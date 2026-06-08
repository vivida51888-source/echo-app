import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../navigation/app_page_route.dart';
import '../services/locale_service.dart';
import '../utils/legal_links.dart';
import '../utils/settings_info_copy.dart';
import '../widgets/echo_info_page.dart';
import '../widgets/scale_tap.dart';
import '../theme/echo_typography.dart';

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({super.key});

  static const _tint = Color(0xFF7A8FA8);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        return EchoInfoPage(
      title: EchoStrings.of().dataPrivacyTitle,
      subtitle: SettingsInfoCopy.privacySubtitle,
      introIcon: Icons.shield_outlined,
      introTint: _tint,
      introTitle: tr('本地存储', 'Local storage'),
      sections: [
        EchoInfoSection(
          title: SettingsInfoCopy.privacyPrincipleTitle,
          paragraphs: [SettingsInfoCopy.privacyPrinciple],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyStoredTitle,
          bullets: SettingsInfoCopy.privacyStored,
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyNotDoTitle,
          bullets: SettingsInfoCopy.privacyNotDo,
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyPermissionsTitle,
          bullets: SettingsInfoCopy.privacyPermissions,
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyPurchasesTitle,
          paragraphs: [SettingsInfoCopy.privacyPurchases],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyBackupTitle,
          paragraphs: [SettingsInfoCopy.privacyBackup],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyAiTitle,
          paragraphs: [SettingsInfoCopy.privacyAi],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyDeleteTitle,
          paragraphs: [SettingsInfoCopy.privacyDelete],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.privacyUpdateTitle,
          paragraphs: [SettingsInfoCopy.privacyUpdate],
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScaleTap(
            onTap: () => openPrivacyPolicyUrl(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                tr('在浏览器中查看完整隐私政策', 'View full privacy policy online'),
                textAlign: TextAlign.center,
                style: EchoTypography.labelMedium.copyWith(
                  color: _tint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

void openDataPrivacyPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const DataPrivacyPage()),
  );
}
