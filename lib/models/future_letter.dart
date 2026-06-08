import '../l10n/localized.dart';

/// 封存给未来自己的信。
class FutureLetter {
  const FutureLetter({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.deliverAt,
    this.openedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime deliverAt;
  final DateTime? openedAt;

  static const maxContentLength = 1500;

  bool get isOpened => openedAt != null;

  bool isDue([DateTime? now]) {
    if (isOpened) return false;
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final deliver = DateTime(
      deliverAt.year,
      deliverAt.month,
      deliverAt.day,
    );
    return !deliver.isAfter(today);
  }

  bool isPending([DateTime? now]) => !isOpened && !isDue(now);

  int daysUntil([DateTime? now]) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final deliver = DateTime(
      deliverAt.year,
      deliverAt.month,
      deliverAt.day,
    );
    return deliver.difference(today).inDays;
  }

  /// 提前拆信所需回响币（低于皮肤最低价 680）。
  int earlyOpenCoinCost([DateTime? now]) {
    final days = daysUntil(now);
    if (days <= 0) return 0;
    return (days * 5 + 80).clamp(96, 520);
  }

  String previewLine() {
    final line = content.split('\n').first.trim();
    if (line.isEmpty) return tr('（空信）', '(Empty letter)');
    if (line.length <= 24) return line;
    return '${line.substring(0, 24)}…';
  }

  FutureLetter copyWith({
    String? content,
    DateTime? deliverAt,
    DateTime? openedAt,
    bool clearOpenedAt = false,
  }) {
    return FutureLetter(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt,
      deliverAt: deliverAt ?? this.deliverAt,
      openedAt: clearOpenedAt ? null : (openedAt ?? this.openedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'deliverAt': deliverAt.toIso8601String(),
        if (openedAt != null) 'openedAt': openedAt!.toIso8601String(),
      };

  factory FutureLetter.fromJson(Map<dynamic, dynamic> json) {
    return FutureLetter(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliverAt: DateTime.parse(json['deliverAt'] as String),
      openedAt: json['openedAt'] == null
          ? null
          : DateTime.parse(json['openedAt'] as String),
    );
  }
}

/// 送达预设。
enum FutureLetterPreset {
  days7('七日后', 7),
  days30('三十日后', 30),
  days100('一百日后', 100),
  year1('一年后', 365);

  const FutureLetterPreset(this.label, this.days);
  final String label;
  final int days;

  DateTime deliverFrom(DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    return base.add(Duration(days: days));
  }
}
