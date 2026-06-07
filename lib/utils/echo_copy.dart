import '../services/future_letter_service.dart';
import '../services/important_day_service.dart';

/// 首页与产品文案：同一天保持稳定，随时间段微调气质。
abstract final class EchoCopy {
  static const _indent = '　　';

  static const _nightPhrases = [
    '夜深了，把一点心事轻轻交给月光。',
    '长夜将尽，愿你在安静里与自己重逢。',
    '星子很淡，心事也很轻，慢慢说给自己听。',
    '夜色像绒毯，接住那些说不出口的疲惫。',
    '灯火远了，世界静下来，你也值得被温柔抱住。',
    '月白风清处，愿你不慌不忙，把心安放好。',
    '夜雨敲窗时，请记得你并不孤单。',
    '把白天的喧嚣放下，听一听心跳的回声。',
    '深夜的柔软，是给还醒着的人留的灯。',
    '愿你在黑夜里，仍看得见微光的方向。',
    '风停了，云慢了，你也终于可以歇一歇。',
    '夜很长，但黎明总会从东方缓缓走来。',
    '把遗憾折好，放进梦里，明天再轻轻打开。',
    '月色入户，照见那些未被言说的温柔。',
    '愿这一夜，你有好梦，也有好眠。',
  ];

  static const _dayPhrases = [
    '午后很长，风从记忆里轻轻掠过。',
    '阳光落在肩上，像一句迟到的安慰。',
    '把此刻的安宁，收进心底慢慢回味。',
    '云影游移，心事也学会与自己和解。',
    '人间烟火里，总有一缕甜值得停留。',
    '你经过的寻常日子，也在悄悄发光。',
    '风铃响了，提醒你去爱具体的生活。',
    '把欢喜缩小，把难过放轻，好好过今天。',
    '天光正好，适合把心事晒得蓬松柔软。',
    '愿你在平凡里，遇见不期而遇的温柔。',
    '花开无声，岁月却替你记得每一次心动。',
    '慢一点也没关系，生活正在向你靠拢。',
    '你认真生活的样子，已经很动人。',
    '把焦虑交给风，把安稳留给自己。',
    '这一日将逝，请温柔地对待自己。',
  ];

  static const _dawnPhrases = [
    '清晨的光落在窗台，温柔也缓缓亮起来。',
    '薄雾散去，新的一天带着露水般的心意。',
    '早安，愿你今日心有所依，行有所向。',
    '晨光微熹，把希望一点点铺在你脚下。',
    '鸟鸣初起，世界醒来，你也值得被祝福。',
    '朝露尚湿，愿你不急不躁，从容开场。',
    '天边的云很浅，你的心也可以很轻。',
    '第一缕风经过，带走昨夜残留的惆怅。',
    '新的一天，从对自己说一句谢谢开始。',
    '晨光入户，请相信今天会有好事发生。',
    '黎明之前最静，愿你听见内心的答案。',
    '把昨夜的梦折好，带着清爽走向清晨。',
    '日头将升，愿你所盼皆能如约而至。',
    '晨风拂面，像世界轻轻拍了拍你的肩。',
    '愿你在清晨，与更好的自己相遇。',
  ];

  static const _duskPhrases = [
    '暮色四合，把疲惫交给渐暗的天光。',
    '夕阳将尽，愿你不负这一日的奔波。',
    '晚风起了，吹散那些不必再提的烦忧。',
    '归途有灯，心里也有可以停靠的岸。',
    '黄昏很短，温柔却可以留得很长。',
    '天边最后一抹橙，是今天给你的回信。',
    '收工的时刻，请为自己点一盏小灯。',
    '暮色温柔，适合与自己和解片刻。',
    '夜尚未深，愿你已感到被生活善待。',
    '晚霞铺陈，替你把辛苦悄悄抚平。',
  ];

  /// 温柔句（句首空两格），须为完整短句，按时段与日期稳定轮换。
  static String dailyPhrase(DateTime now) {
    final important = ImportantDayService.instance.whisperForHome(now);
    if (important != null) return _indent + _oneSimpleSentence(important);

    final futureLetter = FutureLetterService.instance.whisperForHome(now);
    if (futureLetter != null) return _indent + _oneSimpleSentence(futureLetter);

    final daySeed = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        86400000;

    final List<String> pool;
    if (now.hour >= 18 || now.hour < 5) {
      pool = _nightPhrases;
    } else if (now.hour < 10) {
      pool = _dawnPhrases;
    } else if (now.hour >= 17) {
      pool = _duskPhrases;
    } else {
      pool = _dayPhrases;
    }

    return _indent + pool[daySeed % pool.length];
  }

  /// 保证展示为完整句子（取第一句，不截断加省略号）。
  static String _oneSimpleSentence(String raw) {
    final trimmed = raw.trim().replaceAll('\n', '');
    if (trimmed.isEmpty) return trimmed;
    for (final mark in ['。', '！', '？']) {
      final i = trimmed.indexOf(mark);
      if (i > 0) return trimmed.substring(0, i + 1);
    }
    return trimmed;
  }
}
