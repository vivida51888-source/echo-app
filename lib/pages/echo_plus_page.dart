import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/localized.dart';
import '../models/echo_plus_catalog.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_plus_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_settings_layout.dart';
import '../widgets/scale_tap.dart';

class EchoPlusPage extends StatefulWidget {
  const EchoPlusPage({super.key});

  @override
  State<EchoPlusPage> createState() => _EchoPlusPageState();
}

class _EchoPlusPageState extends State<EchoPlusPage> {
  static const _tint = Color(0xFFC99A3A);

  final _plus = EchoPlusService.instance;

  @override
  void initState() {
    super.initState();
    _plus.addListener(_rebuild);
  }

  @override
  void dispose() {
    _plus.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _openManageSubscriptions() async {
    final sku = _plus.monthlyProduct?.id ?? EchoPlusCatalog.monthlyId;
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=${EchoPlusCatalog.packageName}&sku=$sku',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showEchoBriefHint(
        context,
        message: tr(
          '无法打开订阅管理',
          'Could not open subscription management',
        ),
        tone: EchoBriefHintTone.gentle,
      );
    }
  }

  String _activeDescription() {
    if (_plus.hasLifetime) {
      return tr(
        '已永久解锁全部照片墙与信纸皮肤',
        'All photo wall and stationery skins are yours forever',
      );
    }
    return tr(
      '照片墙与信纸皮肤已全部可用',
      'All photo wall and stationery skins are unlocked',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) => EchoSettingsScaffold(
        title: tr('Echo Plus', 'Echo Plus'),
        children: [
          EchoSettingsIntroBanner(
            icon: Icons.workspace_premium_rounded,
            tint: _tint,
            title: _plus.isActive
                ? (_plus.hasLifetime
                    ? tr('已永久开通 Echo Plus', 'Echo Plus — lifetime')
                    : tr('已开通 Echo Plus', 'Echo Plus is active'))
                : tr('解锁全部装扮', 'Unlock every look'),
            description: _plus.isActive
                ? _activeDescription()
                : tr(
                    '月付、年付或一次买断，均可解锁全部墙面与信纸；写日记、待办与导出仍免费',
                    'Monthly, yearly, or lifetime — all unlock every skin. '
                        'Writing, tasks & export stay free',
                  ),
          ),
          const SizedBox(height: EchoSpacing.lg),
          EchoSettingsSectionCard(
            tint: _tint,
            icon: Icons.auto_awesome_outlined,
            title: tr('Plus 包含', 'Included in Plus'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _benefit(tr('全部照片墙皮肤', 'All photo wall skins')),
                _benefit(tr('全部日记信纸', 'All diary stationery')),
                _benefit(
                  tr(
                    '回响币仍可赚取，用于雨露等消耗品',
                    'Echo coins still work for dew & consumables',
                  ),
                ),
              ],
            ),
          ),
          if (!_plus.storeAvailable) ...[
            const SizedBox(height: EchoSpacing.md),
            EchoSettingsFootnote(
              tr(
                '当前设备无法连接 Google Play 结算（请使用已安装 Play 商店的 Android 设备）',
                'Google Play Billing is unavailable on this device '
                    '(use an Android device with Play Store)',
              ),
            ),
          ] else if (_plus.isActive) ...[
            const SizedBox(height: EchoSpacing.md),
            if (_plus.hasActiveSubscription && !_plus.hasLifetime)
              EchoSettingsSectionCard(
                tint: _tint,
                icon: Icons.check_circle_outline_rounded,
                title: tr('管理订阅', 'Manage subscription'),
                description: tr(
                  '在 Google Play 中查看账单、取消或更改方案',
                  'View billing, cancel, or change plan in Google Play',
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ScaleTap(
                    onTap: _openManageSubscriptions,
                    child: Text(
                      tr('打开 Google Play', 'Open Google Play'),
                      style: EchoTypography.labelMedium.copyWith(
                        color: _tint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ] else ...[
            const SizedBox(height: EchoSpacing.md),
            if (_plus.loadingProducts)
              const Padding(
                padding: EdgeInsets.all(EchoSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_plus.yearlyProduct != null)
                _PlanTile(
                  product: _plus.yearlyProduct!,
                  plan: _PlusPlan.yearly,
                  badge: tr('推荐', 'Best value'),
                  selected: true,
                  tint: _tint,
                  busy: _plus.purchaseInFlight,
                  onTap: () => _plus.buy(_plus.yearlyProduct!),
                ),
              if (_plus.lifetimeProduct != null) ...[
                const SizedBox(height: EchoSpacing.sm),
                _PlanTile(
                  product: _plus.lifetimeProduct!,
                  plan: _PlusPlan.lifetime,
                  badge: tr('一次付清', 'Pay once'),
                  tint: _tint,
                  busy: _plus.purchaseInFlight,
                  onTap: () => _plus.buy(_plus.lifetimeProduct!),
                ),
              ],
              if (_plus.monthlyProduct != null) ...[
                const SizedBox(height: EchoSpacing.sm),
                _PlanTile(
                  product: _plus.monthlyProduct!,
                  plan: _PlusPlan.monthly,
                  tint: _tint,
                  busy: _plus.purchaseInFlight,
                  onTap: () => _plus.buy(_plus.monthlyProduct!),
                ),
              ],
              if (_plus.products.isEmpty)
                EchoSettingsFootnote(
                  tr(
                    '未找到商品。请在 Play Console 创建 echo_plus_monthly、echo_plus_yearly（订阅）'
                    '与 echo_plus_lifetime（非消耗型应用内商品），并加入测试轨道。',
                    'No products found. Create echo_plus_monthly, echo_plus_yearly '
                        '(subscriptions) and echo_plus_lifetime (non-consumable in-app '
                        'product) in Play Console, then use a test track.',
                  ),
                ),
            ],
            const SizedBox(height: EchoSpacing.sm),
            Center(
              child: ScaleTap(
                onTap: _plus.purchaseInFlight ? null : _plus.restorePurchases,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EchoSpacing.md,
                    vertical: EchoSpacing.sm,
                  ),
                  child: Text(
                    tr('恢复购买', 'Restore purchases'),
                    style: EchoTypography.labelMedium.copyWith(
                      color: EchoColors.dayTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_plus.lastError != null) ...[
            const SizedBox(height: EchoSpacing.sm),
            EchoSettingsFootnote(_plus.lastError!),
          ],
          const SizedBox(height: EchoSpacing.lg),
          EchoSettingsFootnote(
            tr(
              '月付与年付将自动续费，直至你在 Google Play 中取消；买断为一次性付款。'
              '所有付款由 Google 处理。继续即表示同意服务条款。',
              'Monthly and yearly plans renew automatically until you cancel in '
                  'Google Play. Lifetime is a one-time charge. '
                  'Payments are processed by Google. Continued use means you accept the Terms of Service.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EchoSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_rounded, size: 18, color: _tint.withValues(alpha: 0.9)),
          const SizedBox(width: EchoSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: EchoTypography.bodyMedium.copyWith(
                color: EchoColors.dayTextSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlusPlan { monthly, yearly, lifetime }

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.product,
    required this.plan,
    required this.tint,
    required this.onTap,
    this.badge,
    this.selected = false,
    this.busy = false,
  });

  final ProductDetails product;
  final _PlusPlan plan;
  final Color tint;
  final VoidCallback onTap;
  final String? badge;
  final bool selected;
  final bool busy;

  String get _title => switch (plan) {
        _PlusPlan.monthly => tr('月付', 'Monthly'),
        _PlusPlan.yearly => tr('年付', 'Yearly'),
        _PlusPlan.lifetime => tr('永久买断', 'Lifetime'),
      };

  String? get _subtitle => switch (plan) {
        _PlusPlan.monthly => tr('约 \$1 / 月', 'About \$1 / month'),
        _PlusPlan.yearly => tr('约 \$9.9 / 年', 'About \$9.9 / year'),
        _PlusPlan.lifetime => tr('约 \$29.9，一次付清', 'About \$29.9, one-time'),
      };

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EchoSpacing.md),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.1) : EchoColors.daySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? tint.withValues(alpha: 0.45) : EchoColors.dayDivider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _title,
                        style: EchoTypography.titleMedium.copyWith(
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: EchoSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: EchoTypography.caption.copyWith(
                              color: tint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price,
                    style: EchoTypography.bodyLarge.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subtitle!,
                      style: EchoTypography.caption.copyWith(
                        color: EchoColors.dayTextWhisper,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right_rounded, color: tint.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

void openEchoPlusPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const EchoPlusPage()),
  );
}
