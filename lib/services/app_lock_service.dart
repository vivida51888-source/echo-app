import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

enum AppLockType { none, biometrics, pin, both }

enum AppLockInterval {
  always,
  minutes15,
  minutes60,
}

extension AppLockIntervalLabel on AppLockInterval {
  String get label => switch (this) {
        AppLockInterval.always => '每次打开',
        AppLockInterval.minutes15 => '离开 15 分钟后',
        AppLockInterval.minutes60 => '离开 1 小时后',
      };
}

class AppLockAuthResult {
  const AppLockAuthResult({required this.success, this.message});

  final bool success;
  final String? message;
}

/// 系统验证卡片不展示自定义文案（仅保留取消等必要按钮）。
const _hiddenLine = '\u200b';

const List<AuthMessages> kAppLockAuthMessages = [
  AndroidAuthMessages(
    signInTitle: _hiddenLine,
    biometricHint: _hiddenLine,
    cancelButton: '取消',
    biometricNotRecognized: '请重试',
    biometricSuccess: _hiddenLine,
    biometricRequiredTitle: _hiddenLine,
    deviceCredentialsRequiredTitle: _hiddenLine,
    deviceCredentialsSetupDescription: _hiddenLine,
    goToSettingsButton: '取消',
    goToSettingsDescription: _hiddenLine,
  ),
  IOSAuthMessages(
    cancelButton: '取消',
    goToSettingsButton: '取消',
    goToSettingsDescription: _hiddenLine,
    lockOut: '请稍后再试',
    localizedFallbackTitle: '取消',
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

  String get lockModeLabel => '生物识别 + 密码';

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

  Future<bool> canUseBiometrics() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e, st) {
      if (kDebugMode) debugPrint('AppLockService.canUseBiometrics: $e\n$st');
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometricTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  String biometricLabel(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return '面容';
    if (types.contains(BiometricType.fingerprint)) return '指纹';
    if (types.contains(BiometricType.strong)) return '指纹';
    if (types.contains(BiometricType.weak)) return '指纹';
    return '生物识别';
  }

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
      return const AppLockAuthResult(
        success: false,
        message: '请先设置并保存密码',
      );
    }
    if (!await canUseBiometrics()) {
      return const AppLockAuthResult(
        success: false,
        message: '请先录入指纹或面容',
      );
    }

    final trial = await _authenticateBiometrics();
    if (!trial.success) return trial;

    await setLockType(AppLockType.both);
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
      return const AppLockAuthResult(success: false, message: '请用密码解锁');
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
        return const AppLockAuthResult(success: false, message: '不支持');
      }

      final available = await _auth.getAvailableBiometrics();
      if (available.isEmpty) {
        return const AppLockAuthResult(
          success: false,
          message: '请先录入指纹或面容',
        );
      }

      final ok = await _auth.authenticate(
        localizedReason: '验证以解锁 Echo',
        authMessages: kAppLockAuthMessages,
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
      return const AppLockAuthResult(
        success: false,
        message: '验证未通过',
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('AppLockService.unlockWithBiometrics: $e');
      return AppLockAuthResult(
        success: false,
        message: _messageForPlatformException(e),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('AppLockService.unlockWithBiometrics: $e\n$st');
      return const AppLockAuthResult(success: false, message: '验证失败');
    } finally {
      _biometricInFlight = false;
    }
  }

  String _messageForPlatformException(PlatformException e) {
    return switch (e.code) {
      'NotAvailable' => '不可用',
      'NotEnrolled' => '请先录入指纹或面容',
      'LockedOut' => '请稍后再试',
      'PermanentlyLockedOut' => '请用系统密码',
      'PasscodeNotSet' => '请先设锁屏密码',
      'OtherOperatingSystem' => '不支持',
      _ => '验证失败',
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
