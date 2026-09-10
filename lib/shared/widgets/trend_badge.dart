import 'package:flutter/material.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';

/// A small pill showing a real percent change, colored by direction. Null
/// [percent] means there's nothing to compare against yet (e.g. yesterday
/// had zero orders) -- shown as a neutral "New" badge rather than a
/// misleading 0% or an infinite percentage.
class TrendBadge extends StatelessWidget {
  final double? percent;
  final bool onTint;

  const TrendBadge({super.key, required this.percent, this.onTint = false});

  @override
  Widget build(BuildContext context) {
    final p = percent;
    if (p == null || !p.isFinite) {
      return _pill(
        icon: Icons.fiber_new_rounded,
        label: 'New',
        color: onTint ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
        background: onTint ? Colors.white.withValues(alpha: 0.16) : Theme.of(context).colorScheme.surfaceContainerHigh,
      );
    }

    final isUp = p >= 0;
    final color = onTint ? Colors.white : (isUp ? AppTheme.success : AppTheme.error);
    final background = onTint
        ? Colors.white.withValues(alpha: 0.18)
        : (isUp ? AppTheme.success : AppTheme.error).withValues(alpha: 0.12);

    return _pill(
      icon: isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      label: '${isUp ? '+' : ''}${p.toStringAsFixed(0)}%',
      color: color,
      background: background,
    );
  }

  Widget _pill({required IconData icon, required String label, required Color color, required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppTheme.radius)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
