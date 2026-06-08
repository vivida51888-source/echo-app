import 'package:flutter/material.dart';

import '../l10n/localized.dart';

/// 农历生肖年与书架主题（按公历年份对应生肖年）。
enum ChineseZodiac {
  rat('鼠', '🐭', '子鼠'),
  ox('牛', '🐮', '丑牛'),
  tiger('虎', '🐯', '寅虎'),
  rabbit('兔', '🐰', '卯兔'),
  dragon('龙', '🐲', '辰龙'),
  snake('蛇', '🐍', '巳蛇'),
  horse('马', '🐴', '午马'),
  goat('羊', '🐑', '未羊'),
  monkey('猴', '🐵', '申猴'),
  rooster('鸡', '🐔', '酉鸡'),
  dog('狗', '🐶', '戌狗'),
  pig('猪', '🐷', '亥猪');

  const ChineseZodiac(this.label, this.emoji, this.branchLabel);

  final String label;
  final String emoji;
  final String branchLabel;

  static ChineseZodiac forYear(int year) {
    const order = ChineseZodiac.values;
    final index = (year - 4) % 12;
    return order[index < 0 ? index + 12 : index];
  }

  ZodiacShelfTheme get theme => ZodiacShelfTheme.forZodiac(this);

  String get localizedLabel => switch (this) {
        ChineseZodiac.rat => tr('鼠', 'Rat'),
        ChineseZodiac.ox => tr('牛', 'Ox'),
        ChineseZodiac.tiger => tr('虎', 'Tiger'),
        ChineseZodiac.rabbit => tr('兔', 'Rabbit'),
        ChineseZodiac.dragon => tr('龙', 'Dragon'),
        ChineseZodiac.snake => tr('蛇', 'Snake'),
        ChineseZodiac.horse => tr('马', 'Horse'),
        ChineseZodiac.goat => tr('羊', 'Goat'),
        ChineseZodiac.monkey => tr('猴', 'Monkey'),
        ChineseZodiac.rooster => tr('鸡', 'Rooster'),
        ChineseZodiac.dog => tr('狗', 'Dog'),
        ChineseZodiac.pig => tr('猪', 'Pig'),
      };
}

class ZodiacShelfTheme {
  const ZodiacShelfTheme({
    required this.zodiac,
    required this.alcoveTop,
    required this.alcoveMid,
    required this.alcoveBottom,
    required this.plankTop,
    required this.plankMid,
    required this.plankBottom,
    required this.accent,
    required this.ornament,
    required this.tagline,
  });

  final ChineseZodiac zodiac;
  final Color alcoveTop;
  final Color alcoveMid;
  final Color alcoveBottom;
  final Color plankTop;
  final Color plankMid;
  final Color plankBottom;
  final Color accent;
  final String ornament;
  final String tagline;

  String get localizedTagline => switch (zodiac) {
        ChineseZodiac.rat =>
          tr('灵鼠守卷，细录心事', 'Rat keeps the scroll, noting every thought'),
        ChineseZodiac.ox =>
          tr('勤牛架书，稳步沉淀', 'Ox shelves books, steady and sure'),
        ChineseZodiac.tiger =>
          tr('山风入架，虎纹映卷', 'Mountain wind on the shelf, tiger stripes on the scroll'),
        ChineseZodiac.rabbit =>
          tr('月兔伴读，温柔留痕', 'Moon rabbit reads beside you, gentle traces left'),
        ChineseZodiac.dragon =>
          tr('云龙绕架，气象万千', 'Cloud dragon winds the shelf, skies ever changing'),
        ChineseZodiac.snake =>
          tr('灵蛇盘架，静观心澜', 'Snake coils the shelf, watching quiet tides'),
        ChineseZodiac.horse =>
          tr('骏马踏架，奔向回响', 'Horse steps the shelf, galloping toward echoes'),
        ChineseZodiac.goat =>
          tr('软羊偎书，暖意绵延', 'Soft goat nestles books, warmth that lingers'),
        ChineseZodiac.monkey =>
          tr('灵猴翻卷，妙趣横生', 'Monkey turns the scroll, wit in every page'),
        ChineseZodiac.rooster =>
          tr('金鸡报晓，日日记下', 'Rooster greets dawn, noting each day'),
        ChineseZodiac.dog =>
          tr('忠犬守架，陪伴左右', 'Loyal dog guards the shelf, always nearby'),
        ChineseZodiac.pig =>
          tr('福猪满架，丰盈岁月', 'Blessed pig fills the shelf, abundant years'),
      };

