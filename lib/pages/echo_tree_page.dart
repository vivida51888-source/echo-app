import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/echo_tree_growth.dart';
import '../models/echo_water_bubble.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_tree_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../widgets/echo_tree_visual.dart';
import '../widgets/echo_water_bubbles.dart';
import '../widgets/echo_bubble_shatter.dart';
import '../widgets/scale_tap.dart';

class EchoTreePage extends StatelessWidget {
  const EchoTreePage({super.key});

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
                      padding: EdgeInsets.all(12),
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
            Expanded(
              child: EchoTreePanel(showHeader: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// 雨露树主体（全页与「回响」页内嵌共用）。
class EchoTreePanel extends StatefulWidget {
  const EchoTreePanel({
    super.key,
    this.scrollController,
    this.showHeader = false,
    this.inline = false,
    this.shrinkWrap = false,
  });

  final ScrollController? scrollController;
  final bool showHeader;
  final bool inline;
  final bool shrinkWrap;

  @override
  State<EchoTreePanel> createState() => _EchoTreePanelState();
}

class _EchoTreePanelState extends State<EchoTreePanel> {
  final _service = EchoTreeService.instance;
  bool _watering = false;
  List<EchoWaterBubble> _shatteringBubbles = [];

  static const _treeW = 160.0;
  static const _treeH = 200.0;
  static const _sceneExtraH = 88.0;

  int? _lastCollected;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _service.refreshBubbles();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeShatterQueue());
  }

  void _consumeShatterQueue() {
    if (!mounted || _shatteringBubbles.isNotEmpty) return;
    final queued = _service.takeShatterQueue();
    if (queued.isEmpty) return;
    setState(() => _shatteringBubbles = queued);
  }

  void _onShatterComplete() {
    if (!mounted) return;
    setState(() => _shatteringBubbles = []);
    _consumeShatterQueue();
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
      if (_shatteringBubbles.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _consumeShatterQueue());
      }
    }
  }

  Future<void> _collectBubble(String id) async {
    EchoWaterBubble? target;
    for (final b in _service.pendingBubbles) {
      if (b.id == id) {
        target = b;
        break;
      }
    }
    await _service.collectBubble(id);
    if (target != null && mounted) {
      setState(() => _lastCollected = target!.grams);
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _lastCollected = null);
      });
    }
  }

  Future<void> _collectAll() async {
    await _service.collectAllBubbles();
  }

  Future<void> _waterTree() async {
    if (_service.storedWater <= 0 || _watering) return;
    setState(() => _watering = true);
    await _service.waterTree();
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _watering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final treePanel = _TreePanel(
      service: _service,
      watering: _watering,
      lastCollected: _lastCollected,
      shatteringBubbles: _shatteringBubbles,
      onShatterComplete: _onShatterComplete,
      onCollectBubble: _collectBubble,
      onCollectAll: _collectAll,
      onWater: _waterTree,
    );

    if (widget.inline) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: treePanel,
      );
    }

    return ListView(
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: EdgeInsets.fromLTRB(28, widget.showHeader ? 0 : 16, 28, 40),
      children: [
        if (widget.showHeader) ...[
          Text(
            EchoStrings.current.hubTree,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          widget.showHeader
              ? tr(
                  '雨露会随机漂在树周围，点能量泡就能收集',
                  'Dew drifts around the tree — tap bubbles to collect',
                )
              : tr(
                  '写回响得雨露 · 点能量泡收集后浇水',
                  'Write echoes for dew · collect bubbles, then water',
                ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextWhisper,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(
            '日记 5g · 连续 3–7 天额外奖励 · 雨露保留 2 天',
            '5g per entry · 3–7 day streak bonus · dew lasts 2 days',
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: EchoColors.todoCompletedFill.withValues(alpha: 0.85),
          ),
        ),
        SizedBox(height: widget.showHeader ? 28 : 20),
        treePanel,
      ],
    );
  }
}

class _TreePanel extends StatelessWidget {
  const _TreePanel({
    required this.service,
    required this.watering,
    required this.lastCollected,
    required this.shatteringBubbles,
    required this.onShatterComplete,
    required this.onCollectBubble,
    required this.onCollectAll,
    required this.onWater,
  });

  final EchoTreeService service;
  final bool watering;
  final int? lastCollected;
  final List<EchoWaterBubble> shatteringBubbles;
  final VoidCallback onShatterComplete;
  final ValueChanged<String> onCollectBubble;
  final VoidCallback onCollectAll;
  final VoidCallback onWater;

