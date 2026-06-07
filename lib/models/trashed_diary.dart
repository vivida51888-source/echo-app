import 'diary.dart';

/// 回收站保留天数。
const diaryTrashRetentionDays = 15;

/// 回收站中的回响，保留删除时间以便自动清理。
class TrashedDiary {
  const TrashedDiary({
    required this.diary,
    required this.deletedAt,
  });

  final Diary diary;
  final DateTime deletedAt;

  int get daysRemaining {
    final expires = deletedAt.add(
      const Duration(days: diaryTrashRetentionDays),
    );
    final left = expires.difference(DateTime.now()).inDays;
    return left.clamp(0, diaryTrashRetentionDays);
  }

  Map<String, dynamic> toMap() => {
        'diary': diary.toMap(),
        'deletedAt': deletedAt.toIso8601String(),
      };

  factory TrashedDiary.fromMap(Map<dynamic, dynamic> map) {
    return TrashedDiary(
      diary: Diary.fromMap(
        Map<dynamic, dynamic>.from(map['diary'] as Map),
      ),
      deletedAt: DateTime.parse(map['deletedAt'] as String),
    );
  }
}
