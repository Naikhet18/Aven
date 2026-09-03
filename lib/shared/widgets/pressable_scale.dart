import 'package:flutter/material.dart';

/// Wraps [child] with a subtle press-down scale, the single tactile detail
/// that makes tap targets across the app feel like one consistent, premium
/// surface instead of default flat Material taps. Pure [AnimatedScale] --
/// no extra dependency, negligible build cost.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final String? semanticLabel;
  final bool semanticSelected;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
    this.semanticLabel,
    this.semanticSelected = false,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.semanticLabel == null) return content;
    return Semantics(
      button: true,
      selected: widget.semanticSelected,
      label: widget.semanticLabel,
      child: content,
    );
  }
}
