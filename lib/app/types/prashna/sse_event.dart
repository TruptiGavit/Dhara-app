import 'package:json_annotation/json_annotation.dart';

part 'sse_event.g.dart';

/// Base class for all SSE events received from the API
abstract class SseEvent {
  final String? content;
  final String event;

  const SseEvent({
    required this.content,
    required this.event,
  });

  factory SseEvent.fromJson(Map<String, dynamic> json) {
    final eventType = json['event'] as String;
    
    switch (eventType) {
      case 'ContentDelta':
        return ContentDeltaEvent.fromJson(json);
      case 'SessionID':
        return SessionIdEvent.fromJson(json);
      case 'RunStarted':
        return RunStartedEvent.fromJson(json);
      case 'ToolCallStarted':
        return ToolCallStartedEvent.fromJson(json);
      case 'ToolParameters':
        return ToolParametersEvent.fromJson(json);
      case 'ToolCallCompleted':
        return ToolCallCompletedEvent.fromJson(json);
      case 'RunContent':
        return RunContentEvent.fromJson(json);
      case 'EventData':
        return EventDataEvent.fromJson(json);
      default:
        return UnknownEvent.fromJson(json);
    }
  }
}

/// Content delta event from Gemini API
@JsonSerializable()
class ContentDeltaEvent extends SseEvent {
  const ContentDeltaEvent({
    required super.content,
    required super.event,
  });

  factory ContentDeltaEvent.fromJson(Map<String, dynamic> json) =>
      _$ContentDeltaEventFromJson(json);

  Map<String, dynamic> toJson() => _$ContentDeltaEventToJson(this);
}

/// Session ID event from LangGraph API
@JsonSerializable()
class SessionIdEvent extends SseEvent {
  const SessionIdEvent({
    required super.content,
    required super.event,
  });

  factory SessionIdEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionIdEventFromJson(json);

  Map<String, dynamic> toJson() => _$SessionIdEventToJson(this);
}

/// Run started event from LangGraph API
@JsonSerializable()
class RunStartedEvent extends SseEvent {
  const RunStartedEvent({
    required super.content,
    required super.event,
  });

  factory RunStartedEvent.fromJson(Map<String, dynamic> json) =>
      _$RunStartedEventFromJson(json);

  Map<String, dynamic> toJson() => _$RunStartedEventToJson(this);
}

/// Tool call started event from LangGraph API
@JsonSerializable()
class ToolCallStartedEvent extends SseEvent {
  const ToolCallStartedEvent({
    required super.content,
    required super.event,
  });

  factory ToolCallStartedEvent.fromJson(Map<String, dynamic> json) =>
      _$ToolCallStartedEventFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallStartedEventToJson(this);
}

/// Tool parameters event from LangGraph API
@JsonSerializable()
class ToolParametersEvent extends SseEvent {
  @JsonKey(name: 'content')
  final Map<String, dynamic> toolData;

  const ToolParametersEvent({
    required this.toolData,
    required super.event,
  }) : super(content: '');

  String get toolName => toolData['tool_name'] as String? ?? '';
  Map<String, dynamic> get toolArgs => toolData['tool_args'] as Map<String, dynamic>? ?? {};

  factory ToolParametersEvent.fromJson(Map<String, dynamic> json) =>
      _$ToolParametersEventFromJson(json);

  Map<String, dynamic> toJson() => _$ToolParametersEventToJson(this);
}

/// Tool call completed event from LangGraph API
@JsonSerializable()
class ToolCallCompletedEvent extends SseEvent {
  const ToolCallCompletedEvent({
    required super.content,
    required super.event,
  });

  factory ToolCallCompletedEvent.fromJson(Map<String, dynamic> json) =>
      _$ToolCallCompletedEventFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallCompletedEventToJson(this);
}

/// Run content event from LangGraph API
@JsonSerializable()
class RunContentEvent extends SseEvent {
  const RunContentEvent({
    required super.content,
    required super.event,
  });

  factory RunContentEvent.fromJson(Map<String, dynamic> json) =>
      _$RunContentEventFromJson(json);

  Map<String, dynamic> toJson() => _$RunContentEventToJson(this);
}

/// Event data with timing logs from backend
@JsonSerializable()
class EventDataEvent extends SseEvent {
  @JsonKey(name: 'content')
  final Map<String, dynamic> eventData;

  const EventDataEvent({
    required this.eventData,
    required super.event,
  }) : super(content: '');

  String get model => eventData['model'] as String? ?? '';
  List<Map<String, dynamic>> get events => 
      (eventData['events'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

  factory EventDataEvent.fromJson(Map<String, dynamic> json) =>
      _$EventDataEventFromJson(json);

  Map<String, dynamic> toJson() => _$EventDataEventToJson(this);
}

/// Unknown event type (fallback)
@JsonSerializable()
class UnknownEvent extends SseEvent {
  const UnknownEvent({
    required super.content,
    required super.event,
  });

  factory UnknownEvent.fromJson(Map<String, dynamic> json) =>
      _$UnknownEventFromJson(json);

  Map<String, dynamic> toJson() => _$UnknownEventToJson(this);
}

/// SSE event parsing result
class SseEventResult {
  final SseEvent? event;
  final String? error;
  final bool isComplete;

  const SseEventResult({
    this.event,
    this.error,
    this.isComplete = false,
  });

  bool get hasEvent => event != null;
  bool get hasError => error != null;
  bool get isSuccess => hasEvent && !hasError;
}




