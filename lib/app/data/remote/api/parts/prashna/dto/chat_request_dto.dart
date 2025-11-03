import 'package:json_annotation/json_annotation.dart';

part 'chat_request_dto.g.dart';

/// Request DTO for chat API calls
@JsonSerializable()
class ChatRequestDto {
  final String message;
  @JsonKey(name: 'session_id')
  final String sessionId;

  const ChatRequestDto({
    required this.message,
    required this.sessionId,
  });

  factory ChatRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ChatRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRequestDtoToJson(this);
}

/// Response DTO for SSE events
@JsonSerializable()
class SseEventDto {
  final String content;
  final String event;

  const SseEventDto({
    required this.content,
    required this.event,
  });

  factory SseEventDto.fromJson(Map<String, dynamic> json) =>
      _$SseEventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SseEventDtoToJson(this);
}

/// Tool parameters DTO for LangGraph events
@JsonSerializable()
class ToolParametersDto {
  @JsonKey(name: 'tool_name')
  final String toolName;
  @JsonKey(name: 'tool_args')
  final Map<String, dynamic> toolArgs;

  const ToolParametersDto({
    required this.toolName,
    required this.toolArgs,
  });

  factory ToolParametersDto.fromJson(Map<String, dynamic> json) =>
      _$ToolParametersDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ToolParametersDtoToJson(this);
}




