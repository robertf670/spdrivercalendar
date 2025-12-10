class UniversalBoard {
  final String shift;
  final String? duty;
  final List<BoardSection> sections;

  UniversalBoard({
    required this.shift,
    this.duty,
    required this.sections,
  });

  factory UniversalBoard.fromJson(Map<String, dynamic> json) {
    return UniversalBoard(
      shift: json['shift'] as String,
      duty: json['duty'] as String?,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((section) => BoardSection.fromJson(section as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BoardSection {
  final String type; // 'morning' or 'afternoon'
  final List<BoardEntry> entries;

  BoardSection({
    required this.type,
    required this.entries,
  });

  factory BoardSection.fromJson(Map<String, dynamic> json) {
    return BoardSection(
      type: json['type'] as String,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((entry) => BoardEntry.fromJson(entry as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BoardEntry {
  final String action;
  final String? time;
  final String? location;
  final String? route;
  final String? notes;

  BoardEntry({
    required this.action,
    this.time,
    this.location,
    this.route,
    this.notes,
  });

  factory BoardEntry.fromJson(Map<String, dynamic> json) {
    return BoardEntry(
      action: json['action'] as String,
      time: json['time'] as String?,
      location: json['location'] as String?,
      route: json['route'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

