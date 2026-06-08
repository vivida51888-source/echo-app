import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../l10n/localized.dart';
import '../navigation/app_page_route.dart';
import '../services/locale_service.dart';
import '../utils/legal_links.dart';
import '../utils/settings_info_copy.dart';
import '../widgets/echo_info_page.dart';
import '../widgets/echo_settings_layout.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _tint = Color(0xFF8B7355);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        return EchoInfoPage(
          title: tr('服务条款', 'Terms of Service'),
          subtitle: SettingsInfoCopy.termsSubtitle,
          introIcon: Icons.article_outlined,
          introTint: _tint,
          introTitle: tr('使用约定', 'Agreement'),
          sections: [
            EchoInfoSection(
              title: '',
              paragraphs: [SettingsInfoCopy.termsIntro],
            ),
            EchoInfoSection(
              title: SettingsInfoCopy.termsUseTitle,
              bullets: SettingsInfoCopy.termsUse,
            ),
            EchoInfoSection(
              title: SettingsInfoCopy.termsPlusTitle,
              paragraphs: [SettingsInfoCopy.termsPlus],
            ),
            EchoInfoSection(
              title: SettingsInfoCopy.termsLimitTitle,
              bullets: SettingsInfoCopy.termsLimit,
            ),
            EchoInfoSection(
              title: SettingsInfoCopy.termsLiabilityTitle,
              paragraphs: [SettingsInfoCopy.termsLiability],
            ),
            EchoInfoSection(
              title: SettingsInfoCopy.termsChangesTitle,
              paragraphs: [SettingsInfoCopy.termsChanges],
            ),
          ],
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EchoSettingsFootnote(
                tr(
                  '联系：${AppConfig.supportEmail}',
                  'Contact: ${AppConfig.supportEmail}',
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => openSupportEmail(context),
                  child: Text(tr('发送邮件', 'Send email')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void openTermsPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const TermsPage()),
  );
}
