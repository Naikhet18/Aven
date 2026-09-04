import 'package:flutter/material.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';

/// Animates a number counting up (or down) to [value] whenever it changes,
/// instead of a static Text that just snaps -- the count-up read on refresh
/// is what makes a stat feel alive rather than a plain label. Pure
/// TweenAnimationBuilder, no dependency.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: AppTheme.emphasizedCurve,
      builder: (context, animatedValue, _) => Text(formatter(animatedValue), style: style),
    );
  }
}
