import '../models/todo_category.dart';
import '../models/todo_reminder.dart';
import 'todo_nl/todo_nl_category.dart';
import 'todo_nl/todo_nl_content.dart';
import 'todo_nl/todo_nl_schedule.dart';

/// 自然语言解析结果。
class TodoNaturalLanguageResult {
  const TodoNaturalLanguageResult({
    required this.content,
    required this.reminderAt,
    required this.repeat,
    required this.category,
    required this.matched,
  });

  final String content;
  final DateTime reminderAt;
  final TodoRepeat repeat;
  final TodoCategory category;

  /// 是否识别出时间、重复或截止语义。
  final bool matched;

  bool get hasSchedule => matched;
}

/// 中文待办自然语言解析（规则引擎，本地离线）。
///
/// 流水线：规范化 → 时间/重复抽取 → 任务名清洗 → 分类加权。
abstract final class TodoNaturalLanguage {
  static TodoNaturalLanguageResult parse(String input, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final text = _normalize(input);

    if (text.isEmpty) {
      return TodoNaturalLanguageResult(
        content: '',
        reminderAt: reference.add(const Duration(hours: 1)),
        repeat: TodoRepeat.none,
        category: TodoCategory.life,
        matched: false,
      );
    }

    final schedule = TodoNlScheduleExtractor.extract(text, reference);
    final rawTask = TodoNlScheduleExtractor.extractTaskBody(text, schedule.spans);
    var content = TodoNlContentCleaner.clean(rawTask);
    if (content.isEmpty) {
      content = TodoNlContentCleaner.clean(text);
    }

    final category = TodoNlCategoryResolver.resolve(
      text,
      contentHint: content.isEmpty ? null : content,
    );

    return TodoNaturalLanguageResult(
      content: content.isEmpty ? text : content,
      reminderAt: schedule.reminderAt,
      repeat: schedule.repeat,
      category: category,
      matched: schedule.matched,
    );
  }

  static String _normalize(String input) {
    var text = input.trim();
    const full = '０１２３４５６７８９：，。、';
    const half = '0123456789:，。、';
    for (var i = 0; i < full.length; i++) {
      text = text.replaceAll(full[i], half[i]);
    }
    text = text.replaceAll(RegExp(r'\s+'), '');
    // 口语归一
    text = text.replaceAll('礼拜', '星期');
    text = text.replaceAll('钟头', '小时');
    return text;
  }
}
