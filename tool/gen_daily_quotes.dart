// Run: dart tool/gen_daily_quotes.dart
import 'dart:io';

import 'quote_pools_classic.dart';
import 'quote_pools_modern.dart';

void main() {
  final seen = <String>{};
  final unique = <(String, String)>[];

  // 现代文学优先，经典补足至 365。
  for (final item in [...modernQuotePool, ...classicQuotePool]) {
    final key = '${item.$1}|${item.$2}';
    if (seen.contains(key)) continue;
    seen.add(key);
    unique.add(item);
  }

  if (unique.length < 365) {
    stderr.writeln('Warning: only ${unique.length} unique quotes');
  }

  final quotes = unique.take(365).toList();

  final buffer = StringBuffer('''
// 365 条名句：约八成来自近代·现代小说与散文，其余为诗词经典。
// 按一年中的第几天轮换。重新生成：dart tool/gen_daily_quotes.dart

class DailyQuote {
  const DailyQuote({required this.text, required this.author});

  final String text;
  final String author;
}

abstract final class DailyQuotes {
  DailyQuotes._();

  static const List<DailyQuote> all = [
''');

  for (final q in quotes) {
    final text = q.$1.replaceAll('\\', r'\\').replaceAll("'", r"\'");
    final author = q.$2.replaceAll('\\', r'\\').replaceAll("'", r"\'");
    buffer.writeln("    DailyQuote(text: '$text', author: '$author'),");
  }

  buffer.writeln('''
  ];

  static int dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays;
  }

  static DailyQuote forDate(DateTime date) {
    return all[dayOfYear(date) % all.length];
  }
}
''');

  File('lib/data/daily_quotes.dart').writeAsStringSync(buffer.toString());
  stdout.writeln('Wrote ${quotes.length} quotes (${_countModern(quotes)} modern-tagged)');
}

int _countModern(List<(String, String)> quotes) {
  var n = 0;
  for (final q in quotes) {
    final a = q.$2;
    if (a.contains('《') ||
        a.contains('鲁迅') ||
        a.contains('张爱玲') ||
        a.contains('村上') ||
        a.contains('余华') ||
        a.contains('雨果') ||
        a.contains('海明威') ||
        a.contains('JK') ||
        a.contains('Rowling') ||
        a.contains('宫崎骏') ||
        a.contains('刘慈欣') ||
        a.contains('王小波') ||
        a.contains('三毛') ||
        a.contains('海子') ||
        a.contains('顾城') ||
        a.contains('北岛') ||
        a.contains('路遥') ||
        a.contains('沈从文') ||
        a.contains('汪曾祺') ||
        a.contains('钱钟书') ||
        a.contains('马尔克斯') ||
        a.contains('太宰治') ||
        a.contains('圣埃克苏佩里') ||
        a.contains('胡赛尼') ||
        a.contains('菲茨杰拉德') ||
        a.contains('托尔斯泰') ||
        a.contains('陀思妥耶夫斯基') ||
        a.contains('川端康成') ||
        a.contains('顾漫') ||
        a.contains('木心') ||
        a.contains('史铁生') ||
        a.contains('老舍') ||
        a.contains('金庸') ||
        a.contains('柴静') ||
        a.contains('杨绛') ||
        a.contains('林徽因') ||
        a.contains('徐志摩') ||
        a.contains('泰戈尔') ||
        a.contains('王尔德') ||
        a.contains('黑塞') ||
        a.contains('博尔赫斯') ||
        a.contains('昆德拉') ||
        a.contains('加缪') ||
        a.contains('罗曼·罗兰') ||
        a.contains('莎士比亚') ||
        a.contains('乔布斯') ||
        a.contains('网络')) {
      n++;
    }
  }
  return n;
}
