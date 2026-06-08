import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../navigation/app_page_route.dart';
import '../services/locale_service.dart';
import '../theme/echo_spacing.dart';
import '../widgets/echo_settings_layout.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  static const _tint = Color(0xFF7A8FA8);

  final _service = LocaleService.instance;

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
    final s = EchoStrings.of();

    return EchoSettingsScaffold(
      title: s.languagePageTitle,
      children: [
        EchoSettingsSectionCard(
          tint: _tint,
          icon: Icons.translate_rounded,
          title: s.languagePageTitle,
          description: s.languageSubtitle,
          child: Column(
            children: LocaleService.supportedOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: EchoSpacing.xs),
                child: EchoSettingsChoiceChip(
                  label: _service.optionLabel(option),
                  subtitle: _service.optionSubtitle(option),
                  selected: _service.selectedId == option.id,
                  tint: _tint,
                  onTap: () => _service.setSelectedId(option.id),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: EchoSpacing.lg),
        EchoSettingsFootnote(s.languagePageFootnote),
      ],
    );
  }
}

void openLanguagePage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const LanguagePage()),
  );
}
