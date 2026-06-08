import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../l10n/localized.dart';

enum AppLockType { none, biometrics, pin, both }

enum AppLockInterval {
  always,
  minutes15,
  minutes60,
}

extension AppLockIntervalLabel on AppLockInterval {
  String get label => switch (this) {
        AppLockInterval.always => tr('每次打开', 'Every time'),
        AppLockInterval.minutes15 =>
          tr('离开 15 分钟后', 'After 15 minutes away'),
        AppLockInterval.minutes60 =>
          tr('离开 1 小时后', 'After 1 hour away'),
      };
}

class AppLockAuthResult {
  const AppLockAuthResult({required this.success, this.message});

  final bool success;
  final String? message;
}

/// 系统验证卡片不展示自定义文案（仅保留取消等必要按钮）。
const _hiddenLine = '\u200b';

List<AuthMessages> appLockAuthMessages() => [
      AndroidAuthMessages(
        signInTitle: _hiddenLine,
        biometricHint: _hiddenLine,
        cancelButton: tr('取消', 'Cancel'),
        biometricNotRecognized: tr('请重试', 'Try again'),
        biometricSuccess: _hiddenLine,
        biometricRequiredTitle: _hiddenLine,
        deviceCredentialsRequiredTitle: _hiddenLine,
        deviceCredentialsSetupDescription: _hiddenLine,
        goToSettingsButton: tr('取消', 'Cancel'),
        goToSettingsDescription: _hiddenLine,
      ),
      IOSAuthMessages(
        cancelButton: tr('取消', 'Cancel'),
        goToSettingsButton: tr('取消', 'Cancel'),
        goToSettingsDescription: _hiddenLine,
        lockOut: tr('请稍后再试', 'Try again later'),
        localizedFallbackTitle: tr('取消', 'Cancel'),
      ),
    ];

/// 应用锁：生物识别或 PIN。
class AppLockService extends ChangeNotifier {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const _boxName = 'echo_app_lock';
  static const _enabledKey = 'enabled';
  static const _typeKey = 'type';
  static const _intervalKey = 'interval';
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';

  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage();

  Box<dynamic>? _box;
  bool _enabled = false;
  AppLockType _type = AppLockType.both;
  AppLockInterval _interval = AppLockInterval.always;
  DateTime? _lastUnlockAt;
  bool _isLocked = false;
  bool _backgroundedSinceUnlock = false;
  bool _biometricInFlight = false;
  int _lockEpoch = 0;

  bool get enabled => _enabled;
  int get lockEpoch => _lockEpoch;
  AppLockType get lockType => _type;
  AppLockInterval get interval => _interval;
  bool get isLocked => _enabled && _isLocked;
  bool get biometricInFlight => _biometricInFlight;
  bool get usesBiometricUnlock => _enabled;
  bool get usesPinUnlock => _enabled;

