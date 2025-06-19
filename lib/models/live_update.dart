import 'package:cloud_firestore/cloud_firestore.dart';

// Data model for live updates
class LiveUpdate {
  final String id;
  final String title;
  final String description;
  final String priority; // 'critical', 'warning', 'info'
  final DateTime startTime;
  final DateTime endTime;
  final List<String> routesAffected;
  final bool forceVisible; // Show immediately regardless of start time
  final bool enableScheduledVisibility; // Enable scheduled visibility feature
  final int hoursBeforeStart; // Hours before startTime to display (0 = at start time)

  LiveUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.startTime,
    required this.endTime,
    required this.routesAffected,
    this.forceVisible = false,
    this.enableScheduledVisibility = false,
    this.hoursBeforeStart = 0,
  });

  LiveUpdate copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? routesAffected,
    bool? forceVisible,
    bool? enableScheduledVisibility,
    int? hoursBeforeStart,
  }) {
    return LiveUpdate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      routesAffected: routesAffected ?? this.routesAffected,
      forceVisible: forceVisible ?? this.forceVisible,
      enableScheduledVisibility: enableScheduledVisibility ?? this.enableScheduledVisibility,
      hoursBeforeStart: hoursBeforeStart ?? this.hoursBeforeStart,
    );
  }

  /// Convert to JSON for local storage/backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'routesAffected': routesAffected,
      'forceVisible': forceVisible,
      'enableScheduledVisibility': enableScheduledVisibility,
      'hoursBeforeStart': hoursBeforeStart,
    };
  }

  /// Create from JSON for local storage/backup
  factory LiveUpdate.fromJson(Map<String, dynamic> json) {
    return LiveUpdate(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      routesAffected: List<String>.from(json['routesAffected'] ?? []),
      forceVisible: json['forceVisible'] ?? false,
      enableScheduledVisibility: json['enableScheduledVisibility'] ?? false,
      hoursBeforeStart: json['hoursBeforeStart'] ?? 0,
    );
  }

  /// Create from Firestore document
  factory LiveUpdate.fromFirestore(String documentId, Map<String, dynamic> data) {
    return LiveUpdate(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'info',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      routesAffected: List<String>.from(data['routesAffected'] ?? []),
      forceVisible: data['forceVisible'] ?? false,
      enableScheduledVisibility: data['enableScheduledVisibility'] ?? false,
      hoursBeforeStart: data['hoursBeforeStart'] ?? 0,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'routesAffected': routesAffected,
      'forceVisible': forceVisible,
      'enableScheduledVisibility': enableScheduledVisibility,
      'hoursBeforeStart': hoursBeforeStart,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Check if this update is currently active
  bool get isActive {
    final now = DateTime.now();
    
    // Calculate scheduled visibility time if enabled
    DateTime effectiveStartTime = startTime;
    if (enableScheduledVisibility && hoursBeforeStart > 0) {
      effectiveStartTime = startTime.subtract(Duration(hours: hoursBeforeStart));
    }
    
    // Show if force visible is enabled and before end time, OR 
    // during scheduled time window (which may be before actual start time)
    return (forceVisible && now.isBefore(endTime)) ||
           (now.isAfter(effectiveStartTime) && now.isBefore(endTime));
  }

  /// Check if this update is scheduled for the future
  bool get isScheduled {
    return DateTime.now().isBefore(startTime);
  }

  /// Check if this update has expired
  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  /// Get status string for display
  String get status {
    if (isActive) return 'Active';
    if (isScheduled) return 'Scheduled';
    return 'Expired';
  }

  /// Get the effective visibility start time (considering scheduled visibility)
  DateTime get effectiveStartTime {
    if (enableScheduledVisibility && hoursBeforeStart > 0) {
      return startTime.subtract(Duration(hours: hoursBeforeStart));
    }
    return startTime;
  }

  /// Check if this update is in scheduled visibility mode
  bool get isScheduledForEarlyVisibility {
    return enableScheduledVisibility && 
           hoursBeforeStart > 0 && 
           DateTime.now().isBefore(startTime) && 
           DateTime.now().isAfter(effectiveStartTime);
  }
} 