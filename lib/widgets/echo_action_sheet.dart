import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import 'scale_tap.dart';

Future<T?> showEchoActionSheet<T>({
  required BuildContext context,
  String? message,
  required List<EchoActionSheetItem<T>> actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: EchoColors.daySurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(EchoRadii.xl)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: EchoColors.sheetHandle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          if (message != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          ...actions.map(
            (item) => _EchoActionSheetTile(
              label: item.label,
              labelColor: item.isDestructive
                  ? EchoColors.destructive
                  : EchoColors.dayTextPrimary,
              onTap: () => Navigator.pop(context, item.value),
            ),
          ),
          Divider(height: 1, color: EchoColors.sheetDivider),
          _EchoActionSheetTile(
            label: '取消',
            labelColor: EchoColors.dayTextSecondary,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class EchoActionSheetItem<T> {
  const EchoActionSheetItem({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final bool isDestructive;
}

class _EchoActionSheetTile extends StatelessWidget {
  const _EchoActionSheetTile({
    required this.label,
    required this.onTap,
    required this.labelColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ),
      ),
    );
  }
}