  static ZodiacShelfTheme forZodiac(ChineseZodiac zodiac) {
    switch (zodiac) {
      case ChineseZodiac.rat:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFE8EDF2),
          alcoveMid: const Color(0xFFD5DCE4),
          alcoveBottom: const Color(0xFFC4CDD8),
          plankTop: const Color(0xFF8E9AA8),
          plankMid: const Color(0xFF6E7A88),
          plankBottom: const Color(0xFF556070),
          accent: const Color(0xFF7A8FA3),
          ornament: '◌',
          tagline: '灵鼠守卷，细录心事',
        );
      case ChineseZodiac.ox:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFEDE4D8),
          alcoveMid: const Color(0xFFDFD2C2),
          alcoveBottom: const Color(0xFFD0C0AD),
          plankTop: const Color(0xFFA08972),
          plankMid: const Color(0xFF806952),
          plankBottom: const Color(0xFF655340),
          accent: const Color(0xFF9A7B5A),
          ornament: '⬡',
          tagline: '勤牛架书，稳步沉淀',
        );
      case ChineseZodiac.tiger:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF6E8DC),
          alcoveMid: const Color(0xFFEBD4C0),
          alcoveBottom: const Color(0xFFDFC2A8),
          plankTop: const Color(0xFFC98E62),
          plankMid: const Color(0xFFA86E42),
          plankBottom: const Color(0xFF86552E),
          accent: const Color(0xFFD4844A),
          ornament: '王',
          tagline: '山风入架，虎纹映卷',
        );
      case ChineseZodiac.rabbit:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF3ECE8),
          alcoveMid: const Color(0xFFE6DBD4),
          alcoveBottom: const Color(0xFFD8CCC4),
          plankTop: const Color(0xFFBFA89C),
          plankMid: const Color(0xFF9F877A),
          plankBottom: const Color(0xFF806A5E),
          accent: const Color(0xFFE8B4C8),
          ornament: '⌒',
          tagline: '月兔伴读，温柔留痕',
        );
      case ChineseZodiac.dragon:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF3EBDD),
          alcoveMid: const Color(0xFFE6D8C0),
          alcoveBottom: const Color(0xFFD8C4A4),
          plankTop: const Color(0xFFC4A56A),
          plankMid: const Color(0xFF9E7E42),
          plankBottom: const Color(0xFF7A6030),
          accent: const Color(0xFFD4AF37),
          ornament: '龍',
          tagline: '云龙绕架，气象万千',
        );
      case ChineseZodiac.snake:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFE6EEE8),
          alcoveMid: const Color(0xFFD4E2D8),
          alcoveBottom: const Color(0xFFC2D4C6),
          plankTop: const Color(0xFF8FA892),
          plankMid: const Color(0xFF6E8870),
          plankBottom: const Color(0xFF546A56),
          accent: const Color(0xFF6FAF82),
          ornament: '～',
          tagline: '灵蛇盘架，静观心澜',
        );
      case ChineseZodiac.horse:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF2E8DC),
          alcoveMid: const Color(0xFFE4D4C2),
          alcoveBottom: const Color(0xFFD6C2AA),
          plankTop: const Color(0xFFB8956E),
          plankMid: const Color(0xFF96744E),
          plankBottom: const Color(0xFF755A38),
          accent: const Color(0xFFC97A5A),
          ornament: '马',
          tagline: '骏马踏架，奔向回响',
        );
      case ChineseZodiac.goat:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF4F0EA),
          alcoveMid: const Color(0xFFE8E0D6),
          alcoveBottom: const Color(0xFFDAD0C4),
          plankTop: const Color(0xFFBBA896),
          plankMid: const Color(0xFF998674),
          plankBottom: const Color(0xFF786858),
          accent: const Color(0xFFD4C4B0),
          ornament: '绒',
          tagline: '软羊偎书，暖意绵延',
        );
      case ChineseZodiac.monkey:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFEDE6DA),
          alcoveMid: const Color(0xFFDFD4C4),
          alcoveBottom: const Color(0xFFD0C2AE),
          plankTop: const Color(0xFFAE9678),
          plankMid: const Color(0xFF8E7658),
          plankBottom: const Color(0xFF6E5A40),
          accent: const Color(0xFFD4A84B),
          ornament: '猴',
          tagline: '灵猴翻卷，妙趣横生',
        );
      case ChineseZodiac.rooster:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF6EBE0),
          alcoveMid: const Color(0xFFEAD8C8),
          alcoveBottom: const Color(0xFFDCC6B0),
          plankTop: const Color(0xFFC49A6E),
          plankMid: const Color(0xFFA07848),
          plankBottom: const Color(0xFF805E30),
          accent: const Color(0xFFE8A040),
          ornament: '羽',
          tagline: '金鸡报晓，日日记下',
        );
      case ChineseZodiac.dog:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFEDE8E0),
          alcoveMid: const Color(0xFFDFD8CC),
          alcoveBottom: const Color(0xFFD0C8BA),
          plankTop: const Color(0xFFA89478),
          plankMid: const Color(0xFF88745A),
          plankBottom: const Color(0xFF685840),
          accent: const Color(0xFF9A8570),
          ornament: '忠',
          tagline: '忠犬守架，陪伴左右',
        );
      case ChineseZodiac.pig:
        return ZodiacShelfTheme(
          zodiac: zodiac,
          alcoveTop: const Color(0xFFF4E8EA),
          alcoveMid: const Color(0xFFE8D8DC),
          alcoveBottom: const Color(0xFFDCC8CE),
          plankTop: const Color(0xFFBC98A0),
          plankMid: const Color(0xFF9A7880),
          plankBottom: const Color(0xFF785860),
          accent: const Color(0xFFE8A0A0),
          ornament: '福',
          tagline: '福猪满架，丰盈岁月',
        );
    }
  }
}
