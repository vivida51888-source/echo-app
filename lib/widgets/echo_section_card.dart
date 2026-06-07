import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';

/// 带标题与淡色底的区块卡片（统计页等）。
class EchoSectionCard extends StatelessWidget {
  const EchoSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.tint,
  });

  final String title;
  final String? subtitle;
  final Color? tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: EchoTypography.titleMedium.copyWith(
            color: EchoColors.dayTextPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: EchoSpacing.xxs),
          Text(
            subtitle!,
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextWhisper,
            ),
          ),
        ],
        const SizedBox(height: EchoSpacing.sm + 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EchoColors.sectionCardFill(tint),
            borderRadius: BorderRadius.circular(EchoRadii.lg),
            border: Border.all(
              color: EchoColors.dayDivider.withValues(alpha: 0.65),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              EchoSpacing.sm + 2,
              EchoSpacing.md,
              EchoSpacing.sm + 2,
              EchoSpacing.md,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
