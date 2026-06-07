/// 待来日：每年循环；起点日：从某天起累计。
enum ImportantDayMode {
  annual('待来日'),
  anchor('起点日');

  const ImportantDayMode(this.label);
  final String label;

  static ImportantDayMode fromName(String name) =>
      ImportantDayMode.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ImportantDayMode.annual,
      );
}

enum ImportantDayKind {
  birthday('生日'),
  anniversary('纪念'),
  together('相遇'),
  work('入职'),
  study('上学'),
  married('结婚'),
  dating('恋爱'),
  met('相识'),
  other('其他');

  const ImportantDayKind(this.label);
  final String label;

  static ImportantDayKind fromName(String name) =>
      ImportantDayKind.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ImportantDayKind.other,
      );

  bool get isRomantic =>
      this == ImportantDayKind.married ||
      this == ImportantDayKind.dating ||
      this == ImportantDayKind.met;

  static List<ImportantDayKind> forMode(ImportantDayMode mode) {
    if (mode == ImportantDayMode.annual) {
      return [
        ImportantDayKind.birthday,
        ImportantDayKind.anniversary,
        ImportantDayKind.together,
        ImportantDayKind.other,
      ];
    }
    return [
      ImportantDayKind.work,
      ImportantDayKind.study,
      ImportantDayKind.married,
      ImportantDayKind.other,
    ];
  }
}

/// 起点日达到的刻度：第 N 天，或满 N 年。
class ImportantDayMilestoneHit {
  const ImportantDayMilestoneHit({
    this.dayCount,
    this.yearCount,
  }) : assert(dayCount != null || yearCount != null);

  final int? dayCount;
  final int? yearCount;

  bool get isDayCount => dayCount != null;
  bool get isYearCount => yearCount != null;
}

class ImportantDay {
  const ImportantDay({
    required this.id,
    required this.title,
    required this.month,
    required this.day,
    this.startYear,
    this.mode = ImportantDayMode.annual,
    this.kind = ImportantDayKind.other,
    this.remindDaysBefore = const [0],
    this.enabled = true,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String title;
  final int month;
  final int day;
  final int? startYear;
  final ImportantDayMode mode;
  final ImportantDayKind kind;
  /// 轮回日：0 / 1 / 3 / 7 = 提前几天提醒。
  final List<int> remindDaysBefore;
  final bool enabled;
  final String? note;
  final DateTime createdAt;

  bool get isAnchor => mode == ImportantDayMode.anchor;

  DateTime? get anchorStart {
    if (!isAnchor || startYear == null) return null;
    return DateTime(startYear!, month, day);
  }

  /// 纪念日：起点第几天起，按自然年拆成「年 + 天」便于展示。
  ({int years, int days})? elapsedParts([DateTime? from]) {
    final start = anchorStart;
    if (start == null) return null;
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final startDay = DateTime(start.year, start.month, start.day);
    if (today.isBefore(startDay)) return null;

    var years = today.year - start.year;
    var lastAnniversary = DateTime(today.year, start.month, start.day);
    if (lastAnniversary.isAfter(today)) {
      years -= 1;
      lastAnniversary = DateTime(today.year - 1, start.month, start.day);
    }
    final days = today.difference(lastAnniversary).inDays;
    return (years: years, days: days);
  }

  /// 纪念日：第几天（起点当天为第 1 天）。
  int? daysElapsed([DateTime? from]) {
    final start = anchorStart;
    if (start == null) return null;
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final startDay = DateTime(start.year, start.month, start.day);
    if (today.isBefore(startDay)) return null;
    return today.difference(startDay).inDays + 1;
  }

  /// 轮回日：距下一次还有几天。
  DateTime get nextOccurrence {
    final now = DateTime.now();
    return _occurrenceOnOrAfter(now.year, now);
  }

  int daysUntil([DateTime? from]) {
    if (isAnchor) {
      final hit = nextMilestone(from);
      if (hit == null) return 9999;
      final when = _milestoneDate(hit, from);
      if (when == null) return 9999;
      final base = from ?? DateTime.now();
      final today = DateTime(base.year, base.month, base.day);
      return when.difference(today).inDays;
    }
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final target = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
    );
    return target.difference(today).inDays;
  }

  bool isToday([DateTime? from]) {
    final base = from ?? DateTime.now();
    return base.month == month && base.day == day;
  }

  int? yearsSince([DateTime? from]) {
    if (startYear == null) return null;
    final base = from ?? DateTime.now();
    var years = base.year - startYear!;
    if (base.month < month || (base.month == month && base.day < day)) {
      years -= 1;
    }
    return years < 0 ? null : years + 1;
  }

  /// 起点日固定天数刻度。
  static List<int> dayCountMilestonesFor(ImportantDayKind kind) {
    if (kind.isRomantic) return const [52, 99, 520, 1314];
    return const [100];
  }

  /// 起点日：最多预告未来多少年整。
  static const anchorYearHorizon = 30;

  ImportantDayMilestoneHit? milestoneOn([DateTime? from]) {
    if (!isAnchor) return null;
    final start = anchorStart;
    if (start == null) return null;
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);

    for (final count in dayCountMilestonesFor(kind)) {
      final when = DateTime(start.year, start.month, start.day)
          .add(Duration(days: count - 1));
      if (when == today) {
        return ImportantDayMilestoneHit(dayCount: count);
      }
    }

    for (var y = 1; y <= anchorYearHorizon; y++) {
      final when = DateTime(start.year + y, start.month, start.day);
      if (when == today) {
        return ImportantDayMilestoneHit(yearCount: y);
      }
    }
    return null;
  }

