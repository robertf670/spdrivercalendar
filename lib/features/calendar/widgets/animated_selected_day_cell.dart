import 'package:flutter/material.dart';

/// Draws the existing animated border around a selected calendar day.
class AnimatedSelectedDayCell extends StatefulWidget {
  const AnimatedSelectedDayCell({
    super.key,
    required this.backgroundColor,
    required this.isToday,
    required this.isBankHoliday,
    required this.borderColor,
    required this.child,
  });

  final Color? backgroundColor;
  final bool isToday;
  final bool isBankHoliday;
  final Color borderColor;
  final Widget child;

  @override
  State<AnimatedSelectedDayCell> createState() =>
      _AnimatedSelectedDayCellState();
}

class _AnimatedSelectedDayCellState extends State<AnimatedSelectedDayCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 2.0,
      end: 3.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final borderColor =
            widget.isBankHoliday ? Colors.red : widget.borderColor;
        final borderWidth = _animation.value;

        return Container(
          margin: const EdgeInsets.all(4.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: widget.isToday
                ? Border.all(
                    color: widget.isBankHoliday ? Colors.red : Colors.blue,
                    width: 2,
                  )
                : Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
