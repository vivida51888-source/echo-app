import 'package:flutter/material.dart';

import '../models/mood_journey.dart';
import '../models/weather_mood.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import 'echo_charm.dart';
import 'echo_empty_state.dart';
import '../utils/diary_format.dart';
import 'mood_journey/finish_confetti.dart';
import 'mood_journey/road_scenery.dart';
import 'scale_tap.dart';

/// 心情地图：横向公路卷轴，骑车经过沿途天气变化。
class EchoMoodJourneyMap extends StatelessWidget {
  const EchoMoodJourneyMap({
    super.key,
    required this.days,
    required this.isWeekly,
    required this.onDayTap,
    this.embedded = false,
  });

  final List<EchoDayStat> days;
  final bool isWeekly;
  final ValueChanged<EchoDayStat> onDayTap;
  /// 嵌入区块卡片时不再套额外圆角壳，避免 Hub / 统计页双层矩形。
  final bool embedded;

  Widget _emptyState(String message) {
    final state = EchoEmptyState(
      charm: EchoCharmKind.cloud,
      message: message,
      compact: true,
    );
    if (embedded) return state;
    return _EmptyJourneyCard(message: message);
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return _emptyState('还没有标记心情\n写作时选一种天气，这里会慢慢亮起来');
    }
    if (!days.any((d) => d.hasDiary)) {
      return _emptyState('这一段还没有标记心情\n写回响时选一种天气，沿途风景会慢慢亮起来');
    }

    final segments = isWeekly
        ? MoodJourneyLayout.dailySegments(days)
        : MoodJourneyLayout.monthSegments(days);

    final ride = MoodJourneyRoadRide(
      segments: segments,
      finishDays: days,
      isMonthView: !isWeekly,
      onDayTap: onDayTap,
    );

    if (embedded) return ride;

    return _JourneyShell(
      caption: isWeekly
          ? '从启程之门出发，滑动卷轴看天气如何流转'
          : '一月一路，每段是一周的主调天气',
      child: ride,
    );
  }
}

class _EmptyJourneyCard extends StatelessWidget {
  const _EmptyJourneyCard({this.message = '还没有标记心情\n写作时选一种天气，这里会慢慢亮起来'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
      ),
      child: EchoEmptyState(
        charm: EchoCharmKind.cloud,
        message: message,
        compact: true,
      ),
    );
  }
}

