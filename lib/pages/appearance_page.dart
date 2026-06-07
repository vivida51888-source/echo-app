import 'package:flutter/material.dart';

import '../models/echo_appearance_preset.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_appearance_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../widgets/echo_settings_layout.dart';
import '../widgets/scale_tap.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const _tint = Color(0xFFC4A878);

  @override
  Widget build(BuildContext context) {
    return EchoSettingsScaffold(
      title: '外观',
      children: [
        ListenableBuilder(
          listenable: EchoAppearanceService.instance,
          builder: (context, _) {
            final current = EchoAppearanceService.instance.preset;
            return Column(
              children: [
                for (final preset in EchoAppearancePresets.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: EchoSpacing.sm),
                    child: _AppearancePresetCard(
                      preset: preset,
                      selected: preset.id == current.id,
                      onTap: () =>
                          EchoAppearanceService.instance.setPreset(preset),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AppearancePresetCard extends StatelessWidget {
  const _AppearancePresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final EchoAppearancePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(EchoSpacing.md),
        decoration: BoxDecoration(
          color: EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.lg),
          border: Border.all(
            color: selected
                ? AppearancePage._tint.withValues(alpha: 0.45)
                : EchoColors.dayDivider.withValues(alpha: 0.65),
            width: selected ? 1.2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppearancePage._tint.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: EchoColors.dayTextPrimary.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            _PalettePreview(
              day: preset.previewDay,
              night: preset.previewNight,
              dualTone: preset.dualTone,
            ),
            const SizedBox(width: EchoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: EchoTypography.bodyLarge.copyWith(
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.xxs),
                  Text(
                    preset.subtitle,
                    style: EchoTypography.labelMedium.copyWith(
                      color: EchoColors.dayTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: AppearancePage._tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({
    required this.day,
    required this.night,
    required this.dualTone,
  });

  final Color day;
  final Color night;
  final bool dualTone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EchoRadii.sm),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: dualTone
          ? Row(
              children: [
                Expanded(child: ColoredBox(color: night)),
                Container(width: 0.5, color: EchoColors.dayDivider),
                Expanded(child: ColoredBox(color: day)),
              ],
            )
          : ColoredBox(color: day),
    );
  }
}

void openAppearancePage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const AppearancePage()),
  );
}
