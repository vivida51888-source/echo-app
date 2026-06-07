import 'package:flutter/material.dart';

import '../data/daily_quotes.dart';
import '../l10n/echo_strings.dart';
import '../services/diary_draft_service.dart';
import '../services/diary_service.dart';
import '../services/echo_mood_book_service.dart';
import '../services/future_letter_service.dart';
import '../services/important_day_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../utils/drift_bottle_schedule.dart';
import '../utils/home_moment.dart';
import '../widgets/drift_bottle.dart';
import '../widgets/echo_controls.dart';
import '../widgets/echo_page_header.dart';
import '../widgets/echo_themed_scope.dart';
import '../widgets/scale_tap.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onWriteToday,
    this.onViewToday,
    this.onReviewPast,
  });

  final VoidCallback? onWriteToday;
  final VoidCallback? onViewToday;
  final VoidCallback? onReviewPast;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final s = EchoStrings.of();
        final now = DateTime.now();
        final primary = EchoColors.momentTextPrimary;
        final secondary = EchoColors.momentTextSecondary;
        final whisper = EchoColors.momentTextWhisper;
        final dual = EchoColors.usesDualTone;
        final showBottle = DriftBottleSchedule.isVisibleOn(now);

        return EchoPageBackground(
          homeTone: true,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EchoPageHeader(title: s.momentTitle),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      DiaryService.instance,
                      DiaryDraftService.instance,
                      ImportantDayService.instance,
                      FutureLetterService.instance,
                      EchoMoodBookService.instance,
                    ]),
                    builder: (context, _) {
                      final phrase = s.dailyPhrase(now);
                      final moment = HomeMoment.snapshot();
                      final quote = DailyQuotes.forDate(now);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EchoSpacing.pageHorizontalWide,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MomentLead(
                              date: now,
                              phrase: phrase,
                              primary: primary,
                              secondary: secondary,
                              english: s.isEn,
                            ),
                            const SizedBox(height: EchoSpacing.lg),
                            Expanded(
                              child: _MomentCenterStage(showBottle: showBottle),
                            ),
                            _MomentActions(
                              dualTone: dual,
                              action: moment.action,
                              quote: quote,
                              strings: s,
                              bookshelfTitle:
                                  EchoMoodBookService.instance.bookshelfTitle,
                              onWriteToday: onWriteToday ?? () {},
                              onViewToday: onViewToday ?? onWriteToday ?? () {},
                              onReviewPast: onReviewPast ?? () {},
                              whisper: whisper,
                            ),
                            const SizedBox(height: EchoSpacing.xxxl),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MomentLead extends StatelessWidget {
  const _MomentLead({
    required this.date,
    required this.phrase,
    required this.primary,
    required this.secondary,
    required this.english,
  });

  final DateTime date;
  final String phrase;
  final Color primary;
  final Color secondary;
  final bool english;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DiaryFormat.dateLine(date, english: english),
          style: EchoTypography.labelMedium.copyWith(
            color: secondary,
            letterSpacing: english ? 0.8 : 1.6,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: EchoSpacing.lg),
        Text(
          phrase,
          style: EchoTypography.titleLarge.copyWith(
            fontSize: 18,
            height: 1.5,
            color: primary,
            letterSpacing: 0.05,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class _MomentCenterStage extends StatelessWidget {
  const _MomentCenterStage({required this.showBottle});

  final bool showBottle;

  @override
  Widget build(BuildContext context) {
    if (!showBottle) {
      return const SizedBox.shrink();
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DriftBottleStage(),
      ],
    );
  }
}

class _DriftBottleStage extends StatefulWidget {
  const _DriftBottleStage();

  @override
  State<_DriftBottleStage> createState() => _DriftBottleStageState();
}

class _DriftBottleStageState extends State<_DriftBottleStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: const DriftBottleLane(),
    );
  }
}

class _MomentActions extends StatelessWidget {
  const _MomentActions({
    required this.dualTone,
    required this.action,
    required this.quote,
    required this.strings,
    required this.bookshelfTitle,
    required this.onWriteToday,
    required this.onViewToday,
    required this.onReviewPast,
    required this.whisper,
  });

  final bool dualTone;
  final HomeMomentAction action;
  final DailyQuote quote;
  final EchoStrings strings;
  final String bookshelfTitle;
  final VoidCallback onWriteToday;
  final VoidCallback onViewToday;
  final VoidCallback onReviewPast;
  final Color whisper;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (action == HomeMomentAction.showQuote)
          _DailyQuoteCard(
            quote: quote,
            onTap: onViewToday,
          )
        else
          Center(
            child: EchoPrimaryButton(
              label: action == HomeMomentAction.continueToday
                  ? strings.continueToday
                  : strings.writeToday,
              tone: dualTone
                  ? EchoPrimaryButtonTone.night
                  : EchoPrimaryButtonTone.day,
              onTap: onWriteToday,
            ),
          ),
        const SizedBox(height: EchoSpacing.lg),
        Center(
          child: ScaleTap(
            onTap: onReviewPast,
            scale: 0.98,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EchoSpacing.sm,
                vertical: EchoSpacing.xs,
              ),
              child: Text(
                strings.reviewPastWithBookshelf(bookshelfTitle),
                style: EchoTypography.caption.copyWith(
                  color: whisper,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard({
    required this.quote,
    required this.onTap,
  });

  final DailyQuote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quoteColor = EchoColors.momentTextPrimary;
    final authorColor = EchoColors.momentTextWhisper;

    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EchoSpacing.sm,
          vertical: EchoSpacing.md,
        ),
        child: Column(
          children: [
            Text(
              '「${quote.text}」',
              textAlign: TextAlign.center,
              style: EchoTypography.bodyLarge.copyWith(
                fontSize: 16,
                height: 1.65,
                fontWeight: FontWeight.w300,
                color: quoteColor,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: EchoSpacing.md),
            Text(
              '— ${quote.author}',
              textAlign: TextAlign.center,
              style: EchoTypography.caption.copyWith(
                fontSize: 12,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w300,
                color: authorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