class _JourneyShell extends StatelessWidget {
  const _JourneyShell({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              caption,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 公路卷轴 + 固定视角骑车。
class MoodJourneyRoadRide extends StatefulWidget {
  const MoodJourneyRoadRide({
    super.key,
    required this.segments,
    required this.finishDays,
    required this.isMonthView,
    required this.onDayTap,
  });

  final List<MoodJourneySegmentView> segments;
  final List<EchoDayStat> finishDays;
  final bool isMonthView;
  final ValueChanged<EchoDayStat> onDayTap;

  @override
  State<MoodJourneyRoadRide> createState() => _MoodJourneyRoadRideState();
}

class _MoodJourneyRoadRideState extends State<MoodJourneyRoadRide>
    with TickerProviderStateMixin {
  static const _statusBarHeight = 54.0;

  final _scroll = ScrollController();
  late final AnimationController _pedal;
  late final AnimationController _confetti;
  AnimationController? _rideAnim;
  double _viewportW = 0;
  bool _riding = false;
  bool _wasAtFinish = false;
  bool _showConfetti = false;

  List<EchoDayStat> get _stats => widget.segments.map((s) => s.stat).toList();

  double get _scrollOffset =>
      _scroll.hasClients ? _scroll.offset : 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _pedal = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _rideAnim?.dispose();
    _confetti.dispose();
    _scroll.dispose();
    _pedal.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _riding) return;
    setState(() {});
    _updateFinishState(_viewportW);
  }

  void _updateFinishState(double viewportW) {
    if (viewportW <= 0) return;
    final atFinish = _atFinish(viewportW);
    if (atFinish && !_wasAtFinish) {
      _fireConfetti();
    }
    if (!atFinish) {
      _wasAtFinish = false;
    } else {
      _wasAtFinish = true;
    }
  }

  void _fireConfetti() {
    setState(() => _showConfetti = true);
    _confetti.stop();
    _confetti.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  int _indexAtViewport(double viewportW) {
    final idx = MoodJourneyLayout.segmentIndexAtScroll(_scrollOffset, viewportW);
    return idx.clamp(0, widget.segments.length - 1);
  }

  bool _atFinish(double viewportW) {
    if (!_scroll.hasClients) return false;
    final doorTarget =
        MoodJourneyLayout.scrollToFinishDoor(widget.segments.length, viewportW);
    return (_scrollOffset - doorTarget).abs() < 14;
  }

  Future<void> _rideThrough(double viewportW) async {
    if (_riding || !_scroll.hasClients) return;
    setState(() => _riding = true);
    _rideAnim?.dispose();

    final end = MoodJourneyLayout.scrollToFinishDoor(widget.segments.length, viewportW);
    final distance = (end - _scroll.offset).abs();
    final ms = (distance / MoodJourneyLayout.rideSpeedPxPerSec * 1000)
        .round()
        .clamp(600, 14000);

    _rideAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    final tween = Tween<double>(begin: _scroll.offset, end: end).animate(
      CurvedAnimation(parent: _rideAnim!, curve: Curves.linear),
    );
    tween.addListener(() {
      if (_scroll.hasClients) _scroll.jumpTo(tween.value);
    });
    await _rideAnim!.forward();

    if (!mounted) return;
    setState(() => _riding = false);
    _wasAtFinish = false;
    _fireConfetti();
  }

  String _statusTitle(MoodJourneySegmentView segment, WeatherMood? mood) {
    if (widget.isMonthView) {
      final week = segment.cornerLabel;
      final range = segment.weekRange;
      if (mood != null) {
        return range != null
            ? '$week · $range · ${mood.emoji} ${mood.label}'
            : '$week · ${mood.emoji} ${mood.label}';
      }
      return range != null ? '$week · $range · 本周尚无回响' : '$week · 本周尚无回响';
    }
    return '${DiaryFormat.listDateLabel(segment.stat.date)}'
        '${mood != null ? ' · ${mood.emoji} ${mood.label}' : ' · 尚未写下'}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vw = constraints.maxWidth;
        _viewportW = vw;
        final labelFlags = MoodJourneyLayout.moodLabelFlags(_stats);
        final idx = _indexAtViewport(vw);
        final atFinish = _atFinish(vw);
        final current = widget.segments[idx];
        final kind = atFinish
            ? MoodSceneryKind.rainbow
            : MoodJourneyLayout.sceneryFor(current.stat);
        final mood = current.stat.hasDiary
            ? WeatherMood.resolve(current.stat.moodWeather)
            : null;

        final title = atFinish
            ? (widget.isMonthView ? '抵达回响驿站 · 这一月已存档' : '抵达回响驿站 · 这一段已存档')
            : _statusTitle(current, mood);
        final subtitle = atFinish
            ? (widget.isMonthView ? '本月的心情，都收在这里了' : '本周的心情，都收在这里了')
            : moodSceneryCaption(kind);

        final cyclistLeft = vw * MoodJourneyLayout.cyclistViewportRatio - 28;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: MoodJourneyLayout.sceneHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(bottom: Radius.circular(14)),
                        child: SingleChildScrollView(
                          controller: _scroll,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              JourneyStartSegment(
                                time: _pedal.value,
                                isMonthView: widget.isMonthView,
                              ),
                              for (var i = 0; i < widget.segments.length; i++)
                                MoodRoadSegment(
                                  segmentIndex: i,
                                  day: widget.segments[i].stat,
                                  time: _pedal.value,
                                  showMoodLabel: labelFlags[i],
                                  cornerLabel: widget.segments[i].cornerLabel,
                                  onTap: widget.segments[i].stat.hasDiary
                                      ? () => widget.onDayTap(
                                            widget.segments[i].stat,
                                          )
                                      : null,
                                ),
                              JourneyFinishSegment(
                                days: widget.finishDays,
                                time: _pedal.value,
                                isMonthView: widget.isMonthView,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: cyclistLeft,
                        bottom: MoodJourneyLayout.sceneHeight * 0.14,
                        child: IgnorePointer(
                          child: CustomPaint(
                            size: const Size(56, 52),
                            painter: JourneyCyclistPainter(
                              phase: _pedal.value,
                              riding: _riding || _scrollOffset > 2,
                            ),
                          ),
                        ),
                      ),
                      if (_showConfetti)
                        Positioned(
                          left: cyclistLeft + 14,
                          bottom: MoodJourneyLayout.sceneHeight * 0.14,
                          child: IgnorePointer(
                            child: FinishConfettiPopper(
                              progress: _confetti.value,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _statusBarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: EchoColors.dayTextPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  color: EchoColors.dayTextSecondary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 68,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ScaleTap(
                              onTap: _riding ? null : () => _rideThrough(vw),
                              scale: 0.96,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: EchoColors.dayWriting,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: EchoColors.dayDivider,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  _riding ? '骑行中…' : '出发',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: EchoColors.dayTextPrimary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
