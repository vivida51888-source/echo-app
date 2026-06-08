import 'package:flutter/material.dart';

/// 数字红点：1 显示圆点，2+ 显示具体数量。
class EchoCountBadge extends StatelessWidget {
  const EchoCountBadge({
    super.key,
    required this.count,
    this.size = 18,
    this.offset = const Offset(2, -2),
    this.child,
  });

  final int count;
  final double size;
  final Offset offset;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child ?? const SizedBox.shrink();

    final badge = Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: count > 1
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: const Color(0xFFE85D4A),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white,
          width: size <= 10 ? 1.0 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: count > 1
          ? Text(
              count > 99 ? '99+' : '$count',
              style: TextStyle(
                color: Colors.white,
                fontSize: count > 9 ? 9 : 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            )
          : null,
    );

    if (child == null) return badge;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(
          right: offset.dx,
          top: offset.dy,
          child: badge,
        ),
      ],
    );
  }
}
