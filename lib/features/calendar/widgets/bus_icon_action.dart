import 'package:flutter/material.dart';

/// Track, change, or remove control for a bus. The whole cell is the tap target.
class BusIconAction extends StatelessWidget {
  const BusIconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.loading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: loading ? null : onPressed,
        iconSize: 18,
        style: IconButton.styleFrom(
          foregroundColor: tint,
          backgroundColor: tint.withValues(alpha: 0.12),
          fixedSize: const Size(32, 32),
          minimumSize: const Size(32, 32),
          maximumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
        ),
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: tint),
              )
            : Icon(icon),
      ),
    );
  }
}