  @override
  Widget build(BuildContext context) {
    final growth = service.growth;
    final sceneH = _EchoTreePanelState._treeH + _EchoTreePanelState._sceneExtraH;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: EchoColors.dayWriting.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.8),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final sceneSize = Size(constraints.maxWidth, sceneH);
              return SizedBox(
                height: sceneH,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: EchoTreeVisual(
                        visualStage: service.visualStage,
                        wilt: service.wiltLevel,
                        width: _EchoTreePanelState._treeW,
                        height: _EchoTreePanelState._treeH,
                      ),
                    ),
                    EchoWaterBubbleLayer(
                      bubbles: service.pendingBubbles,
                      onCollect: onCollectBubble,
                      sceneSize: sceneSize,
                    ),
                    if (shatteringBubbles.isNotEmpty)
                      EchoBubbleShatterLayer(
                        bubbles: shatteringBubbles,
                        sceneSize: sceneSize,
                        onComplete: onShatterComplete,
                      ),
                    if (watering)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Text(
                          tr('💧 浇水中…', '💧 Watering…'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: EchoColors.todoCompletedFill
                                .withValues(alpha: 0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (service.hasPendingBubbles)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Text(
                          tr('轻点能量泡收集雨露', 'Tap bubbles to collect dew'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: EchoColors.todoCompletedFill
                                .withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            growth.stageLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
          if (growth.companionLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              growth.companionLabel!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.todoCompletedFill.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (service.writingStreak >= 2) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: EchoColors.todoCompletedSurface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tr('已连续记下 ${service.writingStreak} 天', '${service.writingStreak}-day writing streak'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: EchoColors.todoCompletedFill,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            service.statusWhisper,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextPrimary,
              height: 1.65,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          _WaterStatsRow(service: service, lastCollected: lastCollected),
          const SizedBox(height: 16),
          _ActionRow(
            service: service,
            onCollectAll: onCollectAll,
            onWater: onWater,
            watering: watering,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                label: tr('记下', 'Days'),
                value: tr('${service.uniqueDiaryDays} 天', '${service.uniqueDiaryDays} days'),
              ),
              const SizedBox(width: 16),
              _StatChip(
                label: EchoStrings.current.echoTitle,
                value: tr('${service.totalEntries} 篇', '${service.totalEntries} entries'),
              ),
              const SizedBox(width: 16),
              _StatChip(label: tr('累计', 'Total'), value: '${growth.lifeWater}g'),
            ],
          ),
          if (service.nextStageHint != null) ...[
            const SizedBox(height: 16),
            Text(
              service.nextStageHint!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextWhisper,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _GrowthProgress(growth: growth),
        ],
      ),
    );
  }
}

class _WaterStatsRow extends StatelessWidget {
  const _WaterStatsRow({
    required this.service,
    this.lastCollected,
  });

  final EchoTreeService service;
  final int? lastCollected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _WaterStat(
            label: tr('待收露', 'Pending'),
            value: '${service.pendingWaterTotal}g',
            highlight: service.hasPendingBubbles,
          ),
        ),
        Container(
          width: 0.5,
          height: 32,
          color: EchoColors.dayDivider.withValues(alpha: 0.7),
        ),
        Expanded(
          child: _WaterStat(
            label: lastCollected != null
                ? tr('刚刚收集', 'Just collected')
                : tr('已收下', 'Collected'),
            value: lastCollected != null ? '+${lastCollected}g' : '${service.storedWater}g',
            highlight: service.storedWater > 0 || lastCollected != null,
          ),
        ),
      ],
    );
  }
}

class _WaterStat extends StatelessWidget {
  const _WaterStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: highlight
                ? EchoColors.todoCompletedFill
                : EchoColors.dayTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextWhisper,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.service,
    required this.onCollectAll,
    required this.onWater,
    required this.watering,
  });

  final EchoTreeService service;
  final VoidCallback onCollectAll;
  final VoidCallback onWater;
  final bool watering;

  @override
  Widget build(BuildContext context) {
    final canCollect = service.hasPendingBubbles;
    final canWater = service.storedWater > 0 && !watering;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: canCollect
                ? tr('收集雨露', 'Collect dew')
                : tr('暂无雨露', 'No dew yet'),
            icon: Icons.bubble_chart_outlined,
            enabled: canCollect,
            onTap: onCollectAll,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: canWater
                ? tr('浇水 ${service.storedWater}g', 'Water ${service.storedWater}g')
                : tr('先收集雨露', 'Collect dew first'),
            icon: Icons.water_drop_outlined,
            enabled: canWater,
            primary: true,
            onTap: onWater,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: enabled ? onTap : null,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled && primary
              ? EchoColors.todoCompletedFill.withValues(alpha: 0.22)
              : EchoColors.daySurface.withValues(alpha: enabled ? 1 : 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled && primary
                ? EchoColors.todoCompletedFill.withValues(alpha: 0.45)
                : EchoColors.dayDivider.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled
                  ? (primary
                      ? EchoColors.todoCompletedFill
                      : EchoColors.dayTextSecondary)
                  : EchoColors.dayTextWhisper,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: enabled
                      ? EchoColors.dayTextPrimary
                      : EchoColors.dayTextWhisper,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthProgress extends StatelessWidget {
  const _GrowthProgress({required this.growth});

  final EchoTreeGrowth growth;

  @override
  Widget build(BuildContext context) {
    final progress = growth.progress;
    final waterToNext = growth.waterToNext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: EchoColors.dayDivider.withValues(alpha: 0.6),
            valueColor: AlwaysStoppedAnimation(
              EchoColors.todoCompletedFill.withValues(alpha: 0.65),
            ),
          ),
        ),
        if (waterToNext != null) ...[
          const SizedBox(height: 8),
          Text(
            tr('生长 ${((progress * 100).round())}%', 'Growth ${((progress * 100).round())}%'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextWhisper,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: EchoColors.dayTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextWhisper,
          ),
        ),
      ],
    );
  }
}

void openEchoTreePage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const EchoTreePage()),
  );
}
