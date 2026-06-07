import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import 'echo_settings_layout.dart';

/// 设置类信息页：标题 + 分段正文 / 要点列表。
class EchoInfoSection {
  const EchoInfoSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

class EchoInfoPage extends StatelessWidget {
  const EchoInfoPage({
    super.key,
    required this.title,
    this.subtitle,
    this.introIcon,
    this.introTint,
    this.introTitle,
    required this.sections,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final IconData? introIcon;
  final Color? introTint;
  final String? introTitle;
  final List<EchoInfoSection> sections;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final tint = introTint ?? const Color(0xFF8B7355);

    return EchoSettingsScaffold(
      title: title,
      children: [
        if (introIcon != null && introTitle != null && subtitle != null) ...[
          EchoSettingsIntroBanner(
            icon: introIcon!,
            tint: tint,
            title: introTitle!,
            description: subtitle!,
          ),
          const SizedBox(height: EchoSpacing.xl),
        ],
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: EchoSpacing.md),
          _InfoSectionCard(section: sections[i], tint: tint),
        ],
        if (footer != null) ...[
          const SizedBox(height: EchoSpacing.xl),
          footer!,
        ],
      ],
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.section,
    required this.tint,
  });

  final EchoInfoSection section;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final hasTitle = section.title.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EchoSpacing.lg,
          EchoSpacing.lg,
          EchoSpacing.lg,
          EchoSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasTitle) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: EchoSpacing.sm),
                  Expanded(
                    child: Text(
                      section.title,
                      style: EchoTypography.titleMedium.copyWith(
                        color: EchoColors.dayTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EchoSpacing.md),
            ],
            if (section.paragraphs.isNotEmpty)
              for (final paragraph in section.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: EchoSpacing.sm),
                  child: Text(
                    paragraph,
                    style: EchoTypography.bodyMedium.copyWith(
                      color: EchoColors.dayTextSecondary,
                      height: 1.75,
                    ),
                  ),
                ),
            if (section.bullets.isNotEmpty)
              ...section.bullets.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: EchoSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 9,
                          right: EchoSpacing.sm,
                        ),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(EchoRadii.full),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: EchoTypography.bodyMedium.copyWith(
                            color: EchoColors.dayTextSecondary,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EchoInfoVersionFooter extends StatelessWidget {
  const EchoInfoVersionFooter({
    super.key,
    required this.versionLabel,
  });

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: EchoSpacing.lg),
      decoration: BoxDecoration(
        color: EchoColors.dayWriting.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(EchoRadii.md),
      ),
      child: Text(
        versionLabel,
        textAlign: TextAlign.center,
        style: EchoTypography.caption.copyWith(
          color: EchoColors.dayTextWhisper,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
