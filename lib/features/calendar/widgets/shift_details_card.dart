import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class ShiftDetailsCard extends StatelessWidget {
  final DateTime date;
  final String shift;
  final Map<String, ShiftInfo> shiftInfoMap;
  final BankHoliday? bankHoliday;

  const ShiftDetailsCard({
    Key? key,
    required this.date,
    required this.shift,
    required this.shiftInfoMap,
    this.bankHoliday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shiftInfo = shiftInfoMap[shift];
    final isBankHoliday = bankHoliday != null;
    
    // Determine if it's a Saturday
    final isSaturday = date.weekday == DateTime.saturday;
    
    // Get display name for the shift - show "Relief Shift" for Middle shifts on Saturdays
    final String shiftDisplayName = (shift == 'M' && isSaturday) 
        ? 'Relief' 
        : shiftInfo?.name ?? 'Unknown';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          gradient: LinearGradient(
            colors: [
              shiftInfo?.color.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: const [0.3, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Reduced vertical padding
        child: Row(
          children: [
            // Left section - Shift icon and info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Smaller padding
                    decoration: BoxDecoration(
                      color: shiftInfo?.color.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                    ),
                    child: Icon(Icons.work, color: shiftInfo?.color, size: 20), // Smaller icon
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Important to keep card compact
                      children: [
                        Text(
                          '$shiftDisplayName Shift',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bank holiday indicator (if present)
            if (isBankHoliday)
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Smaller padding
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                      ),
                      child: const Icon(Icons.celebration, color: AppTheme.errorColor, size: 20), // Smaller icon
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bankHoliday!.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
