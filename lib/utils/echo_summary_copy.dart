import '../l10n/localized.dart';

/// Echo 单篇回响底句：按形态分档 + 关键词 + 稳定轮换。
abstract final class EchoSummaryCopy {
  static List<String> get imageOnly => trList(
        [
          '这一帧画面，Echo 也替你留住了。',
          '没写字也没关系，照片会说话。',
          '有些日子，一张图就够回忆了。',
        ],
        [
          'Echo kept this frame for you.',
          'No words needed — the photo speaks.',
          'Some days, one image is enough.',
        ],
      );

  static List<String> get blank => trList(
        [
          '空白也是一种记录，以后或许会想起这一刻。',
          '什么都没写，但你来过这里。',
        ],
        [
          'Blank space is still a record — you may remember later.',
          'Nothing written, but you were here.',
        ],
      );

  static List<String> get ultraShort => trList(
        [
          '短短几句，也像在对自己轻轻说话。',
          '字不多，心意到了就好。',
          '轻飘飘的几句，也值得被留下。',
          '不必写长，真实就够了。',
          '你肯开口，就已经很好了。',
        ],
        [
          'A few words, like talking gently to yourself.',
          'Short and sincere is enough.',
          'Light lines are still worth keeping.',
          'No need for length — honesty is enough.',
          'Speaking up at all is already good.',
        ],
      );

  static List<String> get short => trList(
        [
          '一小段话，装下了一整天的心情。',
          '不多不少，刚好说出此刻。',
          '这些字很轻，但会留得很久。',
          '像对自己悄悄交代了一句。',
        ],
        [
          'A small paragraph holds a whole day.',
          'Just enough to say this moment.',
          'Light words that will stay a long time.',
          'Like a quiet note to yourself.',
        ],
      );

  static List<String> get medium => trList(
        [
          '这一刻被记下来了，以后会慢慢显出意义。',
          '你把自己的一天，安放得很仔细。',
          '文字里藏着细小的温柔，Echo 替你留住了。',
          '有些感受，写下来就轻了一点。',
          '普通的一天，也值得被好好安放。',
        ],
        [
          'This moment is saved — meaning will grow later.',
          'You placed your day with care.',
          'Small tenderness in the words — Echo kept it.',
          'Some feelings lighten when written down.',
          'An ordinary day still deserves a gentle place.',
        ],
      );

  static List<String> get long => trList(
        [
          '你写了很多，Echo 会好好替你收着。',
          '长长的回响，是留给未来自己的信。',
          '愿意说这么多，说明你在认真生活。',
          '这一篇，以后翻回来会很有分量。',
        ],
        [
          'You wrote a lot — Echo will keep it safe.',
          'A long echo is a letter to your future self.',
          'Saying this much means you are living attentively.',
          'This entry will carry weight when you return.',
        ],
      );

  static Map<String, List<String>> get keywordPools => isEnUi
      ? _keywordPoolsEn
      : _keywordPoolsZh;

  static const _keywordPoolsZh = <String, List<String>>{
    '疲惫': [
      '今天的你似乎有些疲惫，但也仍在认真地生活。',
      '累的时候还记得记录，已经很了不起。',
    ],
    '温柔': [
      '文字里藏着细小的温柔，Echo 替你留住了。',
      '这一篇，是留给自己的一份温柔。',
    ],
    '孤独': [
      '有些时刻一个人静静待着，也是一种回响。',
      '一个人待着的时候，世界也没有把你忘记。',
    ],
    '开心': [
      '今天有轻盈的时刻，值得被记下来。',
      '快乐不必很大声，悄悄记下也很好。',
    ],
    '下雨': [
      '雨声里的情绪，也被你温柔地接住了。',
      '雨天写下的字，往往格外安静。',
    ],
    '熬夜': [
      '夜深了还在想事情，记得对自己好一点。',
      '深夜的文字，Echo 会轻轻替你收好。',
    ],
    '朋友': [
      '与人的联结，总是生命里很亮的一页。',
      '有人可念、可写，是幸事。',
    ],
    '家人': [
      '关于家的牵挂，往往最安静，也最深。',
      '那些关于家的话，最值得被留下。',
    ],
    '工作': [
      '忙碌的一天里，你仍为自己留了一点空白。',
      '忙里偷闲写下的几句，也很珍贵。',
    ],
    '运动': [
      '动起来的日子，身体记得，文字也记得。',
      '流汗或散步之后，心里往往更清亮一点。',
    ],
    '学习': [
      '学一点、记一点，日子就有了新的纹理。',
      '把思考写下来，比只放在脑子里更踏实。',
    ],
  };

  static const _keywordPoolsEn = <String, List<String>>{
    'tired': [
      'You seem tired today, yet still living with care.',
      'Recording when exhausted is already remarkable.',
    ],
    'gentle': [
      'Small tenderness in the words — Echo kept it.',
      'This entry is a gentle gift to yourself.',
    ],
    'lonely': [
      'Quiet solitude is its own kind of echo.',
      'Alone or not, the world has not forgotten you.',
    ],
    'happy': [
      'A light moment today — worth noting.',
      'Joy need not be loud; a quiet note is fine.',
    ],
    'rain': [
      'Rainy feelings, gently held in your words.',
      'Words written in rain are often especially still.',
    ],
    'late night': [
      'Still thinking late — be kind to yourself.',
      'Late-night words, Echo will keep them softly.',
    ],
    'friends': [
      'Connection with others is a bright page in life.',
      'Someone to think of and write about is a gift.',
    ],
    'family': [
      'Thoughts of home are quiet and deep.',
      'Words about family are worth keeping.',
    ],
    'work': [
      'A busy day, yet you left a little space for yourself.',
      'Lines stolen between tasks are precious.',
    ],
    'exercise': [
      'Days you move — body remembers, words remember.',
      'After a walk or workout, the mind often clears.',
    ],
    'study': [
      'Learning and noting gives days new texture.',
      'Writing thoughts down feels steadier than holding them.',
    ],
  };

  static final Map<String, String> _zhToEnKeyword = {
    '疲惫': 'tired',
    '温柔': 'gentle',
    '孤独': 'lonely',
    '开心': 'happy',
    '下雨': 'rain',
    '熬夜': 'late night',
    '朋友': 'friends',
    '家人': 'family',
    '工作': 'work',
    '运动': 'exercise',
    '学习': 'study',
  };

  static List<String> generalForTier(int tier) {
    switch (tier) {
      case 3:
        return short;
      case 4:
        return medium;
      case 5:
        return long;
      default:
        return medium;
    }
  }

  static List<String>? keywordPool(String key) {
    if (isEnUi) {
      final enKey = _zhToEnKeyword[key] ?? key;
      return _keywordPoolsEn[enKey];
    }
    return _keywordPoolsZh[key];
  }

  static String pick(List<String> pool, String seed) {
    if (pool.isEmpty) return '';
    if (pool.length == 1) return pool.first;
    return pool[_stableIndex(seed, pool.length)];
  }

  static int _stableIndex(String seed, int length) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash % length;
  }
}
