import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_theme_extension.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import 'scale_tap.dart';

/// 统一页头：大标题 + 副标题 + 可选右侧操作。
class EchoPageHeader extends StatelessWidget {
  const EchoPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tone = EchoPageTone.day,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EchoPageTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = context.echoTheme;
    final useHomePalette = tone == EchoPageTone.night && EchoColors.usesDualTone;
    final primary =
        useHomePalette ? EchoColors.nightTextPrimary : theme.textPrimary;
    final secondary =
        useHomePalette ? EchoColors.nightTextSecondary : theme.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.pageHorizontal,
        EchoSpacing.headerTop,
        EchoSpacing.md,
        EchoSpacing.headerBottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EchoTypography.displayMedium.copyWith(color: primary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: EchoSpacing.xxs + 2),
                  Text(
                    subtitle!,
                    style: EchoTypography.labelMedium.copyWith(color: secondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

enum EchoPageTone { day, night }

/// 页头圆形操作按钮。
class EchoHeaderAction extends StatelessWidget {
  const EchoHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.full),
          border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        ),
        child: Icon(icon, size: 20, color: EchoColors.onSurface),
      ),
    );
  }
}

/// 列表分组标题。
class EchoSectionLabel extends StatelessWidget {
  const EchoSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.pageHorizontal,
        EchoSpacing.lg,
        EchoSpacing.pageHorizontal,
        EchoSpacing.sm,
      ),
      child: Text(
        label,
        style: EchoTypography.caption.copyWith(
          color: EchoColors.onSurfaceWhisper,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
