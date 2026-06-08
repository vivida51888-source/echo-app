import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../navigation/app_page_route.dart';
import '../services/locale_service.dart';
import '../services/app_lock_service.dart';
import '../services/privacy_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_settings_layout.dart';
import '../widgets/scale_tap.dart';

class AppLockSettingsPage extends StatefulWidget {
  const AppLockSettingsPage({super.key});

  @override
  State<AppLockSettingsPage> createState() => _AppLockSettingsPageState();
}

class _AppLockSettingsPageState extends State<AppLockSettingsPage> {
  static const _lockTint = Color(0xFF7A8FA8);
  static const _privacyTint = Color(0xFF9A9088);

  final _lock = AppLockService.instance;
  final _privacy = PrivacyService.instance;
  final _oldPinController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  bool _biometricAvailable = false;
  bool _pinConfigured = false;
  bool _pinEditing = false;
  bool _pinChangeVerified = false;
  bool _busy = false;
  List<BiometricType> _biometricTypes = const [];

  @override
  void initState() {
    super.initState();
    _lock.addListener(_rebuild);
    _privacy.addListener(_rebuild);
    _loadState();
    _lock.setLockType(AppLockType.both);
  }

  Future<void> _loadState() async {
    final bio = await _lock.canUseBiometrics();
    final pin = await _lock.hasPinConfigured();
    final types = await _lock.availableBiometricTypes();
    if (mounted) {
      setState(() {
        _biometricAvailable = bio;
        _pinConfigured = pin;
        _pinEditing = !pin;
        _pinChangeVerified = !pin;
        _biometricTypes = types;
      });
    }
  }

