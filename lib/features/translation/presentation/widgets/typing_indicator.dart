import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// iMessage-style animated pulsing dots typing indicator.
///
/// Shows three dots that pulse sequentially (staggered) while the model is
/// generating the first tokens. The parent passes [isVisible] based on
/// `state.isTranslating && state.translatedText.isEmpty`.
///
/// Animation pattern:
/// - Single [AnimationController] with `duration: 1200ms` and `repeat()`.
/// - Three [Tween<double>] with staggered [Interval] curves.
/// - Each dot's colour pulses via `sin(pi * value)` for smooth fade.
///
/// RTL-ready: dots are laid out in a [Row] using [MainAxisAlignment.center],
/// which works correctly in both LTR and RTL locales.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.isVisible});

  final bool isVisible;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered intervals — dot1 leads, dot3 trails.
  late final Animation<double> _dot1;
  late final Animation<double> _dot2;
  late final Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _dot1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _dot2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );
    _dot3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOut),
      ),
    );

    if (widget.isVisible) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.repeat();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _pulseColor(double animValue) {
    const dimColor = Color(0x66B0D0B0); // onSurfaceVariant at 40% opacity
    const brightColor = AppColors.onSurfaceVariant;
    final t = sin(pi * animValue).clamp(0.0, 1.0);
    return Color.lerp(dimColor, brightColor, t)!;
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _pulseColor(animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(12, 4, 48, 4),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(_dot1),
            const SizedBox(width: 4),
            _buildDot(_dot2),
            const SizedBox(width: 4),
            _buildDot(_dot3),
          ],
        ),
      ),
    );
  }
}