  String get lockModeLabel => switch (_type) {
        AppLockType.pin => tr('密码', 'PIN only'),
        _ => tr('指纹 + 密码', 'Fingerprint + PIN'),
      };

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    _enabled = _box?.get(_enabledKey) as bool? ?? false;
    final stored = _box?.get(_typeKey) as String?;
    _type = AppLockType.values.firstWhere(
      (t) => t.name == stored,
      orElse: () => AppLockType.both,
    );
    if (_enabled && _type != AppLockType.both) {
      _type = AppLockType.both;
      await _box?.put(_typeKey, _type.name);
    }
    _interval = AppLockInterval.values.firstWhere(
      (i) => i.name == (_box?.get(_intervalKey) as String?),
      orElse: () => AppLockInterval.always,
    );
    _isLocked = _enabled;
    if (_enabled) _lockEpoch = 1;
    notifyListeners();
  }

  static bool _isFingerprintType(BiometricType type) =>
      type == BiometricType.fingerprint ||
      type == BiometricType.strong ||
      type == BiometricType.weak;

  Future<bool> canUseBiometrics() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.any(_isFingerprintType);
    } catch (e, st) {
      if (kDebugMode) debugPrint('AppLockService.canUseBiometrics: $e\n$st');
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometricTypes() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.where(_isFingerprintType).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  String biometricLabel(List<BiometricType> types) => tr('指纹', 'Fingerprint');

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _isLocked = value;
    if (value) {
      _lockEpoch++;
    } else {
      _backgroundedSinceUnlock = false;
    }
    await _box?.put(_enabledKey, value);
    notifyListeners();
  }

  Future<void> setLockType(AppLockType type) async {
    _type = type;
    await _box?.put(_typeKey, type.name);
    notifyListeners();
  }

  Future<void> setInterval(AppLockInterval interval) async {
    _interval = interval;
    await _box?.put(_intervalKey, interval.name);
    notifyListeners();
  }

  Future<bool> hasPinConfigured() async {
    final hash = await _secure.read(key: _pinHashKey);
    return hash != null;
  }

  Future<AppLockAuthResult> enableAppLock() async {
    if (!await hasPinConfigured()) {
      return AppLockAuthResult(
        success: false,
        message: tr('请先设置并保存密码', 'Set and save a PIN first'),
      );
    }
    if (await canUseBiometrics()) {
      final trial = await _authenticateBiometrics();
      if (!trial.success) return trial;
      await setLockType(AppLockType.both);
    } else {
      await setLockType(AppLockType.pin);
    }

    await setEnabled(true);
    markUnlocked();
    return const AppLockAuthResult(success: true);
  }

  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hashPin(pin, salt);
    await _secure.write(key: _pinHashKey, value: hash);
    await _secure.write(key: _pinSaltKey, value: salt);
    await setLockType(AppLockType.both);
  }

  Future<bool> verifyPin(String pin) async {
    final hash = await _secure.read(key: _pinHashKey);
    final salt = await _secure.read(key: _pinSaltKey);
    if (hash == null || salt == null) return false;
    return hash == _hashPin(pin, salt);
  }

  /// 修改密码等敏感操作：生物识别验证（不解锁应用）。
  Future<AppLockAuthResult> verifyIdentityWithBiometrics() =>
      _authenticateBiometrics(unlockOnSuccess: false);

  /// 修改密码等敏感操作：校验当前密码（不解锁应用）。
  Future<bool> verifyIdentityWithPin(String pin) async {
    if (pin.length < 4) return false;
    return verifyPin(pin);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  void markBackgrounded() {
    if (!_enabled || _biometricInFlight) return;
    _backgroundedSinceUnlock = true;
  }

  void markUnlocked() {
    _lastUnlockAt = DateTime.now();
    _isLocked = false;
    _backgroundedSinceUnlock = false;
    notifyListeners();
  }

  void lockNow() {
    if (!_enabled) return;
    _isLocked = true;
    _lockEpoch++;
    notifyListeners();
  }

  bool shouldLockOnResume() {
    if (!_enabled || !_backgroundedSinceUnlock) return false;

    if (_interval == AppLockInterval.always) return true;

    final last = _lastUnlockAt;
    if (last == null) return true;
    final elapsed = DateTime.now().difference(last);
    return switch (_interval) {
      AppLockInterval.minutes15 => elapsed >= const Duration(minutes: 15),
      AppLockInterval.minutes60 => elapsed >= const Duration(hours: 1),
      AppLockInterval.always => true,
    };
  }

  Future<AppLockAuthResult> unlockWithBiometrics() async {
    if (!_enabled) {
      markUnlocked();
      return const AppLockAuthResult(success: true);
    }

    if (_type != AppLockType.both) {
      return AppLockAuthResult(
        success: false,
        message: tr('请用密码解锁', 'Unlock with your PIN'),
      );
    }

    return _authenticateBiometrics(unlockOnSuccess: true);
  }

  Future<AppLockAuthResult> _authenticateBiometrics({
    bool unlockOnSuccess = false,
  }) async {
    if (_biometricInFlight) {
      return const AppLockAuthResult(success: false);
    }

    _biometricInFlight = true;
    try {
      if (!await _auth.isDeviceSupported()) {
        return AppLockAuthResult(
          success: false,
          message: tr('不支持', 'Not supported'),
        );
      }

      final available = await _auth.getAvailableBiometrics();
      if (!available.any(_isFingerprintType)) {
        return AppLockAuthResult(
          success: false,
          message: tr('请先在系统中录入指纹', 'Enroll a fingerprint in system settings first'),
        );
      }

      final ok = await _auth.authenticate(
        localizedReason: tr('验证以解锁 Echo', 'Verify to unlock Echo'),
        authMessages: appLockAuthMessages(),
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (ok) {
        if (unlockOnSuccess) markUnlocked();
        return const AppLockAuthResult(success: true);
      }
      return AppLockAuthResult(
        success: false,
        message: tr('验证未通过', 'Verification failed'),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('AppLockService.unlockWithBiometrics: $e');
      return AppLockAuthResult(
        success: false,
        message: _messageForPlatformException(e),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('AppLockService.unlockWithBiometrics: $e\n$st');
      return AppLockAuthResult(
        success: false,
        message: tr('验证失败', 'Verification failed'),
      );
    } finally {
      _biometricInFlight = false;
    }
  }

  String _messageForPlatformException(PlatformException e) {
    return switch (e.code) {
      'NotAvailable' => tr('不可用', 'Unavailable'),
      'NotEnrolled' =>
        tr('请先在系统中录入指纹', 'Enroll a fingerprint in system settings first'),
      'LockedOut' => tr('请稍后再试', 'Try again later'),
      'PermanentlyLockedOut' =>
        tr('请用系统密码', 'Use your device passcode'),
      'PasscodeNotSet' =>
        tr('请先设锁屏密码', 'Set a device passcode first'),
      'OtherOperatingSystem' => tr('不支持', 'Not supported'),
      _ => tr('验证失败', 'Verification failed'),
    };
  }

  Future<bool> unlockWithPin(String pin) async {
    if (!_enabled) {
      markUnlocked();
      return true;
    }
    if (_type != AppLockType.both) return false;
    if (pin.length < 4) return false;
    final ok = await verifyPin(pin);
    if (ok) markUnlocked();
    return ok;
  }

  @Deprecated('Use unlockWithBiometrics or unlockWithPin')
  Future<bool> authenticate({String? pin}) async {
    if (_type == AppLockType.pin) {
      return unlockWithPin(pin ?? '');
    }
    return (await unlockWithBiometrics()).success;
  }
}
