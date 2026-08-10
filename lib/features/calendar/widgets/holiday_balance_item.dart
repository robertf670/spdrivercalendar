import 'package:flutter/material.dart';

/// Compact Today / Remaining / Booked balance cell.
class HolidayBalanceItem extends StatelessWidget {
  const HolidayBalanceItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final labelFontSize = screenWidth < 350
        ? 9.0
        : screenWidth < 400
            ? 9.5
            : screenWidth < 600
                ? 10.0
                : 11.0;
    final valueFontSize = screenWidth < 350
        ? 12.0
        : screenWidth < 400
            ? 13.0
            : screenWidth < 600
                ? 14.0
                : 15.0;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return column;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: column,
    );
  }
}
