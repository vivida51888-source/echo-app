/// 待办拆解步骤。
class TodoSubtask {
  const TodoSubtask({
    required this.id,
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool completed;
  final DateTime? completedAt;

  TodoSubtask copyWith({
    String? title,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TodoSubtask(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TodoSubtask.fromMap(Map<dynamic, dynamic> map) {
    return TodoSubtask(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }
}
