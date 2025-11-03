import 'package:json_annotation/json_annotation.dart';

part 'execution_log.g.dart';

/// Types of execution events in the Prashna system
enum ExecutionEventType {
  @JsonValue('RunStarted')
  runStarted,
  
  @JsonValue('ToolCallStarted')
  toolCallStarted,
  
  @JsonValue('ToolCallCompleted')
  toolCallCompleted,
  
  @JsonValue('RunContent')
  runContent,
  
  @JsonValue('RunCompleted')
  runCompleted,
  
  @JsonValue('Unknown')
  unknown;

  String get displayName {
    switch (this) {
      case ExecutionEventType.runStarted:
        return 'Run Started';
      case ExecutionEventType.toolCallStarted:
        return 'Tool Call Started';
      case ExecutionEventType.toolCallCompleted:
        return 'Tool Call Completed';
      case ExecutionEventType.runContent:
        return 'Content Generation';
      case ExecutionEventType.runCompleted:
        return 'Run Completed';
      case ExecutionEventType.unknown:
        return 'Unknown Event';
    }
  }

  String get iconName {
    switch (this) {
      case ExecutionEventType.runStarted:
        return 'play_circle';
      case ExecutionEventType.toolCallStarted:
        return 'build_circle';
      case ExecutionEventType.toolCallCompleted:
        return 'check_circle';
      case ExecutionEventType.runContent:
        return 'edit';
      case ExecutionEventType.runCompleted:
        return 'done_all';
      case ExecutionEventType.unknown:
        return 'help';
    }
  }
}

/// Individual execution event with timing information
@JsonSerializable()
class ExecutionEvent {
  final ExecutionEventType event;
  final double time; // Time in seconds from start
  final String content;

  const ExecutionEvent({
    required this.event,
    required this.time,
    required this.content,
  });

  factory ExecutionEvent.fromJson(Map<String, dynamic> json) =>
      _$ExecutionEventFromJson(json);
  
  Map<String, dynamic> toJson() => _$ExecutionEventToJson(this);

  /// Get duration since previous event (requires previous event for calculation)
  double? getDurationSince(ExecutionEvent? previousEvent) {
    if (previousEvent == null) return null;
    return time - previousEvent.time;
  }

  /// Check if this is a tool-related event
  bool get isToolEvent => 
      event == ExecutionEventType.toolCallStarted || 
      event == ExecutionEventType.toolCallCompleted;

  /// Extract tool name from content (for tool events)
  String? get toolName {
    if (!isToolEvent) return null;
    
    final match = RegExp(r'(\w+)\(').firstMatch(content);
    return match?.group(1);
  }

  /// Extract completion duration for completed tool calls
  double? get toolDuration {
    if (event != ExecutionEventType.toolCallCompleted) return null;
    
    final match = RegExp(r'completed in ([\d.]+)s').firstMatch(content);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Format time as readable string (e.g., "2.4s", "15.2s")
  String get formattedTime => '${time.toStringAsFixed(1)}s';

  /// Get relative time description
  String getRelativeTimeDescription() {
    if (time < 1) return 'Immediate';
    if (time < 5) return 'Fast';
    if (time < 15) return 'Normal';
    return 'Slow';
  }
}

/// Complete execution log containing all events and metadata
@JsonSerializable()
class ExecutionLog {
  final String model; // AI model used (e.g., "gpt-oss:20b")
  final List<ExecutionEvent> events;

  const ExecutionLog({
    required this.model,
    required this.events,
  });

  factory ExecutionLog.fromJson(Map<String, dynamic> json) =>
      _$ExecutionLogFromJson(json);
  
  Map<String, dynamic> toJson() => _$ExecutionLogToJson(this);

  /// Get total execution time
  double get totalExecutionTime {
    if (events.isEmpty) return 0;
    return events.last.time;
  }

  /// Get all tool call events grouped by tool
  Map<String, List<ExecutionEvent>> get toolCallsByTool {
    final grouped = <String, List<ExecutionEvent>>{};
    
    for (final event in events) {
      if (event.isToolEvent && event.toolName != null) {
        final toolName = event.toolName!;
        grouped.putIfAbsent(toolName, () => []).add(event);
      }
    }
    
    return grouped;
  }

  /// Get performance summary
  ExecutionSummary get summary => ExecutionSummary(
    totalTime: totalExecutionTime,
    toolCalls: toolCallsByTool.length,
    model: model,
    events: events,
  );

  /// Find events by type
  List<ExecutionEvent> getEventsByType(ExecutionEventType type) {
    return events.where((event) => event.event == type).toList();
  }

  /// Get tool completion durations
  Map<String, double> get toolDurations {
    final durations = <String, double>{};
    
    for (final event in events) {
      if (event.event == ExecutionEventType.toolCallCompleted && 
          event.toolName != null && 
          event.toolDuration != null) {
        durations[event.toolName!] = event.toolDuration!;
      }
    }
    
    return durations;
  }
}

/// Summary of execution performance
class ExecutionSummary {
  final double totalTime;
  final int toolCalls;
  final String model;
  final List<ExecutionEvent> events;

  const ExecutionSummary({
    required this.totalTime,
    required this.toolCalls,
    required this.model,
    required this.events,
  });

  /// Get performance rating (Fast/Normal/Slow)
  String get performanceRating {
    if (totalTime < 10) return 'Fast';
    if (totalTime < 30) return 'Normal';
    return 'Slow';
  }

  /// Get the slowest tool
  String? get slowestTool {
    String? slowest;
    double maxDuration = 0;
    
    for (final event in events) {
      if (event.event == ExecutionEventType.toolCallCompleted && 
          event.toolDuration != null && 
          event.toolDuration! > maxDuration) {
        maxDuration = event.toolDuration!;
        slowest = event.toolName;
      }
    }
    
    return slowest;
  }
}