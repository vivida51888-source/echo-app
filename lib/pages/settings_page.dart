import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../services/diary_stationery_service.dart';
import '../services/echo_appearance_service.dart';
import '../services/locale_service.dart';
import '../services/theme_mode_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_spacing.dart';
import '../widgets/echo_page_header.dart';
import '../widgets/echo_settings_layout.dart';
import 'about_echo_page.dart';
import 'appearance_page.dart';
import 'app_lock_settings_page.dart';
import 'data_privacy_page.dart';
import 'echo_plus_page.dart';
import '../services/echo_plus_service.dart';
import 'diary_stationery_page.dart';
import 'export_data_page.dart';
import 'language_page.dart';
import 'recycle_bin_page.dart';
import 'terms_page.dart';
import '../utils/legal_links.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _lockTint = Color(0xFF7A8FA8);
  static const _trashTint = Color(0xFF9A9088);
  static const _exportTint = Color(0xFF8B7355);
  static const _aboutTint = Color(0xFF8B7355);
  static const _privacyTint = Color(0xFF6A8F7A);
  static const _nightTint = Color(0xFF6A6A7A);
  static const _languageTint = Color(0xFF7A8FA8);
  static const _appearanceTint = Color(0xFFC4A878);
  static const _stationeryTint = Color(0xFFC9A882);
  static const _plusTint = Color(0xFFC99A3A);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EchoColors.appBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenableBuilder(
              listenable: LocaleService.instance,
              builder: (context, _) {
                final s = EchoStrings.of();
                return EchoPageHeader(
                  title: s.settingsTitle,
                  subtitle: s.settingsSubtitle,
                );
              },
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  LocaleService.instance,
                  ThemeModeService.instance,
                  EchoAppearanceService.instance,
                  DiaryStationeryService.instance,
                  EchoPlusService.instance,
                ]),
                builder: (context, _) {
                  final s = EchoStrings.of();
                  final isNight = ThemeModeService.instance.isNightMode;
                  final appearanceName =
                      EchoAppearanceService.instance.presetName;
                  final stationeryName =
                      DiaryStationeryService.instance.currentName;
                  final localeLabel = LocaleService.instance.displayLabel();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      EchoSpacing.pageHorizontal,
                      EchoSpacing.sm,
                      EchoSpacing.pageHorizontal,
                      EchoSpacing.xxl,
                    ),
                    children: [
                      EchoSettingsGroup(
                        label: tr('Echo Plus', 'Echo Plus'),
                        children: [
                          EchoSettingsListTile(
                            title: tr('Echo Plus', 'Echo Plus'),
                            subtitle: EchoPlusService.instance.isActive
                                ? (EchoPlusService.instance.hasLifetime
                                    ? tr('永久 · 全部皮肤可用', 'Lifetime · all skins unlocked')
                                    : tr('已开通 · 全部皮肤可用', 'Active · all skins unlocked'))
                                : tr(
                                    '月付 \$1 · 年付 \$9.9 · 买断 \$29.9',
                                    'From \$1/mo · \$9.9/yr · \$29.9 lifetime',
                                  ),
                            icon: Icons.workspace_premium_outlined,
                            iconTint: _plusTint,
                            onTap: () => openEchoPlusPage(context),
                          ),
                        ],
                      ),
                      EchoSettingsGroup(
                        label: s.settingsDisplayGroup,
                        children: [
                          EchoSettingsGroupSwitchTile(
                            title: s.nightModeTitle,
                            subtitle: isNight
                                ? tr('深色界面', 'Dark interface')
                                : tr('默认纸色', 'Default paper tone'),
                            icon: Icons.dark_mode_outlined,
                            iconTint: _nightTint,
                            value: isNight,
                            onChanged: ThemeModeService.instance.setNightMode,
                          ),
                          EchoSettingsListTile(
                            title: s.languageTitle,
                            subtitle: localeLabel,
                            icon: Icons.translate_rounded,
                            iconTint: _languageTint,
                            onTap: () => openLanguagePage(context),
                          ),
                          EchoSettingsListTile(
                            title: s.appearanceTitle,
                            subtitle: s.appearanceSubtitle(appearanceName),
                            icon: Icons.palette_outlined,
                            iconTint: _appearanceTint,
                            onTap: () => openAppearancePage(context),
                          ),
                          EchoSettingsListTile(
                            title: s.diaryStationeryTitle,
                            subtitle: stationeryName,
                            icon: Icons.description_outlined,
                            iconTint: _stationeryTint,
                            onTap: () => openDiaryStationeryPage(context),
                          ),
                        ],
                      ),
                      EchoSettingsGroup(
                        label: s.settingsPrivacyGroup,
                        children: [
                          EchoSettingsListTile(
                            title: s.appLockTitle,
                            subtitle: s.appLockSubtitle,
                            icon: Icons.lock_outline_rounded,
                            iconTint: _lockTint,
                            onTap: () => openAppLockSettingsPage(context),
                          ),
                          EchoSettingsListTile(
                            title: s.recycleBinTitle,
                            subtitle: s.recycleBinSubtitle,
                            icon: Icons.delete_outline_rounded,
                            iconTint: _trashTint,
                            onTap: () => openRecycleBinPage(context),
                          ),
                          EchoSettingsListTile(
                            title: s.exportTitle,
                            subtitle: s.exportSubtitle,
                            icon: Icons.upload_outlined,
                            iconTint: _exportTint,
                            onTap: () => openExportDataPage(context),
                          ),
                        ],
                      ),
                      EchoSettingsGroup(
                        label: s.settingsAboutGroup,
                        children: [
                          EchoSettingsListTile(
                            title: s.aboutEchoTitle,
                            subtitle: s.aboutEchoSubtitle,
                            icon: Icons.info_outline_rounded,
                            iconTint: _aboutTint,
                            onTap: () => openAboutEchoPage(context),
                          ),
                          EchoSettingsListTile(
                            title: s.dataPrivacyTitle,
                            subtitle: s.dataPrivacySubtitle,
                            icon: Icons.shield_outlined,
                            iconTint: _privacyTint,
                            onTap: () => openDataPrivacyPage(context),
                          ),
                          EchoSettingsListTile(
                            title: tr('服务条款', 'Terms of Service'),
                            subtitle: tr('Echo Plus 与使用约定', 'Echo Plus & usage terms'),
                            icon: Icons.article_outlined,
                            iconTint: _privacyTint,
                            onTap: () => openTermsPage(context),
                          ),
                          EchoSettingsListTile(
                            title: tr('在线隐私政策', 'Privacy policy online'),
                            subtitle: tr('Play 商店所需公网链接', 'Public URL for Play Console'),
                            icon: Icons.language_rounded,
                            iconTint: _privacyTint,
                            onTap: () => openPrivacyPolicyUrl(context),
                          ),
                          EchoSettingsListTile(
                            title: tr('联系开发者', 'Contact developer'),
                            subtitle: tr('问题与反馈', 'Questions & feedback'),
                            icon: Icons.mail_outline_rounded,
                            iconTint: _privacyTint,
                            onTap: () => openSupportEmail(context),
                          ),
                        ],
                      ),
                    ],
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
