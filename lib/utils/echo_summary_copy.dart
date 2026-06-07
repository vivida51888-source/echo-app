/// Echo 单篇回响底句：按形态分档 + 关键词 + 稳定轮换。
abstract final class EchoSummaryCopy {
  static const imageOnly = [
    '这一帧画面，Echo 也替你留住了。',
    '没写字也没关系，照片会说话。',
    '有些日子，一张图就够回忆了。',
  ];

  static const blank = [
    '空白也是一种记录，以后或许会想起这一刻。',
    '什么都没写，但你来过这里。',
  ];

  static const ultraShort = [
    '短短几句，也像在对自己轻轻说话。',
    '字不多，心意到了就好。',
    '轻飘飘的几句，也值得被留下。',
    '不必写长，真实就够了。',
    '你肯开口，就已经很好了。',
  ];

  static const short = [
    '一小段话，装下了一整天的心情。',
    '不多不少，刚好说出此刻。',
    '这些字很轻，但会留得很久。',
    '像对自己悄悄交代了一句。',
  ];

  static const medium = [
    '这一刻被记下来了，以后会慢慢显出意义。',
    '你把自己的一天，安放得很仔细。',
    '文字里藏着细小的温柔，Echo 替你留住了。',
    '有些感受，写下来就轻了一点。',
    '普通的一天，也值得被好好安放。',
  ];

  static const long = [
    '你写了很多，Echo 会好好替你收着。',
    '长长的回响，是留给未来自己的信。',
    '愿意说这么多，说明你在认真生活。',
    '这一篇，以后翻回来会很有分量。',
  ];

  static const keywordPools = <String, List<String>>{
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

  static List<String>? keywordPool(String key) => keywordPools[key];

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
