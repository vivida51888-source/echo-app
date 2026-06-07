import 'package:flutter/material.dart';

import '../models/diary_stationery.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_stationery_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../widgets/echo_settings_layout.dart';
import '../widgets/scale_tap.dart';

class DiaryStationeryPage extends StatelessWidget {
  const DiaryStationeryPage({super.key});

  static const _tint = Color(0xFFC9A882);

  @override
  Widget build(BuildContext context) {
    return EchoSettingsScaffold(
      title: '日记信纸',
      children: [
        Text(
          '写作页背景，长文时信纸下方会延伸纸本色',
          style: EchoTypography.caption.copyWith(
            color: EchoColors.dayTextWhisper,
            height: 1.5,
          ),
        ),
        const SizedBox(height: EchoSpacing.md),
        ListenableBuilder(
          listenable: DiaryStationeryService.instance,
          builder: (context, _) {
            final current = DiaryStationeryService.instance.current;
            return Column(
              children: [
                for (final stationery in DiaryStationeries.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: EchoSpacing.sm),
                    child: _StationeryCard(
                      stationery: stationery,
                      selected: stationery.id == current.id,
                      onTap: () => DiaryStationeryService.instance
                          .setStationery(stationery),
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

class _StationeryCard extends StatelessWidget {
  const _StationeryCard({
    required this.stationery,
    required this.selected,
    required this.onTap,
  });

  final DiaryStationery stationery;
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
                ? DiaryStationeryPage._tint.withValues(alpha: 0.45)
                : EchoColors.dayDivider.withValues(alpha: 0.65),
            width: selected ? 1.2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: DiaryStationeryPage._tint.withValues(alpha: 0.12),
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
            StationeryPreview(stationery: stationery),
            const SizedBox(width: EchoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stationery.name,
                    style: EchoTypography.bodyLarge.copyWith(
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.xxs),
                  Text(
                    stationery.subtitle,
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
                color: DiaryStationeryPage._tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationeryPreview extends StatelessWidget {
  const StationeryPreview({
    super.key,
    required this.stationery,
    this.width = 56,
    this.height = 56,
  });

  final DiaryStationery stationery;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EchoRadii.sm),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        color: stationery.extensionColor,
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: stationery.hasImage
          ? Image.asset(
              stationery.assetPath!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            )
          : ColoredBox(color: EchoColors.appBackground),
    );
  }
}

void openDiaryStationeryPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const DiaryStationeryPage()),
  );
}

Future<void> showDiaryStationeryPicker(BuildContext context) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: EchoColors.daySurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(EchoRadii.xl)),
    ),
    builder: (context) => const _DiaryStationeryPickerSheet(),
  );
}

class _DiaryStationeryPickerSheet extends StatelessWidget {
  const _DiaryStationeryPickerSheet();

  static const _tint = Color(0xFFC9A882);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EchoColors.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '换信纸',
                style: EchoTypography.titleMedium.copyWith(
                  color: EchoColors.dayTextPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '左右滑动，点选即可切换',
                style: EchoTypography.caption.copyWith(
                  color: EchoColors.dayTextWhisper,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 128,
              child: ListenableBuilder(
                listenable: DiaryStationeryService.instance,
                builder: (context, _) {
                  final current = DiaryStationeryService.instance.current;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: DiaryStationeries.all.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final stationery = DiaryStationeries.all[index];
                      return _PickerStationeryTile(
                        stationery: stationery,
                        selected: stationery.id == current.id,
                        onTap: () {
                          DiaryStationeryService.instance
                              .setStationery(stationery);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerStationeryTile extends StatelessWidget {
  const _PickerStationeryTile({
    required this.stationery,
    required this.selected,
    required this.onTap,
  });

  final DiaryStationery stationery;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EchoRadii.sm),
                border: Border.all(
                  color: selected
                      ? _DiaryStationeryPickerSheet._tint
                          .withValues(alpha: 0.7)
                      : EchoColors.dayDivider.withValues(alpha: 0.7),
                  width: selected ? 1.6 : 0.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _DiaryStationeryPickerSheet._tint
                              .withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: StationeryPreview(
                stationery: stationery,
                width: 56,
                height: 76,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stationery.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: EchoTypography.micro.copyWith(
                color: selected
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
