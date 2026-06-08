import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../navigation/app_page_route.dart';
import '../services/locale_service.dart';
import '../utils/app_info.dart';
import '../utils/settings_info_copy.dart';
import '../widgets/echo_info_page.dart';

class AboutEchoPage extends StatelessWidget {
  const AboutEchoPage({super.key});

  static const _tint = Color(0xFF8B7355);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        return EchoInfoPage(
      title: tr('关于 ${AppInfo.name}', 'About ${AppInfo.name}'),
      subtitle: SettingsInfoCopy.aboutSubtitle,
      introIcon: Icons.favorite_outline_rounded,
      introTint: _tint,
      introTitle: AppInfo.name,
      sections: [
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
      },
    );
  }
}

void openAboutEchoPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const AboutEchoPage()),
  );
}
