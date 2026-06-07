import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_theme_extension.dart';
import '../theme/echo_typography.dart';
import 'scale_tap.dart';

/// 底部导航：选中态圆点指示 + 统一字重。
class EchoBottomNav extends StatelessWidget {
  const EchoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isNight,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final s = EchoStrings.of();
        final items = [
          (Icons.nightlight_round_outlined, Icons.nightlight_round, s.momentTitle),
          (Icons.auto_stories_outlined, Icons.auto_stories, s.echoTitle),
          (Icons.anchor_outlined, Icons.anchor, s.todoTitle),
          (Icons.tune_outlined, Icons.tune, s.settingsTitle),
        ];

        final dualHome = isNight && EchoColors.usesDualTone;
        final bg = isNight ? EchoColors.homeBackground : EchoColors.appBackground;
        final border = EchoColors.navBorderFor(isHomeTab: isNight);
        final theme = context.echoTheme;
        final selected =
            dualHome ? EchoColors.nightTextPrimary : theme.textPrimary;
        final unselected =
            dualHome ? EchoColors.nightTextSecondary : theme.textSecondary;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            border: Border(top: BorderSide(color: border, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItem(
                        outlined: items[i].$1,
                        filled: items[i].$2,
                        label: items[i].$3,
                        selected: currentIndex == i,
                        selectedColor: selected,
                        unselectedColor: unselected,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.outlined,
    required this.filled,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData outlined;
  final IconData filled;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;

    return ScaleTap(
      onTap: onTap,
      scale: 0.94,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 5 : 0,
              height: selected ? 5 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!selected) const SizedBox(height: 9),
            Icon(selected ? filled : outlined, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: EchoTypography.micro.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
