import 'dart:async' show unawaited;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n/localized.dart';
import '../services/app_lock_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import 'scale_tap.dart';

/// 应用锁门禁：未解锁时覆盖全屏。
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lock = AppLockService.instance;
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  String? _error;
  bool _busy = false;
  bool _preferPin = false;
  List<BiometricType> _biometricTypes = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lock.addListener(_onLockChanged);
    _pinController.addListener(_onPinChanged);
    _loadBiometricLabel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lock.removeListener(_onLockChanged);
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    setState(() {});
    unawaited(_maybeAutoSubmitPin());
  }

  Future<void> _maybeAutoSubmitPin() async {
    if (!_preferPin || !_lock.isLocked || _busy) return;

    final pin = _pinController.text;
    if (pin.length < 4) return;

    final shouldSubmit =
        pin.length == 6 || await _lock.verifyIdentityWithPin(pin);
    if (shouldSubmit) {
      await _submitPin();
    }
  }

  Future<void> _loadBiometricLabel() async {
    final types = await _lock.availableBiometricTypes();
    if (mounted) setState(() => _biometricTypes = types);
  }

  void _onLockChanged() {
    if (!_lock.isLocked) {
      _preferPin = false;
      _error = null;
      _pinController.clear();
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lock.markBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      if (_lock.biometricInFlight || _busy) return;
      if (_lock.enabled && _lock.shouldLockOnResume()) {
        _preferPin = false;
        _lock.lockNow();
      }
    }
  }

  Future<void> _submitPin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _lock.unlockWithPin(_pinController.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _pinController.clear();
      setState(() => _error = null);
    } else {
      _pinController.clear();
      setState(() => _error = tr('密码错误，请重试', 'Wrong PIN — try again'));
    }
  }

  void _switchToPin() {
    setState(() {
      _preferPin = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  void _switchToBiometric() {
    setState(() {
      _preferPin = false;
      _error = null;
      _pinController.clear();
    });
  }

  IconData get _biometricIcon => Icons.fingerprint_rounded;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        if (!_lock.isLocked) return widget.child;

        return Stack(
      children: [
        IgnorePointer(child: widget.child),
        Positioned.fill(
          child: Material(
            color: EchoColors.appBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _LockBackdrop(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EchoSpacing.pageHorizontal,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        const _LockHeader(),
                        const SizedBox(height: EchoSpacing.xxl),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _preferPin
                              ? _LockPinCard(
                                  key: const ValueKey('pin'),
                                  controller: _pinController,
                                  focusNode: _pinFocus,
                                  error: _error,
                                  busy: _busy,
                                  biometricLabel:
                                      _lock.biometricLabel(_biometricTypes),
                                  biometricIcon: _biometricIcon,
                                  onSubmit: _submitPin,
                                  onBiometric: _switchToBiometric,
                                )
                              : _LockBiometricCard(
                                  key: ValueKey(_lock.lockEpoch),
                                  biometricIcon: _biometricIcon,
                                  biometricLabel:
                                      _lock.biometricLabel(_biometricTypes),
                                  error: _error,
                                  onUsePin: _switchToPin,
                                  onBiometricResult: (success, message) {
                                    if (!mounted) return;
                                    setState(() {
                                      _error = success
                                          ? null
                                          : (message ?? tr('验证未通过', 'Verification failed'));
                                    });
                                  },
                                ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

class _LockBackdrop extends StatelessWidget {
  const _LockBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  EchoColors.dayWriting.withValues(alpha: 0.55),
                  EchoColors.appBackground,
                  EchoColors.appBackground,
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: _SoftOrb(
              size: 260,
              color: const Color(0xFF7A8FA8).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -70,
            child: _SoftOrb(
              size: 200,
              color: EchoColors.dayDivider.withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _LockHeader extends StatelessWidget {
  const _LockHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EchoColors.dayDivider.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.daySurface.withValues(alpha: 0.85),
                border: Border.all(
                  color: EchoColors.dayDivider.withValues(alpha: 0.55),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EchoColors.dayTextPrimary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 24,
                color: EchoColors.dayTextSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: EchoSpacing.lg),
        Text(
          'Echo',
          style: EchoTypography.displayMedium.copyWith(
            color: EchoColors.dayTextPrimary,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: EchoSpacing.xs),
        Text(
          tr('你的回响，只属于你', 'Your echoes belong to you'),
          style: EchoTypography.labelMedium.copyWith(
            color: EchoColors.dayTextWhisper,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _FrostedPanel extends StatelessWidget {
  const _FrostedPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EchoRadii.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EchoColors.daySurface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(EchoRadii.xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(alpha: 0.06),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LockBiometricCard extends StatefulWidget {
  const _LockBiometricCard({
    super.key,
    required this.biometricIcon,
    required this.biometricLabel,
    required this.error,
    required this.onUsePin,
    required this.onBiometricResult,
  });

  final IconData biometricIcon;
  final String biometricLabel;
  final String? error;
  final VoidCallback onUsePin;
  final void Function(bool success, String? message) onBiometricResult;

  @override
  State<_LockBiometricCard> createState() => _LockBiometricCardState();
}

class _LockBiometricCardState extends State<_LockBiometricCard>
    with SingleTickerProviderStateMixin {
  final _lock = AppLockService.instance;
  late final AnimationController _pulse;
  bool _prompting = true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _prompt() async {
    if (!mounted || !_lock.isLocked) return;
    if (_lock.biometricInFlight) return;

    setState(() => _prompting = true);
    final result = await _lock.unlockWithBiometrics();
    if (!mounted) return;

    setState(() => _prompting = false);
    widget.onBiometricResult(result.success, result.message);
  }

  @override
  Widget build(BuildContext context) {
    return _FrostedPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EchoSpacing.lg + 2,
          EchoSpacing.xl,
          EchoSpacing.lg + 2,
          EchoSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('验证身份', 'Verify identity'),
              style: EchoTypography.titleMedium.copyWith(
                color: EchoColors.dayTextPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: EchoSpacing.xxs),
            Text(
              tr('轻触图标，用${widget.biometricLabel}解锁', 'Tap the icon to unlock with ${widget.biometricLabel}'),
              style: EchoTypography.caption.copyWith(
                color: EchoColors.dayTextWhisper,
              ),
            ),
            const SizedBox(height: EchoSpacing.xl),
            ScaleTap(
              onTap: _prompting ? null : _prompt,
              scale: 0.96,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final scale = 1 + _pulse.value * 0.04;
                  final glow = 0.06 + _pulse.value * 0.08;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7A8FA8).withValues(alpha: 0.16),
                            EchoColors.dayWriting.withValues(alpha: 0.5),
                          ],
                        ),
                        border: Border.all(
                          color: EchoColors.dayDivider.withValues(alpha: 0.55),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7A8FA8).withValues(alpha: glow),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  widget.biometricIcon,
                  size: 42,
                  color: EchoColors.dayTextSecondary.withValues(alpha: 0.92),
                ),
              ),
            ),
            const SizedBox(height: EchoSpacing.md),
            Text(
              _prompting
                  ? tr('正在唤起${widget.biometricLabel}…', 'Opening ${widget.biometricLabel}…')
                  : tr('也可改用密码', 'Or use PIN instead'),
              style: EchoTypography.caption.copyWith(
                color: EchoColors.dayTextSecondary,
              ),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: EchoSpacing.sm),
              Text(
                widget.error!,
                textAlign: TextAlign.center,
                style: EchoTypography.caption.copyWith(
                  color: EchoColors.destructive.withValues(alpha: 0.9),
                ),
              ),
            ],
            const SizedBox(height: EchoSpacing.lg),
            _LockTextAction(
              label: tr('使用密码', 'Use PIN'),
              icon: Icons.password_rounded,
              onTap: widget.onUsePin,
            ),
          ],
        ),
      ),
    );
  }
}

class _LockPinCard extends StatelessWidget {
  const _LockPinCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.busy,
    required this.biometricLabel,
    required this.biometricIcon,
    required this.onSubmit,
    required this.onBiometric,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final bool busy;
  final String biometricLabel;
  final IconData biometricIcon;
  final VoidCallback onSubmit;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    return _FrostedPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EchoSpacing.lg + 2,
          EchoSpacing.xl,
          EchoSpacing.lg + 2,
          EchoSpacing.lg,
        ),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final length = controller.text.length;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('输入密码', 'Enter PIN'),
                  style: EchoTypography.titleMedium.copyWith(
                    color: EchoColors.dayTextPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: EchoSpacing.xxs),
                Text(
                  tr('输入应用密码以继续', 'Enter your app PIN to continue'),
                  style: EchoTypography.caption.copyWith(
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
                const SizedBox(height: EchoSpacing.xl),
                GestureDetector(
                  onTap: () => focusNode.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _PinDots(length: length, maxLength: 6),
                        Positioned.fill(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            enabled: !busy,
                            autofocus: true,
                            obscureText: true,
                            showCursor: false,
                            enableInteractiveSelection: false,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              color: Colors.transparent,
                              fontSize: 1,
                              height: 1,
                            ),
                            cursorColor: Colors.transparent,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                              isCollapsed: true,
                            ),
                            onSubmitted: (_) => onSubmit(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: EchoSpacing.lg),
                if (error != null) ...[
                  Text(
                    error!,
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.destructive.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.sm),
                ],
                ScaleTap(
                  onTap: busy || length < 4 ? () {} : onSubmit,
                  scale: 0.98,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: length >= 4
                          ? EchoColors.dayTextPrimary
                          : EchoColors.dayTextPrimary.withValues(alpha: 0.25),
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
                            tr('解锁', 'Unlock'),
                            style: EchoTypography.labelLarge.copyWith(
                              color: EchoColors.dayBackground,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: EchoSpacing.lg),
                _LockTextAction(
                  label: tr('用$biometricLabel', 'Use $biometricLabel'),
                  icon: biometricIcon,
                  onTap: busy ? () {} : onBiometric,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, required this.maxLength});

  final int length;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final filled = index < length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: filled ? 14 : 12,
            height: filled ? 14 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? EchoColors.dayTextPrimary
                  : Colors.transparent,
              border: Border.all(
                color: filled
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextWhisper.withValues(alpha: 0.55),
                width: filled ? 0 : 1.5,
              ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: EchoColors.dayTextPrimary.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _LockTextAction extends StatelessWidget {
  const _LockTextAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: EchoColors.dayTextWhisper),
            const SizedBox(width: 6),
            Text(
              label,
              style: EchoTypography.caption.copyWith(
                color: EchoColors.dayTextSecondary,
                decoration: TextDecoration.underline,
                decorationColor:
                    EchoColors.dayTextWhisper.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
