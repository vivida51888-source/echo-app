import 'package:flutter/material.dart';

/// 待办生活分类（少量、覆盖日常基本场景）。
enum TodoCategory {
  life('生活', Icons.home_outlined, Color(0xFFB8956A)),
  health('健康', Icons.favorite_border, Color(0xFF6FAF82)),
  work('工作', Icons.work_outline, Color(0xFF6B8CAE)),
  social('社交', Icons.people_outline, Color(0xFFD4849A)),
  self('学习', Icons.school_outlined, Color(0xFF9B87C4));

  const TodoCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static TodoCategory fromName(String? name) {
    if (name == null || name.isEmpty) return TodoCategory.life;
    if (name == 'relation') return TodoCategory.social;
    return TodoCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => TodoCategory.life,
    );
  }
}