  @override
  void dispose() {
    _lock.removeListener(_rebuild);
    _privacy.removeListener(_rebuild);
    _oldPinController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  IconData get _biometricIcon => Icons.fingerprint_rounded;

  String get _biometricLabel => _lock.biometricLabel(_biometricTypes);

  Future<void> _verifyWithBiometric() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _lock.verifyIdentityWithBiometrics();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.success) {
      _oldPinController.clear();
      setState(() => _pinChangeVerified = true);
      _toast(tr('验证通过，请设置新密码', 'Verified — set a new PIN'));
    } else if (result.message != null && result.message!.isNotEmpty) {
      _toast(result.message!);
    }
  }

  Future<void> _verifyWithOldPin() async {
    if (_busy) return;
    final oldPin = _oldPinController.text;
    if (oldPin.length < 4) {
      _toast(tr('请输入当前密码', 'Enter your current PIN'));
      return;
    }

    setState(() => _busy = true);
    final ok = await _lock.verifyIdentityWithPin(oldPin);
    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      _oldPinController.clear();
      setState(() => _pinChangeVerified = true);
      _toast(tr('验证通过，请设置新密码', 'Verified — set a new PIN'));
    } else {
      _toast(tr('当前密码不正确', 'Current PIN is incorrect'));
    }
  }

  Future<void> _setPin() async {
    if (_pinConfigured && !_pinChangeVerified) {
      _toast(tr('请先验证指纹或当前密码', 'Verify with biometrics or current PIN first'));
      return;
    }

    final a = _pinController.text;
    final b = _pinConfirmController.text;
    if (a.length < 4) {
      _toast(tr('密码至少 4 位', 'PIN must be at least 4 digits'));
      return;
    }
    if (a != b) {
      _toast(tr('两次输入不一致', 'PINs do not match'));
      return;
    }

    final wasConfigured = _pinConfigured;
    await _lock.setPin(a);
    _pinController.clear();
    _pinConfirmController.clear();
    if (mounted) {
      setState(() {
        _pinConfigured = true;
        _pinEditing = false;
        _pinChangeVerified = false;
      });
    }
    _toast(wasConfigured
        ? tr('密码已更新', 'PIN updated')
        : tr('密码已保存', 'PIN saved'));
  }

  void _startPinChange() {
    setState(() {
      _pinEditing = true;
      _pinChangeVerified = false;
      _oldPinController.clear();
      _pinController.clear();
      _pinConfirmController.clear();
    });
  }

  void _cancelPinChange() {
    setState(() {
      _pinEditing = false;
      _pinChangeVerified = false;
      _oldPinController.clear();
      _pinController.clear();
      _pinConfirmController.clear();
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    if (_busy) return;

    if (!value) {
      await _lock.setEnabled(false);
      return;
    }

    if (!_pinConfigured) {
      _toast(tr('请先设置并保存密码', 'Set and save a PIN first'));
      return;
    }
    setState(() => _busy = true);
    final result = await _lock.enableAppLock();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.success) {
      _toast(tr('应用锁已开启', 'App lock enabled'));
    } else {
      _toast(result.message ?? tr('无法开启', 'Could not enable'));
    }
  }

  void _toast(String msg) {
    showEchoToast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _lock.enabled;
    final showPinVerify = _pinConfigured && _pinEditing && !_pinChangeVerified;
    final showPinSetup =
        !_pinConfigured || (_pinEditing && _pinChangeVerified);
    final showPinSummary = _pinConfigured && !_pinEditing;

    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final s = EchoStrings.of();
        return EchoSettingsScaffold(
      title: s.appLockTitle,
      children: [
        _LockStatusHero(
          tint: _lockTint,
          enabled: enabled,
          pinConfigured: _pinConfigured,
          biometricAvailable: _biometricAvailable,
          modeLabel: enabled ? _lock.lockModeLabel : null,
        ),
        const SizedBox(height: EchoSpacing.lg),
        if (showPinSummary)
          _PinSummaryCard(
            tint: _lockTint,
            onChange: _startPinChange,
          )
        else if (showPinVerify)
          _PinVerifyCard(
            tint: _lockTint,
            busy: _busy,
            biometricAvailable: _biometricAvailable,
            biometricIcon: _biometricIcon,
            biometricLabel: _biometricLabel,
            oldPinController: _oldPinController,
            onCancel: _cancelPinChange,
            onVerifyOldPin: _verifyWithOldPin,
            onVerifyBiometric: _verifyWithBiometric,
          )
        else if (showPinSetup)
          _PinSetupCard(
            tint: _lockTint,
            pinConfigured: _pinConfigured,
            pinController: _pinController,
            pinConfirmController: _pinConfirmController,
            onCancel: _pinConfigured ? _cancelPinChange : null,
            onSave: _setPin,
          ),
        const SizedBox(height: EchoSpacing.md),
        EchoSettingsSectionCard(
          tint: _lockTint,
          icon: Icons.lock_outline_rounded,
          title: tr('启用应用锁', 'Enable app lock'),
          description: tr(
            '需先保存密码；有指纹时可指纹 + 密码解锁',
            'Save a PIN first; add fingerprint for faster unlock',
          ),
          child: EchoSettingsInsetPanel(
            child: EchoSettingsSwitchTile(
              icon: enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
              iconTint: _lockTint,
              title: enabled ? tr('已开启', 'On') : tr('未开启', 'Off'),
              subtitle: enabled
                  ? tr('离开应用后按间隔重新验证', 'Re-verify after leaving the app')
                  : tr('开启后保护日记与设置', 'Protects your journal and settings'),
              value: enabled,
              onChanged: _busy ? null : _toggleEnabled,
            ),
          ),
        ),
        if (enabled) ...[
          const SizedBox(height: EchoSpacing.lg),
          EchoSettingsSectionCard(
            tint: _lockTint,
            icon: Icons.schedule_rounded,
            title: tr('解锁间隔', 'Unlock interval'),
            description: tr('多久之后需要重新验证身份', 'When to ask for verification again'),
            child: Wrap(
              spacing: EchoSpacing.sm,
              runSpacing: EchoSpacing.sm,
              children: AppLockInterval.values.map((interval) {
                return EchoSettingsChoiceChip(
                  label: interval.label,
                  selected: _lock.interval == interval,
                  tint: _lockTint,
                  onTap: () => _lock.setInterval(interval),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: EchoSpacing.lg),
        EchoSettingsSectionCard(
          tint: _privacyTint,
          icon: Icons.blur_on_outlined,
          title: tr('界面隐私', 'Screen privacy'),
          child: EchoSettingsInsetPanel(
            child: EchoSettingsSwitchTile(
              icon: Icons.visibility_off_outlined,
              iconTint: _privacyTint,
              title: tr('多任务界面模糊', 'Blur in app switcher'),
              subtitle: tr('切换应用时以模糊画面保护内容', 'Blur content when switching apps'),
              value: _privacy.blurInSwitcher,
              onChanged: _privacy.setBlurInSwitcher,
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

class _PinSummaryCard extends StatelessWidget {
  const _PinSummaryCard({
    required this.tint,
    required this.onChange,
  });

  final Color tint;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return EchoSettingsSectionCard(
      tint: tint,
      icon: Icons.pin_outlined,
      title: tr('应用密码', 'App PIN'),
      description: tr('已设置，修改前需验证身份', 'Set — verify identity before changing'),
      child: ScaleTap(
        onTap: onChange,
        scale: 0.98,
        child: EchoSettingsInsetPanel(
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: tint),
              const SizedBox(width: EchoSpacing.sm),
              Expanded(
                child: Text(
                  tr('密码已设置', 'PIN is set'),
                  style: EchoTypography.bodyMedium.copyWith(
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
              ),
              Text(
                tr('修改', 'Change'),
                style: EchoTypography.labelMedium.copyWith(
                  color: tint,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinVerifyCard extends StatelessWidget {
  const _PinVerifyCard({
    required this.tint,
    required this.busy,
    required this.biometricAvailable,
    required this.biometricIcon,
    required this.biometricLabel,
    required this.oldPinController,
    required this.onCancel,
    required this.onVerifyOldPin,
    required this.onVerifyBiometric,
  });

  final Color tint;
  final bool busy;
  final bool biometricAvailable;
  final IconData biometricIcon;
  final String biometricLabel;
  final TextEditingController oldPinController;
  final VoidCallback onCancel;
  final VoidCallback onVerifyOldPin;
  final VoidCallback onVerifyBiometric;

  @override
  Widget build(BuildContext context) {
    return EchoSettingsSectionCard(
      tint: tint,
      icon: Icons.verified_user_outlined,
      title: tr('验证身份', 'Verify identity'),
      description: tr(
        '修改密码前，请验证指纹或输入当前密码',
        'Verify with fingerprint or enter your current PIN',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ScaleTap(
              onTap: busy ? null : onCancel,
              scale: 0.98,
              child: Padding(
                padding: const EdgeInsets.only(bottom: EchoSpacing.sm),
                child: Text(
                  tr('取消', 'Cancel'),
                  style: EchoTypography.caption.copyWith(
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
              ),
            ),
          ),
          if (biometricAvailable) ...[
            ScaleTap(
              onTap: busy ? null : onVerifyBiometric,
              scale: 0.98,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EchoRadii.pill),
                  border: Border.all(
                    color: tint.withValues(alpha: 0.24),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(biometricIcon, size: 20, color: tint),
                    const SizedBox(width: 8),
                    Text(
                      tr('用$biometricLabel验证', 'Verify with $biometricLabel'),
                      style: EchoTypography.labelLarge.copyWith(
                        color: EchoColors.dayTextPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: EchoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: EchoColors.dayDivider.withValues(alpha: 0.55),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    tr('或输入当前密码', 'Or enter current PIN'),
                    style: EchoTypography.micro.copyWith(
                      color: EchoColors.dayTextWhisper,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: EchoColors.dayDivider.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EchoSpacing.md),
          ],
          _PinField(
            controller: oldPinController,
            label: tr('当前密码', 'Current PIN'),
            tint: tint,
            enabled: !busy,
            onSubmitted: onVerifyOldPin,
          ),
          const SizedBox(height: EchoSpacing.md),
          ScaleTap(
            onTap: busy ? null : onVerifyOldPin,
            scale: 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EchoColors.dayTextPrimary,
                borderRadius: BorderRadius.circular(EchoRadii.pill),
              ),
              child: busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EchoColors.dayBackground,
                      ),
                    )
                  : Text(
                      tr('验证并继续', 'Verify & continue'),
                      style: EchoTypography.labelLarge.copyWith(
                        color: EchoColors.dayBackground,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockStatusHero extends StatelessWidget {
  const _LockStatusHero({
    required this.tint,
    required this.enabled,
    required this.pinConfigured,
    required this.biometricAvailable,
    this.modeLabel,
  });

  final Color tint;
  final bool enabled;
  final bool pinConfigured;
  final bool biometricAvailable;
  final String? modeLabel;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        enabled ? tint : EchoColors.dayTextWhisper.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.lg + 2,
        EchoSpacing.xl,
        EchoSpacing.lg + 2,
        EchoSpacing.lg + 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.14),
            EchoColors.daySurface,
            EchoColors.dayWriting.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(EchoRadii.xl),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.08),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.daySurface.withValues(alpha: 0.9),
                  border: Border.all(
                    color: tint.withValues(alpha: 0.22),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.dayTextPrimary.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  enabled ? Icons.verified_user_outlined : Icons.lock_outline,
                  size: 28,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: EchoSpacing.md),
          Text(
            enabled ? tr('回响已上锁', 'Echoes are locked') : tr('回响未上锁', 'Echoes are unlocked'),
            style: EchoTypography.titleMedium.copyWith(
              color: EchoColors.dayTextPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: EchoSpacing.xxs),
          Text(
            enabled
                ? (modeLabel ?? tr('指纹 + 密码', 'Fingerprint + PIN'))
                : tr('设置密码后可开启保护', 'Set a PIN to enable protection'),
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextSecondary,
            ),
          ),
          const SizedBox(height: EchoSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: EchoSpacing.sm,
            runSpacing: EchoSpacing.xs,
            children: [
              _StatusPill(
                icon: Icons.password_rounded,
                label: pinConfigured ? tr('密码已设', 'PIN set') : tr('待设密码', 'PIN needed'),
                active: pinConfigured,
                tint: tint,
              ),
              _StatusPill(
                icon: Icons.fingerprint_rounded,
                label: biometricAvailable
                    ? tr('指纹可用', 'Fingerprint ready')
                    : tr('仅密码解锁', 'PIN only'),
                active: biometricAvailable,
                tint: tint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final color = active ? tint : EchoColors.dayTextWhisper;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? tint.withValues(alpha: 0.1)
            : EchoColors.appBackground.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(EchoRadii.pill),
        border: Border.all(
          color: active
              ? tint.withValues(alpha: 0.2)
              : EchoColors.dayDivider.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: EchoTypography.micro.copyWith(
              color: active
                  ? EchoColors.dayTextSecondary
                  : EchoColors.dayTextWhisper,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinSetupCard extends StatelessWidget {
  const _PinSetupCard({
    required this.tint,
    required this.pinConfigured,
    required this.pinController,
    required this.pinConfirmController,
    required this.onSave,
    this.onCancel,
  });

  final Color tint;
  final bool pinConfigured;
  final TextEditingController pinController;
  final TextEditingController pinConfirmController;
  final VoidCallback onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return EchoSettingsSectionCard(
      tint: tint,
      icon: Icons.pin_outlined,
      title: pinConfigured ? tr('修改密码', 'Change PIN') : tr('设置密码', 'Set PIN'),
      description: tr('4–6 位数字，作为备用解锁方式', '4–6 digits as backup unlock'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onCancel != null)
            Align(
              alignment: Alignment.centerRight,
              child: ScaleTap(
                onTap: onCancel,
                scale: 0.98,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: EchoSpacing.sm),
                  child: Text(
                    tr('取消', 'Cancel'),
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.dayTextWhisper,
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _PinField(
                  controller: pinController,
                  label: tr('新密码', 'New PIN'),
                  tint: tint,
                ),
              ),
              const SizedBox(width: EchoSpacing.sm),
              Expanded(
                child: _PinField(
                  controller: pinConfirmController,
                  label: tr('确认', 'Confirm'),
                  tint: tint,
                ),
              ),
            ],
          ),
          const SizedBox(height: EchoSpacing.md),
          ScaleTap(
            onTap: onSave,
            scale: 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(EchoRadii.pill),
                border: Border.all(
                  color: tint.withValues(alpha: 0.28),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: tint),
                  const SizedBox(width: 8),
                  Text(
                    pinConfigured ? tr('更新密码', 'Update PIN') : tr('保存密码', 'Save PIN'),
                    style: EchoTypography.labelLarge.copyWith(
                      color: EchoColors.dayTextPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.tint,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final Color tint;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: EchoTypography.titleMedium.copyWith(
        color: EchoColors.dayTextPrimary,
        letterSpacing: 6,
      ),
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: EchoColors.dayWriting.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EchoSpacing.sm,
          vertical: EchoSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: BorderSide(
            color: EchoColors.dayDivider.withValues(alpha: 0.45),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: BorderSide(
            color: tint.withValues(alpha: 0.45),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

void openAppLockSettingsPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const AppLockSettingsPage()),
  );
}
