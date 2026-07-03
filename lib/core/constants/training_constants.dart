/// Constants for user-defined custom training duties (event title: "Training").
class TrainingConstants {
  TrainingConstants._();

  /// Shift option in the Training zone add-shift dropdown.
  static const String customTrainingShiftOption = 'Custom';

  /// Event card title for custom training duties.
  static const String customTrainingTitle = 'Training';

  static const int maxDescriptionLength = 50;

  static const String customLocationOption = 'Other';

  static const List<String> presetLocations = [
    'Garage',
    'Training School',
    'Union',
    'Mentor',
  ];

  /// Resolves dropdown + optional custom text into a stored location string.
  static String? resolveLocation(String? selection, String customText) {
    if (selection == null || selection.isEmpty) {
      return null;
    }
    if (selection == customLocationOption) {
      final trimmed = customText.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return selection;
  }
}
