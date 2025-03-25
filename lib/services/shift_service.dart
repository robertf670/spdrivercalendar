import 'package:spdrivercalendar/models/work_shift.dart';
// Import any local storage solution you use (SharedPreferences, Hive, SQLite, etc.)

class ShiftService {
  // List to store shifts in memory (replace with actual database implementation)
  static List<WorkShift> _shifts = [];

  // Get all shifts
  static List<WorkShift> getAllShifts() {
    return [..._shifts]; // Return a copy of the list
  }

  // Save a shift
  static Future<void> saveShift(WorkShift shift) async {
    // Add to in-memory list
    _shifts.add(shift);
    
    // TODO: Implement actual persistence (database, shared preferences, etc.)
    // For example:
    // await _database.insert('shifts', shift.toMap());
    
    print('Shift saved: ${shift.title}');
  }

  // Get shift by ID
  static WorkShift? getShiftById(String id) {
    try {
      return _shifts.firstWhere((shift) => shift.id == id);
    } catch (e) {
      return null;
    }
  }

  // Delete shift
  static Future<bool> deleteShift(String id) async {
    try {
      _shifts.removeWhere((shift) => shift.id == id);
      
      // TODO: Implement actual deletion from persistence
      // For example:
      // await _database.delete('shifts', where: 'id = ?', whereArgs: [id]);
      
      return true;
    } catch (e) {
      print('Error deleting shift: $e');
      return false;
    }
  }
}
