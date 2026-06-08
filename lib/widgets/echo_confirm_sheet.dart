import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_typography.dart';
import 'scale_tap.dart';

/// 底部圆角确认面板（替代方正 AlertDialog）。
Future<bool> showEchoConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  Widget? leading,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EchoColors.daySurface,
            borderRadius: BorderRadius.circular(EchoRadii.xl),
            border: Border.all(
              color: EchoColors.dayDivider.withValues(alpha: 0.55),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EchoColors.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  children: [
                    if (leading != null) ...[
                      leading,
                      const SizedBox(height: 14),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: EchoTypography.titleMedium.copyWith(
                        color: EchoColors.dayTextPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: EchoTypography.bodyMedium.copyWith(
                        color: EchoColors.dayTextSecondary,
                        height: 1.55,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: EchoColors.sheetDivider),
              ScaleTap(
                onTap: () => Navigator.pop(context, true),
                scale: 0.98,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      confirmLabel ?? tr('确认', 'Confirm'),
                      textAlign: TextAlign.center,
                      style: EchoTypography.labelLarge.copyWith(
                        color: EchoColors.dayTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: EchoColors.sheetDivider),
              ScaleTap(
                onTap: () => Navigator.pop(context, false),
                scale: 0.98,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      cancelLabel ?? tr('取消', 'Cancel'),
                      textAlign: TextAlign.center,
                      style: EchoTypography.labelLarge.copyWith(
                        color: EchoColors.dayTextSecondary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
