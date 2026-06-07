import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../models/chinese_zodiac.dart';
import '../models/echo_mood_book.dart';
import '../models/weather_mood.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import 'scale_tap.dart';

/// 虚拟书架：12 本心情之书，按年份生肖主题渲染。
class MoodBookshelf extends StatelessWidget {
  const MoodBookshelf({
    super.key,
    required this.year,
    required this.books,
    required this.onBookTap,
  });

  final int year;
  final List<EchoMoodBook> books;
  final ValueChanged<EchoMoodBook> onBookTap;

  @override
  Widget build(BuildContext context) {
    assert(books.length == 12);
    final theme = ChineseZodiac.forYear(year).theme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.alcoveTop.withValues(alpha: 0.96),
            theme.alcoveMid.withValues(alpha: 0.92),
            theme.alcoveBottom.withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.28),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.plankBottom.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 10,
            child: Opacity(
              opacity: 0.12,
              child: Text(
                theme.zodiac.emoji,
                style: TextStyle(fontSize: 72, height: 1),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.accent.withValues(alpha: 0.28),
                  width: 0.5,
                ),
              ),
              child: Text(
                '${theme.zodiac.branchLabel}年架',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: theme.plankBottom.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 38, 14, 16),
            child: Column(
              children: [
                _ShelfRow(books: books.sublist(0, 6), onBookTap: onBookTap),
                _ShelfPlank(theme: theme),
                const SizedBox(height: 14),
                _ShelfRow(books: books.sublist(6, 12), onBookTap: onBookTap),
                _ShelfPlank(theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.books, required this.onBookTap});

  final List<EchoMoodBook> books;
  final ValueChanged<EchoMoodBook> onBookTap;

  static const _rowHeight = 168.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < books.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: MoodBookSpine(
                book: books[i],
                onTap: () => onBookTap(books[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShelfPlank extends StatelessWidget {
  const _ShelfPlank({required this.theme});

  final ZodiacShelfTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 3,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                theme.accent.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
        Container(
          height: 11,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.plankTop, theme.plankMid, theme.plankBottom],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.plankBottom.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              theme.ornament,
              style: TextStyle(
                fontSize: 7,
                color: Colors.white.withValues(alpha: 0.35),
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MoodBookSpine extends StatelessWidget {
  const MoodBookSpine({
    super.key,
    required this.book,
    required this.onTap,
  });

  final EchoMoodBook book;
  final VoidCallback onTap;

  static const _spineHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final month = DiaryFormat.monthTitleShort(book.month);
    final hasEntries = book.hasEntries;
    final hasCustomTitle =
        book.customTitle != null && book.customTitle!.isNotEmpty;

    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: SizedBox(
        height: 168,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: _spineHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
                right: Radius.circular(6),
              ),
              gradient: LinearGradient(
                colors: hasEntries
                    ? [book.spineHighlight, book.spineColor, book.spineShadow]
                    : [
                        EchoColors.daySurface,
                        WeatherMood.emptySpineColor,
                        EchoColors.dayDivider,
                      ],
                stops: const [0.0, 0.42, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasEntries ? book.spineShadow : EchoColors.dayDivider)
                      .withValues(alpha: hasEntries ? 0.38 : 0.2),
                  blurRadius: hasEntries ? 8 : 4,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (hasEntries)
                  Positioned(
                    right: 0,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: EchoColors.daySurface.withValues(alpha: 0.88),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                if (hasCustomTitle)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EchoColors.dayTextPrimary.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                Positioned(
                  left: 4,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: hasEntries ? 0.5 : 0.2),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 7, 10),
                  child: Column(
                    children: [
                      Text(
                        hasEntries ? book.dominantEmoji : '—',
                        style: TextStyle(
                          fontSize: hasEntries ? 15 : 11,
                          height: 1,
                          color: hasEntries
                              ? EchoColors.dayTextPrimary.withValues(alpha: 0.9)
                              : EchoColors.dayTextWhisper,
                        ),
                      ),
                      const Spacer(),
                      _VerticalSpineLabel(
                        text: month,
                        active: hasEntries,
                      ),
                      if (hasEntries) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${book.stats.diaryDayCount}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: EchoColors.dayTextPrimary.withValues(alpha: 0.6),
                            height: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 书脊竖排月份（自上而下逐字排列）。
class _VerticalSpineLabel extends StatelessWidget {
  const _VerticalSpineLabel({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? EchoColors.dayTextPrimary.withValues(alpha: 0.88)
        : EchoColors.dayTextWhisper;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: text.characters.map((char) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            char,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}
