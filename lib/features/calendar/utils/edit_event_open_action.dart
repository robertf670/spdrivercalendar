import 'package:spdrivercalendar/models/event.dart';

/// What the calendar screen should do when [editEvent] is invoked.
enum EditEventOpenAction {
  /// Preload/refresh the selected month (refresh_trigger events).
  refreshMonth,

  /// Spare duty update that only needs a local rebuild.
  refreshSpareInPlace,

  /// Open the edit-event dialog.
  openDialog,
}

/// Resolves edit-entry behaviour without UI side effects.
EditEventOpenAction resolveEditEventOpenAction(Event event) {
  if (event.id == 'refresh_trigger' ||
      event.id.startsWith('refresh_trigger_')) {
    return EditEventOpenAction.refreshMonth;
  }

  // Preserve prior spare short-circuit (assignedDuties or SP title).
  if (event.title.startsWith('SP') &&
      (event.assignedDuties != null || event.title.contains('SP'))) {
    return EditEventOpenAction.refreshSpareInPlace;
  }

  return EditEventOpenAction.openDialog;
}