  ImportantDayMilestoneHit? nextMilestone([DateTime? from]) {
    if (!isAnchor) return null;
    final start = anchorStart;
    if (start == null) return null;
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);

    ImportantDayMilestoneHit? nearest;
    DateTime? nearestDate;

    void consider(DateTime when, ImportantDayMilestoneHit hit) {
      if (when.isBefore(today)) return;
      if (nearestDate == null || when.isBefore(nearestDate!)) {
        nearestDate = when;
        nearest = hit;
      }
    }

    for (final count in dayCountMilestonesFor(kind)) {
      consider(
        DateTime(start.year, start.month, start.day)
            .add(Duration(days: count - 1)),
        ImportantDayMilestoneHit(dayCount: count),
      );
    }

    for (var y = 1; y <= anchorYearHorizon; y++) {
      consider(
        DateTime(start.year + y, start.month, start.day),
        ImportantDayMilestoneHit(yearCount: y),
      );
    }

    return nearest;
  }

  List<({DateTime when, ImportantDayMilestoneHit hit})> upcomingMilestones([
    DateTime? from,
  ]) {
    if (!isAnchor) return const [];
    final start = anchorStart;
    if (start == null) return const [];
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final list = <({DateTime when, ImportantDayMilestoneHit hit})>[];

    for (final count in dayCountMilestonesFor(kind)) {
      final when = DateTime(start.year, start.month, start.day)
          .add(Duration(days: count - 1));
      if (!when.isBefore(today)) {
        list.add((
          when: when,
          hit: ImportantDayMilestoneHit(dayCount: count),
        ));
      }
    }

    for (var y = 1; y <= anchorYearHorizon; y++) {
      final when = DateTime(start.year + y, start.month, start.day);
      if (!when.isBefore(today)) {
        list.add((
          when: when,
          hit: ImportantDayMilestoneHit(yearCount: y),
        ));
      }
    }

    list.sort((a, b) => a.when.compareTo(b.when));
    return list;
  }

  DateTime? _milestoneDate(ImportantDayMilestoneHit hit, [DateTime? from]) {
    final start = anchorStart;
    if (start == null) return null;
    if (hit.dayCount != null) {
      return DateTime(start.year, start.month, start.day)
          .add(Duration(days: hit.dayCount! - 1));
    }
    if (hit.yearCount != null) {
      return DateTime(start.year + hit.yearCount!, start.month, start.day);
    }
    return null;
  }

  DateTime _occurrenceOnOrAfter(int year, DateTime from) {
    var candidate = DateTime(year, month, day);
    final fromDay = DateTime(from.year, from.month, from.day);
    if (!candidate.isBefore(fromDay)) return candidate;
    return DateTime(year + 1, month, day);
  }

  ImportantDay copyWith({
    String? title,
    int? month,
    int? day,
    int? startYear,
    bool clearStartYear = false,
    ImportantDayMode? mode,
    ImportantDayKind? kind,
    List<int>? remindDaysBefore,
    bool? enabled,
    String? note,
    bool clearNote = false,
  }) {
    return ImportantDay(
      id: id,
      title: title ?? this.title,
      month: month ?? this.month,
      day: day ?? this.day,
      startYear: clearStartYear ? null : (startYear ?? this.startYear),
      mode: mode ?? this.mode,
      kind: kind ?? this.kind,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      enabled: enabled ?? this.enabled,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'month': month,
        'day': day,
        if (startYear != null) 'startYear': startYear,
        'mode': mode.name,
        'kind': kind.name,
        'remindDaysBefore': remindDaysBefore,
        'enabled': enabled,
        if (note != null) 'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImportantDay.fromJson(Map<dynamic, dynamic> json) {
    final rawRemind = json['remindDaysBefore'];
    final reminds = rawRemind is List
        ? rawRemind.map((e) => (e as num).toInt()).toList()
        : <int>[0];

    return ImportantDay(
      id: json['id'] as String,
      title: json['title'] as String,
      month: (json['month'] as num).toInt(),
      day: (json['day'] as num).toInt(),
      startYear: json['startYear'] as int?,
      mode: ImportantDayMode.fromName(json['mode'] as String? ?? ''),
      kind: ImportantDayKind.fromName(json['kind'] as String? ?? ''),
      remindDaysBefore: reminds.isEmpty ? const [0] : reminds,
      enabled: json['enabled'] as bool? ?? true,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
