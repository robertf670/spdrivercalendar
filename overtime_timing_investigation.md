# Overtime Timing Display Issue - Investigation and Fix

## Problem
**Issue**: Overtime 1/57A showing as "12:22 B Walk" instead of "12:45 B Walk" (displaying report time instead of start time)

## Root Cause Analysis

### CSV Data Structure
Looking at `assets/M-F_DUTIES_PZ1.csv` for PZ1/57:
```csv
PZ1/57,007057,12:22:00,12:45:00,39A-BWALK,17:00:00,39A-BWALK,18:02:00,18:02:00,39-ASTONQ,21:50:00,39-ASTONQ,22:10:00,09:48:00,08:46:00
```

- **Index 2**: `12:22:00` = **Report Time** (when driver reports for duty) ❌ Currently used
- **Index 3**: `12:45:00` = **Start Time** (when actual work begins) ✅ Should be used for overtime
- **Index 4**: `39A-BWALK` = Location (displays as "B Walk")

### Code Issue
In `lib/features/calendar/screens/calendar_screen.dart`:

1. **`_getShiftTimes()` function** (lines 1095, 1123): Always used index 2 (report time) for ALL shifts
2. **Overtime creation logic** (line 4748): Called `_getShiftTimes()` without indicating it was for overtime
3. **Display logic**: Used the returned time directly, showing report time instead of start time

### Overtime vs Regular Shifts
- **Regular shifts**: Should show **report time** (when to report for duty)
- **Overtime shifts**: Should show **start time** (when work actually begins)
- **Overtime identification**: Title contains `(OT)` suffix (e.g., "PZ1/57A (OT)")

## Solution Implemented

### 1. Enhanced `_getShiftTimes()` Function
**File**: `lib/features/calendar/screens/calendar_screen.dart`

Added optional `isOvertimeShift` parameter:
```dart
Future<Map<String, dynamic>?> _getShiftTimes(String zone, String shiftNumber, DateTime shiftDate, {bool isOvertimeShift = false}) async
```

### 2. Updated CSV Parsing Logic
For both Jamestown and Regular Zone formats:

**Before** (Report time only):
```dart
final startTime = _parseTimeOfDay(parts[2].trim()); // Report time
```

**After** (Conditional based on shift type):
```dart
// For overtime shifts, use start time (depart time) instead of report time
final startTime = isOvertimeShift 
    ? _parseTimeOfDay(parts[3].trim()) // Depart time for overtime
    : _parseTimeOfDay(parts[2].trim()); // Report time for regular shifts
```

### 3. Updated Overtime Creation Call
**File**: Line 4748

**Before**:
```dart
shiftTimes = await _getShiftTimes(
  selectedZone.replaceAll('Zone ', ''),
  selectedShiftNumber,
  shiftDate,
);
```

**After**:
```dart
shiftTimes = await _getShiftTimes(
  selectedZone.replaceAll('Zone ', ''),
  selectedShiftNumber,
  shiftDate,
  isOvertimeShift: true, // Pass overtime flag
);
```

## Result
- **Before Fix**: "Overtime 1/57A" displayed "12:22 B Walk" (report time)
- **After Fix**: "Overtime 1/57A" displays "12:45 B Walk" (start time)
- **Regular shifts**: Continue to display report time correctly
- **Backward compatibility**: All existing functionality preserved

## Confirmation: Overtime-Only Issue
✅ **Confirmed**: This issue only affects overtime shifts  
✅ **Regular shifts**: Continue to correctly display report time  
✅ **Bus Check/UNI/Euro shifts**: Unaffected (different parsing logic)  
✅ **Jamestown shifts**: Also fixed for potential overtime usage