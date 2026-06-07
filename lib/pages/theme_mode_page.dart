import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../services/theme_mode_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../widgets/echo_settings_layout.dart';

class ThemeModePage extends StatefulWidget {
  const ThemeModePage({super.key});

  @override
  State<ThemeModePage> createState() => _ThemeModePageState();
}

class _ThemeModePageState extends State<ThemeModePage> {
  static const _tint = Color(0xFF6A6A7A);

  final _service = ThemeModeService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = _service.isNightMode;

    return EchoSettingsScaffold(
      title: '夜间模式',
      children: [
        _ThemePreviewCard(isDark: isDark),
        const SizedBox(height: EchoSpacing.lg),
        EchoSettingsSectionCard(
          tint: _tint,
          icon: Icons.brightness_4_outlined,
          title: '显示模式',
          child: EchoSettingsInsetPanel(
            child: EchoSettingsSwitchTile(
              icon: Icons.dark_mode_outlined,
              iconTint: _tint,
              title: '开启夜间模式',
              subtitle: isDark ? '当前已开启' : '当前为默认纸色',
              value: isDark,
              onChanged: _service.setNightMode,
            ),
          ),
        ),
        const SizedBox(height: EchoSpacing.lg),
        const EchoSettingsFootnote('开启后立即生效，与纸色设置互不影响。'),
      ],
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final previewBg =
        isDark ? const Color(0xFF1A1816) : EchoColors.appBackground;
    final previewFg =
        isDark ? const Color(0xFFE8E4DC) : EchoColors.dayTextPrimary;
    final previewMuted =
        isDark ? const Color(0xFF8A8580) : EchoColors.dayTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EchoSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            previewBg,
            previewBg.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.65),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_outlined,
                size: 20,
                color: previewMuted,
              ),
              const SizedBox(width: EchoSpacing.sm),
              Text(
                isDark ? '夜间预览' : '日间预览',
                style: EchoTypography.labelLarge.copyWith(
                  color: previewFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: EchoSpacing.lg),
          Text(
            '回响',
            style: EchoTypography.titleMedium.copyWith(
              color: previewFg,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: EchoSpacing.xs),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: previewFg.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: EchoSpacing.sm),
          Container(
            height: 8,
            width: 140,
            decoration: BoxDecoration(
              color: previewFg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: EchoSpacing.sm),
          Container(
            height: 8,
            width: 96,
            decoration: BoxDecoration(
              color: previewFg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

void openThemeModePage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const ThemeModePage()),
  );
}
