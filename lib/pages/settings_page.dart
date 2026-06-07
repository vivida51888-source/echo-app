import 'package:flutter/material.dart';



import '../navigation/app_page_route.dart';

import '../services/diary_stationery_service.dart';
import '../services/echo_appearance_service.dart';

import '../l10n/echo_strings.dart';
import '../services/locale_service.dart';
import '../services/theme_mode_service.dart';

import '../utils/future_letter_copy.dart';

import '../theme/echo_colors.dart';

import '../theme/echo_spacing.dart';

import '../widgets/echo_page_header.dart';

import '../widgets/echo_settings_layout.dart';

import 'appearance_page.dart';
import 'diary_stationery_page.dart';

import 'about_echo_page.dart';

import 'app_lock_settings_page.dart';

import 'data_privacy_page.dart';

import 'export_data_page.dart';

import 'future_letters_page.dart';

import 'important_days_page.dart';
import 'keepsakes_page.dart';

import 'recycle_bin_page.dart';

import 'language_page.dart';
import 'theme_mode_page.dart';



class SettingsPage extends StatelessWidget {

  const SettingsPage({super.key});



  static const _lockTint = Color(0xFF7A8FA8);

  static const _trashTint = Color(0xFF9A9088);

  static const _exportTint = Color(0xFF8B7355);

  static const _letterTint = Color(0xFF8A7AA8);

  static const _dayTint = Color(0xFF9AB898);

  static const _shopTint = Color(0xFF9A8AA8);

  static const _vaultTint = Color(0xFF7FAF82);

  static const _aboutTint = Color(0xFF8B7355);



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

              child: ListView(

                padding: const EdgeInsets.fromLTRB(

                  EchoSpacing.pageHorizontal,

                  EchoSpacing.sm,

                  EchoSpacing.pageHorizontal,

                  EchoSpacing.xxl,

                ),

                children: [

                  EchoSettingsGroup(

                    label: '隐私与数据',

                    children: [

                      EchoSettingsListTile(

                        title: '应用锁与隐私',

                        subtitle: 'Face ID、密码、多任务模糊',

                        icon: Icons.lock_outline_rounded,

                        iconTint: _lockTint,

                        onTap: () => openAppLockSettingsPage(context),

                      ),

                      EchoSettingsListTile(

                        title: '回收站',

                        subtitle: '删除后保留 15 天',

                        icon: Icons.delete_outline_rounded,

                        iconTint: _trashTint,

                        onTap: () => openRecycleBinPage(context),

                      ),

                      EchoSettingsListTile(

                        title: '备份与导出',

                        subtitle: 'Word、全量 zip',

                        icon: Icons.upload_outlined,

                        iconTint: _exportTint,

                        onTap: () => openExportDataPage(context),

                      ),

                    ],

                  ),

                  EchoSettingsGroup(

                    label: '记录',

                    children: [

                      EchoSettingsListTile(

                        title: FutureLetterCopy.settingsTitle,

                        subtitle: FutureLetterCopy.settingsSubtitle,

                        icon: Icons.mail_outline_rounded,

                        iconTint: _letterTint,

                        onTap: () {

                          Navigator.of(context).push(

                            AppPageRoute<void>(

                              builder: (_) => const FutureLettersPage(),

                            ),

                          );

                        },

                      ),

                      EchoSettingsListTile(

                        title: '印记 · 重要日',

                        subtitle: '生日、纪念日提醒',

                        icon: Icons.event_outlined,

                        iconTint: _dayTint,

                        onTap: () {

                          Navigator.of(context).push(

                            AppPageRoute<void>(

                              builder: (_) => const ImportantDaysPage(),

                            ),

                          );

                        },

                      ),

                    ],

                  ),

                  EchoSettingsGroup(

                    label: '回响拾遗',

                    children: [

                      EchoSettingsListTile(

                        title: '情绪小铺',

                        subtitle: '看看能收集哪些纪念物',

                        icon: Icons.storefront_outlined,

                        iconTint: _shopTint,

                        onTap: () => openKeepsakesPage(context),

                      ),

                      EchoSettingsListTile(

                        title: '个人仓库',

                        subtitle: '专注之花、时间种子、共鸣贝壳',

                        icon: Icons.inventory_2_outlined,

                        iconTint: _vaultTint,

                        onTap: () => openPersonalVaultPage(context),

                      ),

                    ],

                  ),

                  EchoSettingsGroup(

                    label: '关于',

                    children: [

                      EchoSettingsListTile(

                        title: '关于 Echo',

                        subtitle: '版本与功能说明',

                        icon: Icons.info_outline_rounded,

                        iconTint: _aboutTint,

                        onTap: () => openAboutEchoPage(context),

                      ),

                    ],

                  ),

                  ListenableBuilder(

                    listenable: Listenable.merge([

                      EchoAppearanceService.instance,

                      DiaryStationeryService.instance,

                      ThemeModeService.instance,

                      LocaleService.instance,

                    ]),

                    builder: (context, _) {

                      final appearanceName =

                          EchoAppearanceService.instance.presetName;

                      final stationeryName =

                          DiaryStationeryService.instance.currentName;

                      final nightLabel = ThemeModeService.instance.mode.label;

                      final strings = EchoStrings.of();

                      final localeLabel = LocaleService.instance.mode.label(
                        englishUi: strings.isEn,
                      );



                      return EchoSettingsGroup(

                        label: strings.isEn ? 'Display' : '显示',

                        children: [

                          EchoSettingsListTile(

                            title: strings.languageTitle,

                            subtitle: localeLabel,

                            icon: Icons.translate_rounded,

                            iconTint: const Color(0xFF7A8FA8),

                            onTap: () => openLanguagePage(context),

                          ),

                          EchoSettingsListTile(

                            title: '数据与隐私',

                            subtitle: '本地存储与权限',

                            icon: Icons.shield_outlined,

                            iconTint: EchoColors.dayTextSecondary,

                            onTap: () => openDataPrivacyPage(context),

                          ),

                          EchoSettingsListTile(

                            title: '外观',

                            subtitle: '纸色 · $appearanceName',

                            icon: Icons.palette_outlined,

                            iconTint: const Color(0xFFC4A878),

                            onTap: () => openAppearancePage(context),

                          ),

                          EchoSettingsListTile(

                            title: '日记信纸',

                            subtitle: stationeryName,

                            icon: Icons.description_outlined,

                            iconTint: const Color(0xFFC9A882),

                            onTap: () => openDiaryStationeryPage(context),

                          ),

                          EchoSettingsListTile(

                            title: '夜间模式',

                            subtitle: nightLabel,

                            icon: Icons.dark_mode_outlined,

                            iconTint: const Color(0xFF6A6A7A),

                            onTap: () => openThemeModePage(context),

                          ),

                        ],

                      );

                    },

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}


