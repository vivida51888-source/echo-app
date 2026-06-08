import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import 'echo_count_badge.dart';
import 'scale_tap.dart';

/// 设置子页统一脚手架。
class EchoSettingsScaffold extends StatelessWidget {
  const EchoSettingsScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(
      EchoSpacing.pageHorizontal,
      EchoSpacing.xs,
      EchoSpacing.pageHorizontal,
      EchoSpacing.xxl,
    ),
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.appBackground,
      appBar: AppBar(
        backgroundColor: EchoColors.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: EchoTypography.titleMedium.copyWith(
            color: EchoColors.dayTextPrimary,
          ),
        ),
        actions: actions,
      ),
      body: ListView(
        padding: padding,
        children: children,
      ),
    );
  }
}

/// 设置页顶部引导条。
class EchoSettingsIntroBanner extends StatelessWidget {
  const EchoSettingsIntroBanner({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.lg,
        EchoSpacing.lg,
        EchoSpacing.lg,
        EchoSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.08),
            EchoColors.daySurface,
          ],
        ),
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(EchoRadii.sm),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: EchoSpacing.sm),
          Text(
            title,
            style: EchoTypography.titleLarge.copyWith(
              color: EchoColors.dayTextPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: EchoSpacing.xxs),
          Text(
            description,
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置分组标题（用于主页列表）。
class EchoSettingsGroupLabel extends StatelessWidget {
  const EchoSettingsGroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: EchoSpacing.xxs,
        bottom: EchoSpacing.sm,
        top: EchoSpacing.md,
      ),
      child: Text(
        label,
        style: EchoTypography.micro.copyWith(
          color: EchoColors.dayTextWhisper,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 主页设置项分组卡片。
class EchoSettingsGroup extends StatelessWidget {
  const EchoSettingsGroup({
    super.key,
    this.label,
    required this.children,
  });

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) EchoSettingsGroupLabel(label!),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EchoColors.daySurface,
            borderRadius: BorderRadius.circular(EchoRadii.lg),
            border: Border.all(
              color: EchoColors.dayDivider.withValues(alpha: 0.65),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EchoRadii.lg),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: EchoSpacing.md,
                      color: EchoColors.dayDivider.withValues(alpha: 0.45),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: EchoSpacing.lg),
      ],
    );
  }
}

