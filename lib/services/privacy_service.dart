import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:screen_protector/screen_protector.dart';

/// 多任务切换时模糊/遮挡界面，防止偷看。
///
/// - iOS：系统级模糊（[ScreenProtector.protectDataLeakageWithBlur]）
/// - Android：不用 [ScreenProtector.protectDataLeakageOn]（FLAG_SECURE 会在多任务里变成白/黑块）
/// - 全平台：进入 inactive / hidden / paused 时截图并叠加「老花眼」模糊层
class PrivacyService extends ChangeNotifier {
  PrivacyService._();

  static final PrivacyService instance = PrivacyService._();

  static const _boxName = 'echo_privacy';
  static const _blurKey = 'blur_switcher';

  Box<dynamic>? _box;
  bool _blurInSwitcher = true;
  bool _obscured = false;

  bool get blurInSwitcher => _blurInSwitcher;

  /// 是否显示全屏模糊遮罩（应用仍可见时，如切到多任务瞬间）。
  bool get showOverlay => _blurInSwitcher && _obscured;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    _blurInSwitcher = _box?.get(_blurKey) as bool? ?? true;
    await _syncNativeProtection();
    notifyListeners();
  }

  Future<void> setBlurInSwitcher(bool value) async {
    _blurInSwitcher = value;
    await _box?.put(_blurKey, value);
    if (!value) {
      _obscured = false;
    }
    await _syncNativeProtection();
    notifyListeners();
  }

  void onLifecycleChanged(AppLifecycleState state) {
    final shouldObscure = switch (state) {
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused =>
        true,
      AppLifecycleState.resumed => false,
      AppLifecycleState.detached => false,
    };
    _setObscured(shouldObscure);
  }

  void _setObscured(bool value) {
    if (_obscured == value) return;
    _obscured = value;
    notifyListeners();
    unawaited(_syncIosBlur());
  }

  Future<void> _syncNativeProtection() async {
    try {
      if (!_blurInSwitcher) {
        await _disableNativeProtection();
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        // 保持关闭，让系统截取模糊遮罩而非空白占位图。
        await ScreenProtector.protectDataLeakageOff();
        return;
      }
      if (_obscured) {
        await _syncIosBlur();
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('PrivacyService._syncNativeProtection: $e\n$st');
    }
  }

  Future<void> _syncIosBlur() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || !_blurInSwitcher) {
      return;
    }
    try {
      if (_obscured) {
        await ScreenProtector.protectDataLeakageWithBlur();
      } else {
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('PrivacyService._syncIosBlur: $e\n$st');
    }
  }

  Future<void> _disableNativeProtection() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
      await ScreenProtector.protectDataLeakageOff();
    } catch (e, st) {
      if (kDebugMode) debugPrint('PrivacyService._disableNativeProtection: $e\n$st');
    }
  }
}
