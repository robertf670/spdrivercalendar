import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';

class ShiftDetailsCard extends StatelessWidget {
  final DateTime date;
  final String shift;
  final Map<String, ShiftInfo> shiftInfoMap;
  final BankHoliday? bankHoliday;
  final bool hasDayNote;
  final VoidCallback onShowDayNotes;

  const ShiftDetailsCard({
    super.key,
    required this.date,
    required this.shift,
    required this.shiftInfoMap,
    this.bankHoliday,
    required this.hasDayNote,
    required this.onShowDayNotes,
  });

  @override
  Widget build(BuildContext context) {
    final shiftInfo = shiftInfoMap[shift];
    final isBankHoliday = bankHoliday != null;
    
    // Determine if it's a Saturday or Saturday service date
    final isSaturday = RosterService.isSaturdayService(date) || date.weekday == DateTime.saturday;
    final isSaturdayService = RosterService.isSaturdayService(date);
    
    // Get display name for the shift - show "Relief Shift" for Middle shifts on Saturdays
    final String shiftName = (shift == 'M' && isSaturday) 
        ? 'Relief' 
        : shiftInfo?.name ?? 'Unknown';
    final bool isSwapped = RestDaySwapService.isSwappedRestDay(date) || RestDaySwapService.isSwappedWorkDay(date);
    final String shiftDisplayName = isSwapped ? '$shiftName Shift Swapped' : '$shiftName Shift';
    
    // Calculate responsive badge sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final badgeSizes = _getBadgeSizes(screenWidth);
    
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
              shiftInfo?.color.withValues(alpha: 0.2) ?? Colors.blue.withValues(alpha: 0.2),
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
                      color: shiftInfo?.color.withValues(alpha: 0.2) ?? Colors.blue.withValues(alpha: 0.2),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shiftDisplayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (isSaturdayService) ...[
                              SizedBox(width: badgeSizes['spacing']!),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: badgeSizes['paddingH']!,
                                  vertical: badgeSizes['paddingV']!,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(badgeSizes['radius']!),
                                ),
                                child: Text(
                                  'SAT Service',
                                  style: TextStyle(
                                    fontSize: badgeSizes['fontSize']!,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                        color: AppTheme.errorColor.withValues(alpha: 0.2),
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
            // Notes icon - same as event cards
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                onTap: onShowDayNotes,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    children: [
                      Icon(
                        hasDayNote ? Icons.notes : Icons.notes_outlined,
                        size: 18,
                        color: hasDayNote
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.8))
                            : (shiftInfo?.color ?? Colors.blue).withValues(alpha: 0.6),
                      ),
                      if (hasDayNote)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to calculate responsive badge sizes
  Map<String, double> _getBadgeSizes(double screenWidth) {
    if (screenWidth < 350) {
      return {
        'fontSize': 8.0,
        'paddingH': 4.0,
        'paddingV': 1.0,
        'radius': 3.0,
        'spacing': 4.0,
      };
    } else if (screenWidth < 450) {
      return {
        'fontSize': 9.0,
        'paddingH': 5.0,
        'paddingV': 1.5,
        'radius': 4.0,
        'spacing': 6.0,
      };
    } else if (screenWidth < 600) {
      return {
        'fontSize': 10.0,
        'paddingH': 6.0,
        'paddingV': 2.0,
        'radius': 4.0,
        'spacing': 8.0,
      };
    } else if (screenWidth < 900) {
      return {
        'fontSize': 11.0,
        'paddingH': 7.0,
        'paddingV': 2.5,
        'radius': 5.0,
        'spacing': 10.0,
      };
    } else {
      return {
        'fontSize': 12.0,
        'paddingH': 8.0,
        'paddingV': 3.0,
        'radius': 5.0,
        'spacing': 12.0,
      };
    }
  }
}
