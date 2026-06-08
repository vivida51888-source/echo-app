import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../l10n/localized.dart';
import '../widgets/echo_hint.dart';

Future<void> openPrivacyPolicyUrl(BuildContext context) =>
    _openConfiguredUrl(
      context,
      url: AppConfig.privacyPolicyUrl,
      missing: tr(
        '隐私政策链接尚未配置。请将 docs/privacy.html 部署到公网后，'
        '在 lib/config/app_config.dart 填写 privacyPolicyUrl。',
        'Privacy policy URL is not configured yet. Host docs/privacy.html '
        'and set privacyPolicyUrl in lib/config/app_config.dart.',
      ),
    );

Future<void> openTermsOfServiceUrl(BuildContext context) =>
    _openConfiguredUrl(
      context,
      url: AppConfig.termsOfServiceUrl,
      missing: tr(
        '在线服务条款链接尚未配置，请查看应用内服务条款。',
        'Online terms URL is not configured — see in-app Terms of Service.',
      ),
    );

Future<void> openSupportEmail(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppConfig.supportEmail,
    query: 'subject=${Uri.encodeComponent('Echo support')}',
  );
  if (!await launchUrl(uri)) {
    if (!context.mounted) return;
    showEchoBriefHint(
      context,
      message: AppConfig.supportEmail,
      tone: EchoBriefHintTone.neutral,
    );
  }
}

Future<void> _openConfiguredUrl(
  BuildContext context, {
  required String url,
  required String missing,
}) async {
  if (url.isEmpty) {
    if (!context.mounted) return;
    showEchoBriefHint(context, message: missing, tone: EchoBriefHintTone.gentle);
    return;
  }
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) return;
    showEchoBriefHint(
      context,
      message: tr('无法打开链接', 'Could not open link'),
      tone: EchoBriefHintTone.gentle,
    );
  }
}
