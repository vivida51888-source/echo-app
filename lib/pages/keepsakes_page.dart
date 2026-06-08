import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/echo_achievement.dart';
import '../models/echo_shop_catalog.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_reward_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_typography.dart';
import '../utils/echo_achievement_feedback.dart';
import '../utils/echo_layout.dart';
import '../widgets/echo_coin_collect_overlay.dart';
import '../widgets/echo_confirm_sheet.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_moment_toast.dart';
import '../widgets/echo_coin_icon.dart';
import '../widgets/echo_count_badge.dart';
import '../widgets/scale_tap.dart';

enum KeepsakesTab { shop, vault }

class KeepsakesPage extends StatefulWidget {
  const KeepsakesPage({super.key, this.initialTab = KeepsakesTab.shop});

  final KeepsakesTab initialTab;

  @override
  State<KeepsakesPage> createState() => _KeepsakesPageState();
}

class _KeepsakesPageState extends State<KeepsakesPage> {
  final _service = EchoRewardService.instance;
  final _coinBadgeKey = GlobalKey();
  late KeepsakesTab _tab;
  var _playingCoins = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _service.addListener(_rebuild);
    _service.syncAchievements();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tab == KeepsakesTab.vault) _playVaultCoinAnimation();
    });
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _selectTab(KeepsakesTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (tab == KeepsakesTab.vault) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playVaultCoinAnimation();
      });
    }
  }

  Future<void> _playVaultCoinAnimation() async {
    if (_playingCoins || !mounted) return;
    _playingCoins = true;
    await playAchievementCoinAnimation(
      context,
      coinTargetKey: _coinBadgeKey,
    );
    _playingCoins = false;
  }

  Future<bool> _confirmPurchase(EchoShopItem item) async {
    return showEchoConfirmSheet(
      context,
      title: tr('确认兑换', 'Confirm redemption'),
      message: tr(
        '兑换「${item.name}」\n将消耗 ${item.price} 回响币',
        'Redeem «${item.name}» for ${item.price} Echo coins',
      ),
      confirmLabel: tr('兑换', 'Redeem'),
      cancelLabel: EchoStrings.current.cancel,
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: item.tint.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(item.icon, color: item.tint, size: 26),
      ),
    );
  }

  Future<void> _purchase(EchoShopItem item) async {
    if (!await _confirmPurchase(item)) return;

    final result = await _service.purchase(item);
    if (!mounted) return;
    if (result.ok) {
      await EchoCoinCollectOverlay.playSpend(
        context,
        amount: item.price,
        sourceKey: _coinBadgeKey,
      );
      if (!mounted) return;
      final message = item.isSkin
          ? tr('恭喜你解锁 ${item.name}', 'You unlocked ${item.name}!')
          : tr('恭喜你获得 ${item.name}', 'You got ${item.name}!');
      showEchoBriefHint(
        context,
        message: message,
        tone: EchoBriefHintTone.success,
      );
    } else if (result.error != null) {
      final error = result.error!;
      final coinShortage = error == tr('回响币不足', 'Not enough Echo coins');
      if (coinShortage) {
        await showEchoMomentToast(
          context,
          message: error,
          kind: EchoMomentToastKind.coins,
        );
      } else {
        showEchoBriefHint(
          context,
          message: error,
          tone: EchoBriefHintTone.gentle,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: EchoColors.appBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KeepsakesPageHeader(
                  tab: _tab,
                  coinBadgeKey: _coinBadgeKey,
                  coins: _service.coins,
                  vaultBadgeCount: _service.unreadAchievementCount,
                  onBack: () => Navigator.pop(context),
                  onTabChanged: _selectTab,
                ),
                Expanded(
                  child: _tab == KeepsakesTab.shop
                      ? _ShopView(
                          service: _service,
                          onPurchase: _purchase,
                        )
                      : _AchievementsView(service: _service),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KeepsakesPageHeader extends StatelessWidget {
  const _KeepsakesPageHeader({
    required this.tab,
    required this.coinBadgeKey,
    required this.coins,
    required this.vaultBadgeCount,
    required this.onBack,
    required this.onTabChanged,
  });

  final KeepsakesTab tab;
  final GlobalKey coinBadgeKey;
  final int coins;
  final int vaultBadgeCount;
  final VoidCallback onBack;
  final ValueChanged<KeepsakesTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final s = EchoStrings.of();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTap(
                onTap: onBack,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.keepsakesPageTitle,
                        style: EchoTypography.displayMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.4,
                          height: 1.1,
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _CoinBadge(
                  key: coinBadgeKey,
                  coins: coins,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: EchoColors.daySurface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(EchoRadii.lg),
                border: Border.all(
                  color: EchoColors.dayDivider.withValues(alpha: 0.55),
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: _KeepsakesTabBar(
                  tab: tab,
                  vaultBadgeCount: vaultBadgeCount,
                  onChanged: onTabChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EchoCoinIcon(size: 18),
        const SizedBox(width: 4),
        Text(
          '$coins',
          style: EchoTypography.labelLarge.copyWith(
            color: const Color(0xFF8A6A28),
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          tr('回响币', 'coins'),
          style: EchoTypography.micro.copyWith(
            color: const Color(0xFF8A6A28).withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _KeepsakesTabBar extends StatelessWidget {
  const _KeepsakesTabBar({
    required this.tab,
    required this.onChanged,
    this.vaultBadgeCount = 0,
  });

  final KeepsakesTab tab;
  final ValueChanged<KeepsakesTab> onChanged;
  final int vaultBadgeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabUnderline(
            label: EchoStrings.current.echoShopTitle,
            selected: tab == KeepsakesTab.shop,
            centered: true,
            onTap: () => onChanged(KeepsakesTab.shop),
          ),
        ),
        Expanded(
          child: EchoCountBadge(
            count: vaultBadgeCount,
            size: 8,
            offset: const Offset(-2, -2),
            child: _TabUnderline(
              label: EchoStrings.current.personalVaultTitle,
              selected: tab == KeepsakesTab.vault,
              centered: true,
              onTap: () => onChanged(KeepsakesTab.vault),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabUnderline extends StatelessWidget {
  const _TabUnderline({
    required this.label,
    required this.selected,
    required this.onTap,
    this.centered = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: EchoTypography.labelLarge.copyWith(
              color: selected
                  ? EchoColors.dayTextPrimary
                  : EchoColors.dayTextWhisper,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w300,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: selected ? 32 : 0,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFC99A3A).withValues(alpha: 0.75)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 回响小铺：分类网格 + 真实预览图 ─────────────────────────────

class _ShopView extends StatelessWidget {
  const _ShopView({
    required this.service,
    required this.onPurchase,
  });

  final EchoRewardService service;
  final Future<void> Function(EchoShopItem item) onPurchase;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      children: [
        for (final cat in EchoShopCategory.values) ...[
          _CategoryHeader(label: cat.label),
          const SizedBox(height: 12),
          if (cat == EchoShopCategory.dew)
            _DewGrid(
              items: EchoShopCatalog.forCategory(cat),
              service: service,
              onPurchase: onPurchase,
            )
          else
            _SkinGrid(
              items: EchoShopCatalog.forCategory(cat),
              service: service,
              onPurchase: onPurchase,
            ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: EchoTypography.titleMedium.copyWith(
              color: EchoColors.dayTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkinGrid extends StatelessWidget {
  const _SkinGrid({
    required this.items,
    required this.service,
    required this.onPurchase,
  });

  final List<EchoShopItem> items;
  final EchoRewardService service;
  final Future<void> Function(EchoShopItem item) onPurchase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = EchoLayout.shopGridSpacing(context);
        final columns = EchoLayout.shopGridColumns(context);
        final cellW =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: [
            for (final item in items)
              SizedBox(
                width: cellW,
                child: _SkinTile(
                  item: item,
                  owned: service.isShopItemOwned(item),
                  canBuy: service.canAfford(item),
                  onTap: service.isShopItemOwned(item)
                      ? null
                      : () => onPurchase(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.item,
    required this.owned,
    required this.canBuy,
    this.onTap,
  });

  final EchoShopItem item;
  final bool owned;
  final bool canBuy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final asset = item.previewAsset;

    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Opacity(
        opacity: owned ? 0.65 : 1,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: item.kind == EchoShopItemKind.stationerySkin
                  ? 0.72
                  : 1.05,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: asset != null
                        ? Image.asset(
                            asset,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : ColoredBox(color: item.tint.withValues(alpha: 0.2)),
                  ),
                  if (owned)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tr('已拥有', 'Owned'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else if (!canBuy)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: EchoTypography.caption.copyWith(
                color: EchoColors.dayTextPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            _PriceRow(price: item.price, dimmed: !owned && !canBuy),
          ],
        ),
      ),
    );
  }
}

class _DewGrid extends StatelessWidget {
  const _DewGrid({
    required this.items,
    required this.service,
    required this.onPurchase,
  });

  final List<EchoShopItem> items;
  final EchoRewardService service;
  final Future<void> Function(EchoShopItem item) onPurchase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = EchoLayout.shopGridSpacing(context);
        final columns = MediaQuery.sizeOf(context).width < 360 ? 2 : 3;
        final cellW =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            for (final item in items)
              SizedBox(
                width: cellW,
                child: ScaleTap(
                  onTap: service.canAfford(item)
                      ? () => onPurchase(item)
                      : null,
                  scale: 0.97,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                item.tint.withValues(alpha: 0.35),
                                item.tint.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            size: 28,
                            color: item.tint,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: EchoTypography.micro.copyWith(
                          color: EchoColors.dayTextSecondary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _PriceRow(
                        price: item.price,
                        dimmed: !service.canAfford(item),
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.price,
    this.dimmed = false,
    this.compact = false,
  });

  final int price;
  final bool dimmed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = dimmed
        ? EchoColors.dayTextWhisper
        : const Color(0xFF8A6A28);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        EchoCoinIcon(
          size: compact ? 12 : 14,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          '$price',
          style: (compact
                  ? EchoTypography.micro
                  : EchoTypography.labelMedium)
              .copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 3),
          Text(
            tr('回响币', 'coins'),
            style: EchoTypography.micro.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

// ─── 个人成就：海岛奇兵式列表 + 三星 ─────────────────────────────

class _AchievementsView extends StatelessWidget {
  const _AchievementsView({required this.service});

  final EchoRewardService service;

  @override
  Widget build(BuildContext context) {
    final starsEarned = EchoAchievements.all.fold<int>(
      0,
      (sum, def) => sum + service.claimedTierLevel(def.id),
    );
    final maxStars = EchoAchievements.all.length * 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('总星数', 'Total stars'),
                      style: EchoTypography.caption.copyWith(
                        color: EchoColors.dayTextWhisper,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$starsEarned / $maxStars',
                      style: EchoTypography.titleMedium.copyWith(
                        color: EchoColors.dayTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final cat in EchoAchievementCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(
              cat.label.toUpperCase(),
              style: EchoTypography.micro.copyWith(
                color: EchoColors.dayTextWhisper,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (var i = 0; i < EchoAchievements.forCategory(cat).length; i++) ...[
            _AchievementRow(
              def: EchoAchievements.forCategory(cat)[i],
              progress: service.progressFor(
                EchoAchievements.forCategory(cat)[i],
              ),
              claimedStars: service.claimedTierLevel(
                EchoAchievements.forCategory(cat)[i].id,
              ),
            ),
            if (i < EchoAchievements.forCategory(cat).length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                color: EchoColors.dayDivider.withValues(alpha: 0.65),
              ),
          ],
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.def,
    required this.progress,
    required this.claimedStars,
  });

  final EchoAchievementDef def;
  final int progress;
  final int claimedStars;

  @override
  Widget build(BuildContext context) {
    final stars = def.starCount(claimedStars);
    final done = stars >= 3;
    final nextThreshold = done
        ? def.tiers.last.threshold
        : def.tiers[claimedStars.clamp(0, 2)].threshold;
    final progressRatio = done
        ? 1.0
        : (progress / nextThreshold).clamp(0.0, 1.0);

    return ScaleTap(
      onTap: () => showEchoAchievementDetailSheet(
        context,
        def: def,
        progress: progress,
        claimedStars: claimedStars,
      ),
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AchievementBadge(
              icon: def.icon,
              tint: def.tint,
              stars: stars,
              done: done,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          def.name,
                          style: EchoTypography.labelLarge.copyWith(
                            color: EchoColors.dayTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _StarRow(filled: stars),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.nextGoalText(progress, claimedStars),
                    style: EchoTypography.caption.copyWith(
                      color: done
                          ? def.tint.withValues(alpha: 0.9)
                          : EchoColors.dayTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (!done) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 4,
                        backgroundColor:
                            EchoColors.dayDivider.withValues(alpha: 0.45),
                        color: def.tint.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: EchoColors.dayTextWhisper.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.icon,
    required this.tint,
    required this.stars,
    required this.done,
  });

  final IconData icon;
  final Color tint;
  final int stars;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: done ? 0.28 : 0.14),
            tint.withValues(alpha: done ? 0.12 : 0.05),
          ],
        ),
        border: Border.all(
          color: done
              ? const Color(0xFFE8C878).withValues(alpha: 0.75)
              : EchoColors.dayDivider.withValues(alpha: 0.55),
          width: done ? 1.5 : 0.5,
        ),
      ),
      child: Icon(
        icon,
        size: 24,
        color: done ? tint : tint.withValues(alpha: 0.75),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18,
              color: i < filled
                  ? const Color(0xFFE8C878)
                  : EchoColors.dayDivider,
            ),
          ),
      ],
    );
  }
}

void showEchoAchievementDetailSheet(
  BuildContext context, {
  required EchoAchievementDef def,
  required int progress,
  required int claimedStars,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewPaddingOf(ctx).bottom;
      return Container(
        decoration: BoxDecoration(
          color: EchoColors.daySurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(EchoRadii.xl),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EchoColors.dayDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _AchievementBadge(
                  icon: def.icon,
                  tint: def.tint,
                  stars: def.starCount(claimedStars),
                  done: claimedStars >= 3,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: EchoTypography.titleMedium.copyWith(
                          color: EchoColors.dayTextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        def.hint,
                        style: EchoTypography.caption.copyWith(
                          color: EchoColors.dayTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              def.progressSummary(progress, claimedStars),
              style: EchoTypography.labelMedium.copyWith(
                color: EchoColors.dayTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < def.tiers.length; i++) ...[
              _AchievementTierDetailRow(
                detail: def.tierRequirementDetail(i),
                earned: i < claimedStars,
                tint: def.tint,
              ),
              if (i < def.tiers.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      );
    },
  );
}

class _AchievementTierDetailRow extends StatelessWidget {
  const _AchievementTierDetailRow({
    required this.detail,
    required this.earned,
    required this.tint,
  });

  final String detail;
  final bool earned;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: earned
            ? tint.withValues(alpha: 0.08)
            : EchoColors.appBackground,
        borderRadius: BorderRadius.circular(EchoRadii.sm),
        border: Border.all(
          color: earned
              ? tint.withValues(alpha: 0.25)
              : EchoColors.dayDivider.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            earned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: earned ? tint : EchoColors.dayTextWhisper,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail,
              style: EchoTypography.caption.copyWith(
                color: earned
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

void openPersonalAchievementsPage(BuildContext context) {
  openKeepsakesPage(context, initialTab: KeepsakesTab.vault);
}

/// 兼容旧入口名。
void openPersonalVaultPage(BuildContext context) =>
    openPersonalAchievementsPage(context);
