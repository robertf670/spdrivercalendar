import 'package:flutter/foundation.dart';

/// Owns the first narrow slice of calendar view state.
///
/// Settings, holidays, duty editing, and integrations intentionally remain
/// outside this controller during the incremental Provider migration.
class CalendarController extends ChangeNotifier {
  CalendarController({
    required DateTime initialFocusedDay,
    DateTime? initialSelectedDay,
    bool initiallyLoading = false,
  })  : _focusedDay = initialFocusedDay,
        _selectedDay = initialSelectedDay,
        _isVisibleMonthLoading = initiallyLoading;

  DateTime? _selectedDay;
  DateTime _focusedDay;
  bool _isVisibleMonthLoading;

  DateTime? get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  bool get isVisibleMonthLoading => _isVisibleMonthLoading;

  void selectDay(DateTime? selectedDay, {DateTime? focusedDay}) {
    final nextFocusedDay = focusedDay ?? _focusedDay;
    if (_selectedDay == selectedDay && _focusedDay == nextFocusedDay) return;

    _selectedDay = selectedDay;
    _focusedDay = nextFocusedDay;
    notifyListeners();
  }

  void setFocusedDay(DateTime focusedDay) {
    if (_focusedDay == focusedDay) return;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void setVisibleMonthLoading(bool isLoading) {
    if (_isVisibleMonthLoading == isLoading) return;
    _isVisibleMonthLoading = isLoading;
    notifyListeners();
  }

  void beginVisibleMonthLoad(DateTime focusedDay) {
    if (_focusedDay == focusedDay && _isVisibleMonthLoading) return;
    _focusedDay = focusedDay;
    _isVisibleMonthLoading = true;
    notifyListeners();
  }
}
