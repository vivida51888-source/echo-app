import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:echo_app/main.dart';
import 'package:echo_app/services/diary_draft_service.dart';
import 'package:echo_app/services/diary_service.dart';
import 'package:echo_app/utils/diary_format.dart';
import 'package:echo_app/utils/echo_copy.dart';
import 'package:echo_app/services/echo_insight_service.dart';
import 'package:echo_app/models/todo_reminder.dart';
import 'package:echo_app/services/todo_service.dart';
import 'package:echo_app/utils/todo_schedule.dart';
import 'package:echo_app/services/mock_ai_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('./.test_hive');
    await DiaryService.instance.init();
    await TodoService.instance.init();
  });

  testWidgets('Echo home page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EchoApp());

    expect(find.text('写下今天'), findsOneWidget);
    expect(find.text('回看过去'), findsOneWidget);
    expect(find.text('此刻'), findsOneWidget);
    expect(find.text('回响'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);

    await tester.tap(find.text('回响'));
    await tester.pumpAndSettle();

    expect(find.text('全部'), findsOneWidget);
    expect(find.text('按月'), findsOneWidget);
    expect(find.text('按周'), findsOneWidget);
  });

  test('deriveTitle uses first line', () {
    expect(
      DiaryFormat.deriveTitle('你好世界\n第二行'),
      '你好世界',
    );
  });

  test('dailyPhrase is stable for same day', () {
    final date = DateTime(2026, 5, 17, 10);
    expect(EchoCopy.dailyPhrase(date), EchoCopy.dailyPhrase(date));
  });

  test('mock AI extracts keywords', () {
    final result = MockAiService.instance.analyze('今天工作很累，朋友请我吃饭');
    expect(result.keywords, contains('工作'));
    expect(result.keywords, contains('朋友'));
    expect(result.summary.isNotEmpty, true);
  });

  test('diary draft roundtrip', () async {
    await DiaryDraftService.instance.save(
      draftId: 'draft_test',
      content: '草稿内容',
      moodWeather: '☀️ 晴',
      imagePaths: const [],
      recordedAt: DateTime(2026, 5, 20, 10),
      fromEmotionalEntry: false,
    );
    final loaded = await DiaryDraftService.instance.load();
    expect(loaded?.content, '草稿内容');
    await DiaryDraftService.instance.clear();
  });

  test('echo insight filters diaries by month', () {
    final now = DateTime.now();
    final diaries =
        EchoInsightService.instance.diariesInMonth(now.year, now.month);
    expect(diaries, isA<List>());
  });

  test('todo toggle complete and uncomplete', () async {
    final id = await TodoService.instance.add(
      content: '测试待办',
      reminderAt: DateTime.now().add(const Duration(hours: 1)),
    );
    await TodoService.instance.complete(id);
    expect(TodoService.instance.getById(id)!.isPermanentlyCompleted, true);
    await TodoService.instance.uncomplete(id);
    expect(TodoService.instance.getById(id)!.isPermanentlyCompleted, false);
    await TodoService.instance.delete(id);
  });

  test('repeat todo advances reminder on complete', () async {
    final id = await TodoService.instance.add(
      content: '每日喝水',
      reminderAt: DateTime.now(),
      repeat: TodoRepeat.daily,
    );
    await TodoService.instance.complete(id);
    final updated = TodoService.instance.getById(id)!;
    expect(updated.isPermanentlyCompleted, false);
    expect(updated.lastCompletedAt, isNotNull);
    expect(
      updated.reminderAt.isAfter(DateTime.now()),
      true,
    );
    await TodoService.instance.delete(id);
  });

  test('todo schedule groups expired and today', () async {
    final now = DateTime.now();
    final expired = await TodoService.instance.add(
      content: '过期项',
      reminderAt: now.subtract(const Duration(hours: 2)),
    );
    final today = await TodoService.instance.add(
      content: '今天项',
      reminderAt: DateTime(now.year, now.month, now.day, 20, 0),
    );
    final groups = TodoSchedule.groupActive(
      TodoService.instance.activeItems(now),
      now,
    );
    expect(groups[TodoTimeGroup.expired]!.any((t) => t.id == expired), true);
    expect(groups[TodoTimeGroup.today]!.any((t) => t.id == today), true);
    await TodoService.instance.delete(expired);
    await TodoService.instance.delete(today);
  });

}