/// 分组内开关项（与 [EchoSettingsListTile] 同款样式，右侧为开关）。
class EchoSettingsGroupSwitchTile extends StatelessWidget {
  const EchoSettingsGroupSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.iconTint,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    final tint = iconTint ?? EchoColors.dayTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.md,
        EchoSpacing.md,
        EchoSpacing.sm,
        EchoSpacing.md,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(EchoRadii.sm),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: EchoSpacing.sm + 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EchoTypography.bodyLarge.copyWith(
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: EchoSpacing.xxs),
                  Text(
                    subtitle!,
                    style: EchoTypography.labelMedium.copyWith(
                      color: EchoColors.dayTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 分组内列表项。
class EchoSettingsListTile extends StatelessWidget {
  const EchoSettingsListTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconTint,
    this.enabled = true,
    this.badgeCount = 0,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconTint;
  final VoidCallback onTap;
  final bool enabled;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final tint = iconTint ?? EchoColors.dayTextSecondary;

    return ScaleTap(
      onTap: enabled ? onTap : null,
      scale: 0.98,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EchoSpacing.md,
            EchoSpacing.md,
            EchoSpacing.sm + 2,
            EchoSpacing.md,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(EchoRadii.sm),
                  ),
                  child: Icon(icon, size: 18, color: tint),
                ),
                const SizedBox(width: EchoSpacing.sm + 2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EchoTypography.bodyLarge.copyWith(
                        color: EchoColors.dayTextPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: EchoSpacing.xxs),
                      Text(
                        subtitle!,
                        style: EchoTypography.labelMedium.copyWith(
                          color: EchoColors.dayTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              EchoCountBadge(
                count: badgeCount,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: EchoColors.dayTextWhisper,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 功能区块卡片（子页内大块内容）。
class EchoSettingsSectionCard extends StatelessWidget {
  const EchoSettingsSectionCard({
    super.key,
    required this.tint,
    required this.icon,
    required this.title,
    this.description,
    required this.child,
  });

  final Color tint;
  final IconData icon;
  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.65),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(EchoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(EchoRadii.sm),
                  ),
                  child: Icon(icon, size: 20, color: tint),
                ),
                const SizedBox(width: EchoSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: EchoTypography.bodyLarge.copyWith(
                          color: EchoColors.dayTextPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: EchoSpacing.xxs),
                        Text(
                          description!,
                          style: EchoTypography.caption.copyWith(
                            color: EchoColors.dayTextSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: EchoSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

/// 卡片内浅色底面板。
class EchoSettingsInsetPanel extends StatelessWidget {
  const EchoSettingsInsetPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EchoColors.appBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

/// 开关行。
class EchoSettingsSwitchTile extends StatelessWidget {
  const EchoSettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconTint,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    final tint = iconTint ?? EchoColors.dayTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EchoSpacing.md,
        vertical: EchoSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: EchoSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EchoTypography.bodyMedium.copyWith(
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.dayTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 单选项（描边芯片）。
class EchoSettingsChoiceChip extends StatelessWidget {
  const EchoSettingsChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.tint,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? EchoColors.dayTextPrimary;

    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : EchoColors.appBackground.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(EchoRadii.md),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.35)
                : EchoColors.dayDivider.withValues(alpha: 0.45),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? accent : EchoColors.dayTextWhisper,
            ),
            const SizedBox(width: EchoSpacing.sm),
            Expanded(
              child: subtitle == null
                  ? Text(
                      label,
                      style: EchoTypography.bodyMedium.copyWith(
                        color: EchoColors.dayTextPrimary,
                        fontWeight:
                            selected ? FontWeight.w400 : FontWeight.w300,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: EchoTypography.bodyMedium.copyWith(
                            color: EchoColors.dayTextPrimary,
                            fontWeight:
                                selected ? FontWeight.w400 : FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: EchoTypography.caption.copyWith(
                            color: EchoColors.dayTextWhisper,
                          ),
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

/// 标签组。
class EchoSettingsTagRow extends StatelessWidget {
  const EchoSettingsTagRow({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: EchoSpacing.xs,
      runSpacing: EchoSpacing.xs,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EchoColors.appBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(EchoRadii.pill),
              border: Border.all(
                color: EchoColors.dayDivider.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              tag,
              style: EchoTypography.micro.copyWith(
                color: EchoColors.dayTextSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
      ],
    );
  }
}

/// 轻量操作按钮。
class EchoSettingsActionButton extends StatelessWidget {
  const EchoSettingsActionButton({
    super.key,
    required this.label,
    required this.tint,
    this.icon,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final Color tint;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;

    return ScaleTap(
      onTap: enabled ? onTap : null,
      scale: enabled ? 0.98 : 1,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(EchoRadii.md),
            border: Border.all(
              color: tint.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tint,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: tint),
              if (icon != null || busy) const SizedBox(width: EchoSpacing.xs),
              Text(
                label,
                style: EchoTypography.labelLarge.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态卡片。
class EchoSettingsEmptyCard extends StatelessWidget {
  const EchoSettingsEmptyCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.message,
  });

  final IconData icon;
  final Color tint;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EchoSpacing.xl,
        vertical: EchoSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(EchoRadii.full),
            ),
            child: Icon(icon, size: 24, color: tint.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: EchoSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: EchoTypography.bodyMedium.copyWith(
              color: EchoColors.dayTextSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// 页脚说明。
class EchoSettingsFootnote extends StatelessWidget {
  const EchoSettingsFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: EchoTypography.micro.copyWith(
        color: EchoColors.dayTextWhisper,
        height: 1.65,
      ),
    );
  }
}
