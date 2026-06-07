import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_typography.dart';
import 'echo_charm.dart';
import 'scale_tap.dart';

/// 带 Echo 小插画的空状态。
class EchoEmptyState extends StatelessWidget {
  const EchoEmptyState({
    super.key,
    required this.charm,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.tone = EchoCharmTone.day,
    this.compact = false,
  });

  final EchoCharmKind charm;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EchoCharmTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = tone == EchoCharmTone.night
        ? EchoColors.nightTextSecondary
        : EchoColors.dayTextSecondary;
    final whisper = tone == EchoCharmTone.night
        ? EchoColors.nightTextWhisper
        : EchoColors.dayTextWhisper;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 40,
        vertical: compact ? 8 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EchoCharm(
            kind: charm,
            size: compact ? 64 : 88,
            tone: tone,
            animate: !compact,
          ),
          SizedBox(height: compact ? 12 : 20),
          if (title != null) ...[
            Text(
              title!,
              style: EchoTypography.labelLarge.copyWith(color: primary),
            ),
            SizedBox(height: compact ? 6 : 8),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: EchoTypography.labelMedium.copyWith(
              color: title == null ? primary : whisper,
              height: 1.65,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? 14 : 20),
            ScaleTap(
              onTap: onAction,
              scale: 0.96,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
