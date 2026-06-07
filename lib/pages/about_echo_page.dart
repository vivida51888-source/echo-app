import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../utils/app_info.dart';
import '../utils/settings_info_copy.dart';
import '../widgets/echo_info_page.dart';

class AboutEchoPage extends StatelessWidget {
  const AboutEchoPage({super.key});

  static const _tint = Color(0xFF8B7355);

  @override
  Widget build(BuildContext context) {
    return EchoInfoPage(
      title: '关于 ${AppInfo.name}',
      subtitle: SettingsInfoCopy.aboutSubtitle,
      introIcon: Icons.favorite_outline_rounded,
      introTint: _tint,
      introTitle: AppInfo.name,
      sections: const [
        EchoInfoSection(
          title: '',
          paragraphs: [SettingsInfoCopy.aboutIntro],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.aboutPhilosophyTitle,
          paragraphs: [SettingsInfoCopy.aboutPhilosophy],
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.aboutFeaturesTitle,
          bullets: SettingsInfoCopy.aboutFeatures,
        ),
        EchoInfoSection(
          title: SettingsInfoCopy.aboutAiTitle,
          paragraphs: [SettingsInfoCopy.aboutAi],
        ),
        EchoInfoSection(
          title: '',
          paragraphs: [SettingsInfoCopy.aboutClosing],
        ),
      ],
      footer: EchoInfoVersionFooter(versionLabel: AppInfo.versionLabel),
    );
  }
}

void openAboutEchoPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const AboutEchoPage()),
  );
}
