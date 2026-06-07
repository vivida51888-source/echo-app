import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../utils/settings_info_copy.dart';
import '../widgets/echo_info_page.dart';

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({super.key});

  static const _tint = Color(0xFF7A8FA8);

  @override
  Widget build(BuildContext context) {
    return EchoInfoPage(
      title: '数据与隐私',
      subtitle: SettingsInfoCopy.privacySubtitle,
      introIcon: Icons.shield_outlined,
      introTint: _tint,
      introTitle: '本地存储',
      sections: const [
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
    );
  }
}

void openDataPrivacyPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const DataPrivacyPage()),
  );
}
