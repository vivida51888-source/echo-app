import 'package:flutter/material.dart';

import '../models/echo_collectible.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_collectible_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../widgets/scale_tap.dart';

enum KeepsakesTab { shop, vault }

class KeepsakesPage extends StatefulWidget {
  const KeepsakesPage({super.key, this.initialTab = KeepsakesTab.shop});

  final KeepsakesTab initialTab;

  @override
  State<KeepsakesPage> createState() => _KeepsakesPageState();
}

class _KeepsakesPageState extends State<KeepsakesPage> {
  final _service = EchoCollectibleService.instance;
  late KeepsakesTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
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
    return Scaffold(
      backgroundColor: EchoColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  ScaleTap(
                    onTap: () => Navigator.pop(context),
                    scale: 0.9,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '回响拾遗',
                    style: EchoTypography.displayMedium.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '情绪小铺遇见可能，个人仓库留住所得',
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.dayTextWhisper,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: _KeepsakesTabBar(
                tab: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                children: [
                  if (_tab == KeepsakesTab.shop)
                    ..._buildShop()
                  else
                    ..._buildVault(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShop() {
    final streak = _service.todoCompletionStreak;
    return [
      for (final kind in EchoCollectibleKind.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShopCard(
            kind: kind,
            owned: _service.countOf(kind),
            streak: kind == EchoCollectibleKind.focusFlower ? streak : null,
            grantedTiers: kind == EchoCollectibleKind.focusFlower
                ? _service.grantedFlowerTiers
                : const {},
          ),
        ),
    ];
  }

  List<Widget> _buildVault() {
    final items = _service.items;
    if (items.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
              Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: EchoColors.dayTextWhisper,
              ),
              const SizedBox(height: 14),
              Text(
                '仓库还空着',
                style: EchoTypography.titleMedium.copyWith(
                  color: EchoColors.dayTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '去情绪小铺看看，完成小事就会落下纪念',
                textAlign: TextAlign.center,
                style: EchoTypography.caption.copyWith(
                  color: EchoColors.dayTextWhisper,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            _VaultTile(item: item),
        ],
      ),
    ];
  }
}

class _KeepsakesTabBar extends StatelessWidget {
  const _KeepsakesTabBar({
    required this.tab,
    required this.onChanged,
  });

  final KeepsakesTab tab;
  final ValueChanged<KeepsakesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabChip(
            label: '情绪小铺',
            selected: tab == KeepsakesTab.shop,
            onTap: () => onChanged(KeepsakesTab.shop),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabChip(
            label: '个人仓库',
            selected: tab == KeepsakesTab.vault,
            onTap: () => onChanged(KeepsakesTab.vault),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? EchoColors.dayTextPrimary.withValues(alpha: 0.08)
              : EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.md),
          border: Border.all(
            color: selected
                ? EchoColors.dayTextPrimary.withValues(alpha: 0.18)
                : EchoColors.dayDivider.withValues(alpha: 0.55),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: EchoTypography.labelMedium.copyWith(
            color: selected
                ? EchoColors.dayTextPrimary
                : EchoColors.dayTextSecondary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.kind,
    required this.owned,
    this.streak,
    this.grantedTiers = const {},
  });

  final EchoCollectibleKind kind;
  final int owned;
  final int? streak;
  final Set<int> grantedTiers;

  @override
  Widget build(BuildContext context) {
    final tint = kind.tint;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.14),
            EchoColors.daySurface,
          ],
        ),
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: tint.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(kind.icon, size: 24, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      kind.name,
                      style: EchoTypography.titleMedium.copyWith(
                        color: EchoColors.dayTextPrimary,
                      ),
                    ),
                    if (owned > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(EchoRadii.pill),
                        ),
                        child: Text(
                          '已得 $owned',
                          style: EchoTypography.micro.copyWith(
                            color: tint.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  kind.shopHint,
                  style: EchoTypography.bodyMedium.copyWith(
                    color: EchoColors.dayTextSecondary,
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kind.earnDetail,
                  style: EchoTypography.caption.copyWith(
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
                if (kind == EchoCollectibleKind.focusFlower) ...[
                  const SizedBox(height: 10),
                  Text(
                    '当前连续 $streak 天',
                    style: EchoTypography.caption.copyWith(
                      color: tint.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tier in EchoCollectibleService.flowerTiers)
                        _TierChip(
                          label: '$tier 天',
                          rare: tier >= 7,
                          unlocked: grantedTiers.contains(tier),
                          tint: tint,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.label,
    required this.rare,
    required this.unlocked,
    required this.tint,
  });

  final String label;
  final bool rare;
  final bool unlocked;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: unlocked
            ? tint.withValues(alpha: rare ? 0.2 : 0.12)
            : EchoColors.appBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(EchoRadii.pill),
        border: Border.all(
          color: unlocked
              ? tint.withValues(alpha: 0.35)
              : EchoColors.dayDivider.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Text(
        unlocked ? '$label ✓' : label,
        style: EchoTypography.micro.copyWith(
          color: unlocked
              ? tint
              : EchoColors.dayTextWhisper,
          fontWeight: unlocked ? FontWeight.w500 : FontWeight.w300,
        ),
      ),
    );
  }
}

class _VaultTile extends StatelessWidget {
  const _VaultTile({required this.item});

  final EchoCollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final tint = item.kind.tint;
    final width = (MediaQuery.sizeOf(context).width - 56 - 10) / 2;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: item.isRare
              ? tint.withValues(alpha: 0.42)
              : EchoColors.dayDivider.withValues(alpha: 0.55),
          width: item.isRare ? 0.8 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: item.isRare ? 0.08 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.kind.icon, size: 18, color: tint),
              ),
              if (item.isRare) ...[
                const Spacer(),
                Text(
                  '稀有',
                  style: EchoTypography.micro.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.displayName,
            style: EchoTypography.labelLarge.copyWith(
              color: EchoColors.dayTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DiaryFormat.listDateLabel(item.earnedAt),
            style: EchoTypography.micro.copyWith(
              color: EchoColors.dayTextWhisper,
            ),
          ),
        ],
      ),
    );
  }
}

void showCollectibleEarnedSnack(
  BuildContext context,
  EchoCollectibleItem item,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '获得 ${item.displayName}',
        style: const TextStyle(fontWeight: FontWeight.w300),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: EchoColors.dayTextPrimary,
    ),
  );
}

void openKeepsakesPage(
  BuildContext context, {
  KeepsakesTab initialTab = KeepsakesTab.shop,
}) {
  Navigator.of(context).push(
    AppPageRoute<void>(
      builder: (_) => KeepsakesPage(initialTab: initialTab),
    ),
  );
}

void openPersonalVaultPage(BuildContext context) {
  openKeepsakesPage(context, initialTab: KeepsakesTab.vault);
}
