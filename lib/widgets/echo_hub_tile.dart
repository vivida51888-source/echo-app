import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import 'scale_tap.dart';

/// 模块入口卡片：回响 / 设置等 hub 列表项。
class EchoHubTile extends StatelessWidget {
  const EchoHubTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconTint,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = iconTint ?? EchoColors.dayTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.pageHorizontal,
        0,
        EchoSpacing.pageHorizontal,
        EchoSpacing.sm,
      ),
      child: ScaleTap(
        onTap: onTap,
        scale: 0.98,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EchoColors.daySurface,
            borderRadius: BorderRadius.circular(EchoRadii.md),
            border: Border.all(color: EchoColors.dayDivider, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              EchoSpacing.md,
              EchoSpacing.md,
              EchoSpacing.sm + 2,
              EchoSpacing.md,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(EchoRadii.sm),
                    ),
                    child: Icon(icon, size: 18, color: tint),
                  ),
                  const SizedBox(width: EchoSpacing.sm + 2),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: EchoTypography.bodyLarge.copyWith(
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: EchoSpacing.xxs),
                        Text(
                          subtitle!,
                          style: EchoTypography.labelMedium.copyWith(
                            color: EchoColors.dayTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: EchoColors.dayTextWhisper,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
