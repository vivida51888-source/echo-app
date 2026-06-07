import 'package:flutter_test/flutter_test.dart';

import 'package:echo_app/models/todo_category.dart';
import 'package:echo_app/models/todo_reminder.dart';
import 'package:echo_app/utils/todo_natural_language.dart';

void main() {
  final reference = DateTime(2026, 6, 1, 10, 0); // 周日

  group('TodoNaturalLanguage', () {
    test('明天下午3点去超市买东西', () {
      final result = TodoNaturalLanguage.parse(
        '明天下午3点去超市买东西',
        now: reference,
      );

      expect(result.content, '去超市买东西');
      expect(result.reminderAt.year, 2026);
      expect(result.reminderAt.month, 6);
      expect(result.reminderAt.day, 2);
      expect(result.reminderAt.hour, 15);
      expect(result.reminderAt.minute, 0);
      expect(result.repeat, TodoRepeat.none);
      expect(result.category, TodoCategory.life);
      expect(result.matched, isTrue);
    });

    test('后天晚上8点半开会', () {
      final result = TodoNaturalLanguage.parse('后天晚上8点半开会', now: reference);

      expect(result.content, '开会');
      expect(result.reminderAt.day, 3);
      expect(result.reminderAt.hour, 20);
      expect(result.reminderAt.minute, 30);
      expect(result.category, TodoCategory.work);
    });

    test('每天上午7点晨跑', () {
      final result = TodoNaturalLanguage.parse('每天上午7点晨跑', now: reference);

      expect(result.content, '晨跑');
      expect(result.reminderAt.hour, 7);
      expect(result.repeat, TodoRepeat.daily);
      expect(result.category, TodoCategory.health);
    });

    test('每周三9点给妈妈打电话', () {
      final result = TodoNaturalLanguage.parse('每周三9点给妈妈打电话', now: reference);

      expect(result.content, '给妈妈打电话');
      expect(result.reminderAt.weekday, DateTime.wednesday);
      expect(result.reminderAt.hour, 9);
      expect(result.repeat, TodoRepeat.weekly);
      expect(result.category, TodoCategory.social);
    });

    test('工作日8点半提交报告', () {
      final result = TodoNaturalLanguage.parse('工作日8点半提交报告', now: reference);

      expect(result.content, '提交报告');
      expect(result.reminderAt.hour, 8);
      expect(result.reminderAt.minute, 30);
      expect(result.repeat, TodoRepeat.workday);
      expect(result.category, TodoCategory.work);
    });

    test('3点喝水', () {
      final result = TodoNaturalLanguage.parse('3点喝水', now: reference);

      expect(result.content, '喝水');
      expect(result.reminderAt.hour, 15);
      expect(result.category, TodoCategory.health);
    });

    test('6月5日14:30整理房间', () {
      final result = TodoNaturalLanguage.parse('6月5日14:30整理房间', now: reference);

      expect(result.content, '整理房间');
      expect(result.reminderAt.month, 6);
      expect(result.reminderAt.day, 5);
      expect(result.reminderAt.hour, 14);
      expect(result.reminderAt.minute, 30);
      expect(result.category, TodoCategory.self);
    });

    test('每个星期天的下午六点给奶奶打电话', () {
      final result = TodoNaturalLanguage.parse(
        '每个星期天的下午六点给奶奶打电话',
        now: reference,
      );

      expect(result.content, '给奶奶打电话');
      expect(result.reminderAt.weekday, DateTime.sunday);
      expect(result.reminderAt.hour, 18);
      expect(result.reminderAt.minute, 0);
      expect(result.repeat, TodoRepeat.weekly);
      expect(result.category, TodoCategory.social);
      expect(result.matched, isTrue);
    });

    test('每逢周五晚上聚会', () {
      final result = TodoNaturalLanguage.parse('每逢周五晚上聚会', now: reference);

      expect(result.content, '聚会');
      expect(result.reminderAt.weekday, DateTime.friday);
      expect(result.repeat, TodoRepeat.weekly);
      expect(result.category, TodoCategory.social);
    });

    test('每个星期一早上8点开周会', () {
      final result = TodoNaturalLanguage.parse(
        '每个星期一早上8点开周会',
        now: reference,
      );

      expect(result.content, '开周会');
      expect(result.reminderAt.weekday, DateTime.monday);
      expect(result.reminderAt.hour, 8);
      expect(result.repeat, TodoRepeat.weekly);
      expect(result.category, TodoCategory.work);
    });

    test('提醒我吃药', () {
      final result = TodoNaturalLanguage.parse('提醒我吃药', now: reference);
      expect(result.content, '吃药');
      expect(result.category, TodoCategory.health);
    });

    test('提醒我买高铁票', () {
      final result = TodoNaturalLanguage.parse('提醒我买高铁票', now: reference);
      expect(result.content, '买高铁票');
      expect(result.category, TodoCategory.life);
    });

    test('帮我定个一小时后打球的提醒', () {
      final result = TodoNaturalLanguage.parse(
        '帮我定个一小时后打球的提醒',
        now: reference,
      );
      expect(result.content, '打球');
      expect(result.matched, isTrue);
      expect(
        result.reminderAt.difference(reference).inMinutes,
        closeTo(60, 1),
      );
      expect(result.category, TodoCategory.health);
    });

    test('plain text without schedule defaults to one hour later', () {
      final result = TodoNaturalLanguage.parse('买牛奶', now: reference);

      expect(result.content, '买牛奶');
      expect(result.reminderAt, reference.add(const Duration(hours: 1)));
      expect(result.matched, isFalse);
      expect(result.category, TodoCategory.life);
    });

    test('15号交房租', () {
      final result = TodoNaturalLanguage.parse('15号交房租', now: reference);

      expect(result.content, '交房租');
      expect(result.repeat, TodoRepeat.monthly);
      expect(result.reminderAt.day, 15);
      expect(result.reminderAt.hour, 9);
      expect(result.category, TodoCategory.life);
      expect(result.matched, isTrue);
    });

    test('每月15号交房租', () {
      final result = TodoNaturalLanguage.parse('每月15号交房租', now: reference);

      expect(result.content, '交房租');
      expect(result.repeat, TodoRepeat.monthly);
      expect(result.reminderAt.day, 15);
      expect(result.category, TodoCategory.life);
    });

    test('月底前完成ppt', () {
      final result = TodoNaturalLanguage.parse('月底前完成ppt', now: reference);

      expect(result.content, '完成ppt');
      expect(result.reminderAt.month, 6);
      expect(result.reminderAt.day, 30);
      expect(result.reminderAt.hour, 18);
      expect(result.repeat, TodoRepeat.none);
      expect(result.category, TodoCategory.work);
      expect(result.matched, isTrue);
    });

    test('记得提醒我周五之前搞定那个报告', () {
      final result = TodoNaturalLanguage.parse(
        '记得提醒我周五之前搞定那个报告',
        now: reference,
      );

      expect(result.content, '搞定报告');
      expect(result.reminderAt.weekday, DateTime.friday);
      expect(result.reminderAt.hour, 18);
      expect(result.category, TodoCategory.work);
      expect(result.matched, isTrue);
    });

    test('下午出门前把垃圾带下去', () {
      final result = TodoNaturalLanguage.parse(
        '下午出门前把垃圾带下去',
        now: reference,
      );

      expect(result.content, '垃圾带下去');
      expect(result.reminderAt.hour, 14);
      expect(result.category, TodoCategory.life);
      expect(result.matched, isTrue);
    });

    test('每隔天晨跑', () {
      final result = TodoNaturalLanguage.parse('每隔天晨跑', now: reference);

      expect(result.content, '晨跑');
      expect(result.repeat, TodoRepeat.alternateDay);
      expect(result.category, TodoCategory.health);
      expect(result.matched, isTrue);
    });

    test('隔天跑步', () {
      final result = TodoNaturalLanguage.parse('隔天跑步', now: reference);

      expect(result.content, '跑步');
      expect(result.repeat, TodoRepeat.alternateDay);
      expect(result.category, TodoCategory.health);
    });

    test('打卡', () {
      final result = TodoNaturalLanguage.parse('打卡', now: reference);

      expect(result.content, '打卡');
      expect(result.category, TodoCategory.self);
    });

    test('背单词', () {
      final result = TodoNaturalLanguage.parse('每天7点背单词', now: reference);

      expect(result.content, '背单词');
      expect(result.category, TodoCategory.self);
      expect(result.repeat, TodoRepeat.daily);
    });

    test('背20个单词', () {
      final result = TodoNaturalLanguage.parse('背20个单词', now: reference);

      expect(result.category, TodoCategory.self);
    });
  });
}
