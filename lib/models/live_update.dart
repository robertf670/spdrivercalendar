import 'package:cloud_firestore/cloud_firestore.dart';

// Data model for live updates and polls
class LiveUpdate {
  final String id;
  final String title;
  final String description;
  final String priority; // 'critical', 'warning', 'info' (for updates only)
  final DateTime startTime;
  final DateTime endTime;
  final List<String> routesAffected;
  final bool forceVisible; // Show immediately regardless of start time (for updates only)
  final bool enableScheduledVisibility; // Enable scheduled visibility feature (for updates only)
  final int hoursBeforeStart; // Hours before startTime to display (0 = at start time) (for updates only)
  
  // Poll-specific fields
  final String type; // 'update' or 'poll'
  final List<String>? pollOptions; // Poll options (null for updates)
  final String? voteVisibility; // 'always', 'after_vote', 'after_end', 'never' (for polls only)
  final List<int>? voteCounts; // Vote counts matching pollOptions length (for polls only)
  final int? totalVotes; // Total votes cast (for polls only)
  final DateTime? resultsVisibleUntil; // When to stop showing results after poll ends (for polls only)

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
    this.type = 'update',
    this.pollOptions,
    this.voteVisibility,
    this.voteCounts,
    this.totalVotes,
    this.resultsVisibleUntil,
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
    String? type,
    List<String>? pollOptions,
    String? voteVisibility,
    List<int>? voteCounts,
    int? totalVotes,
    DateTime? resultsVisibleUntil,
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
      type: type ?? this.type,
      pollOptions: pollOptions ?? this.pollOptions,
      voteVisibility: voteVisibility ?? this.voteVisibility,
      voteCounts: voteCounts ?? this.voteCounts,
      totalVotes: totalVotes ?? this.totalVotes,
      resultsVisibleUntil: resultsVisibleUntil ?? this.resultsVisibleUntil,
    );
  }
  
  /// Check if this is a poll
  bool get isPoll => type == 'poll';
  
  /// Check if this is an update
  bool get isUpdate => type == 'update';

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
      'type': type,
      'pollOptions': pollOptions,
      'voteVisibility': voteVisibility,
      'voteCounts': voteCounts,
      'totalVotes': totalVotes,
      'resultsVisibleUntil': resultsVisibleUntil?.toIso8601String(),
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
      type: json['type'] ?? 'update',
      pollOptions: json['pollOptions'] != null ? List<String>.from(json['pollOptions']) : null,
      voteVisibility: json['voteVisibility'],
      voteCounts: json['voteCounts'] != null ? List<int>.from(json['voteCounts']) : null,
      totalVotes: json['totalVotes'],
      resultsVisibleUntil: json['resultsVisibleUntil'] != null ? DateTime.parse(json['resultsVisibleUntil']) : null,
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
      type: data['type'] ?? 'update',
      pollOptions: data['pollOptions'] != null ? List<String>.from(data['pollOptions']) : null,
      voteVisibility: data['voteVisibility'],
      voteCounts: data['voteCounts'] != null ? List<int>.from(data['voteCounts']) : null,
      totalVotes: data['totalVotes'],
      resultsVisibleUntil: data['resultsVisibleUntil'] != null ? (data['resultsVisibleUntil'] as Timestamp).toDate() : null,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    final map = {
      'title': title,
      'description': description,
      'priority': priority,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'routesAffected': routesAffected,
      'forceVisible': forceVisible,
      'enableScheduledVisibility': enableScheduledVisibility,
      'hoursBeforeStart': hoursBeforeStart,
      'type': type,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
    
    // Add poll-specific fields if this is a poll
    if (isPoll) {
      map['pollOptions'] = pollOptions ?? [];
      map['voteVisibility'] = voteVisibility ?? 'always';
      map['voteCounts'] = voteCounts ?? List.filled(pollOptions?.length ?? 0, 0);
      map['totalVotes'] = totalVotes ?? 0;
      if (resultsVisibleUntil != null) {
        map['resultsVisibleUntil'] = Timestamp.fromDate(resultsVisibleUntil!);
      }
    }
    
    return map;
  }

  /// Check if this update/poll is currently active
  bool get isActive {
    final now = DateTime.now();
    
    // For polls, simple time-based check
    if (isPoll) {
      return now.isAfter(startTime) && now.isBefore(endTime);
    }
    
    // For updates, calculate scheduled visibility time if enabled
    DateTime effectiveStartTime = startTime;
    if (enableScheduledVisibility && hoursBeforeStart > 0) {
      effectiveStartTime = startTime.subtract(Duration(hours: hoursBeforeStart));
    }
    
    // Show if force visible is enabled and before end time, OR 
    // during scheduled time window (which may be before actual start time)
    return (forceVisible && now.isBefore(endTime)) ||
           (now.isAfter(effectiveStartTime) && now.isBefore(endTime));
  }
  
  /// Check if poll should be shown (active or within results window)
  bool get shouldShowPoll {
    if (!isPoll) return false;
    final now = DateTime.now();
    
    // Show if active
    if (isActive) return true;
    
    // Show if ended but within results window
    if (resultsVisibleUntil != null && now.isBefore(resultsVisibleUntil!)) {
      return true;
    }
    
    return false;
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