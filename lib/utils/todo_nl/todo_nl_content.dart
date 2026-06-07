/// 任务名清洗：去掉提醒包裹语、口语虚词。
abstract final class TodoNlContentCleaner {
  static final _prefixes = _sorted([
    '请帮我', '麻烦帮我', '麻烦你帮我', '麻烦你', '帮忙', '请帮',
    '帮我设定一个', '帮我设置一个', '帮我定一个', '帮我设一个', '帮我安排一个',
    '帮我设定个', '帮我设置个', '帮我定个', '帮我设个', '帮我安排个',
    '帮我设定', '帮我设置', '帮我定', '帮我设', '帮我安排', '帮我',
    '记得提醒', '记得提醒我', '提醒我', '提醒一下', '提醒',
    '设定一个', '设置一个', '定一个', '设一个', '安排一个',
    '设定个', '设置个', '定个', '设个', '安排个',
    '设定', '设置', '安排', '设',
    '别忘了', '别忘记', '不要忘记', '不要忘', '记得', '勿忘',
    '请', '给我',
  ]);

  static final _suffixes = _sorted([
    '的提醒', '的事项', '的事情', '的事儿', '的通知', '的待办', '的任务',
    '提醒一下', '提醒', '通知', '待办', '任务',
    '的事', '就好', '可以吗', '好吗', '行不行', '一下', '呗', '啊', '吧', '呢', '了', '哦',
  ]);

  static final _fillers = _sorted([
    '那个', '这个', '那个', '一下子', '一下子',
  ]);

  static List<String> _sorted(List<String> items) {
    final copy = List<String>.from(items);
    copy.sort((a, b) => b.length.compareTo(a.length));
    return copy;
  }

  static String clean(String input) {
    var text = input
        .replaceAll(RegExp(r'[，,。、；;！!？?…~～]+$'), '')
        .replaceAll(RegExp(r'^[，,。、；;！!？?…~～]+'), '')
        .trim();

    if (text.isEmpty) return text;

    var guard = 0;
    var changed = true;
    while (changed && guard < 32) {
      guard++;
      changed = false;

      for (final prefix in _prefixes) {
        if (text.startsWith(prefix)) {
          text = text.substring(prefix.length);
          changed = true;
          break;
        }
      }

      for (final suffix in _suffixes) {
        if (text.endsWith(suffix)) {
          text = text.substring(0, text.length - suffix.length);
          changed = true;
          break;
        }
      }

      for (final filler in _fillers) {
        if (text.contains(filler)) {
          text = text.replaceAll(filler, '');
          changed = true;
          break;
        }
      }

      text = text.replaceAll(RegExp(r'^把'), '');
      text = text.replaceAll(RegExp(r'^的+'), '').replaceAll(RegExp(r'的+$'), '');
    }

    text = text.replaceAll(RegExp(r'\s+'), '');
    return text.trim();
  }
}
