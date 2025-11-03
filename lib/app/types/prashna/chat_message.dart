import 'package:json_annotation/json_annotation.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/execution_log.dart';

part 'chat_message.g.dart';

/// Enum for message roles
enum MessageRole {
  @JsonValue('user')
  user,
  
  @JsonValue('assistant')
  assistant;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'Dhara Assistant';
    }
  }
}

/// Enum for message status
enum MessageStatus {
  @JsonValue('sending')
  sending,
  
  @JsonValue('streaming')
  streaming,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('error')
  error,
  
  @JsonValue('cancelled')
  cancelled;
}

/// Source citation information
@JsonSerializable()
class SourceCitation {
  final int id;
  final String type; // 'chunk', 'verse', 'defn'
  final String? text;
  final String? reference;
  final String? url;

  const SourceCitation({
    required this.id,
    required this.type,
    this.text,
    this.reference,
    this.url,
  });

  factory SourceCitation.fromJson(Map<String, dynamic> json) =>
      _$SourceCitationFromJson(json);

  Map<String, dynamic> toJson() => _$SourceCitationToJson(this);
}

/// Tool call information for tracking AI tool usage
@JsonSerializable()
class ToolCall {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime startTime;
  final DateTime? endTime;
  final String? result;

  const ToolCall({
    required this.name,
    required this.parameters,
    required this.startTime,
    this.endTime,
    this.result,
  });

  bool get isCompleted => endTime != null;
  
  Duration get duration => 
      endTime?.difference(startTime) ?? Duration.zero;

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);

  ToolCall copyWith({
    String? name,
    Map<String, dynamic>? parameters,
    DateTime? startTime,
    DateTime? endTime,
    String? result,
  }) {
    return ToolCall(
      name: name ?? this.name,
      parameters: parameters ?? this.parameters,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      result: result ?? this.result,
    );
  }
}

/// Main chat message model
@JsonSerializable()
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final String? rawContent; // Original content before citation processing
  final MessageStatus status;
  final DateTime timestamp;
  final AiModel? aiModel; // Only for assistant messages
  final String? sessionId;
  final List<SourceCitation> citations;
  final List<ToolCall> toolCalls;
  final String? errorMessage;
  final ExecutionLog? executionLog;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.rawContent,
    required this.status,
    required this.timestamp,
    this.aiModel,
    this.sessionId,
    this.citations = const [],
    this.toolCalls = const [],
    this.errorMessage,
    this.executionLog,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// Create a user message
  factory ChatMessage.user({
    required String content,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      status: MessageStatus.completed,
      timestamp: DateTime.now(),
    );
  }

  /// Create an assistant message
  factory ChatMessage.assistant({
    required String content,
    required AiModel aiModel,
    String? id,
    String? sessionId,
    MessageStatus status = MessageStatus.streaming,
    List<SourceCitation> citations = const [],
    List<ToolCall> toolCalls = const [],
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      status: status,
      timestamp: DateTime.now(),
      aiModel: aiModel,
      sessionId: sessionId,
      citations: citations,
      toolCalls: toolCalls,
    );
  }

  /// Create an error message
  factory ChatMessage.error({
    required String errorMessage,
    AiModel? aiModel,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: 'Sorry, I encountered an error while processing your request.',
      status: MessageStatus.error,
      timestamp: DateTime.now(),
      aiModel: aiModel,
      errorMessage: errorMessage,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isCompleted => status == MessageStatus.completed;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get hasError => status == MessageStatus.error;
  bool get hasCitations => citations.isNotEmpty;
  bool get hasToolCalls => toolCalls.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    String? rawContent,
    MessageStatus? status,
    DateTime? timestamp,
    AiModel? aiModel,
    String? sessionId,
    List<SourceCitation>? citations,
    List<ToolCall>? toolCalls,
    String? errorMessage,
    ExecutionLog? executionLog,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      rawContent: rawContent ?? this.rawContent,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      aiModel: aiModel ?? this.aiModel,
      sessionId: sessionId ?? this.sessionId,
      citations: citations ?? this.citations,
      toolCalls: toolCalls ?? this.toolCalls,
      errorMessage: errorMessage ?? this.errorMessage,
      executionLog: executionLog ?? this.executionLog,
    );
  }

  /// Add content to the message (for streaming)
  ChatMessage appendContent(String newContent) {
    return copyWith(
      content: content + newContent,
    );
  }

  /// Mark message as completed
  ChatMessage markCompleted() {
    return copyWith(status: MessageStatus.completed);
  }

  /// Mark message as error
  ChatMessage markError(String error) {
    return copyWith(
      status: MessageStatus.error,
      errorMessage: error,
    );
  }

  /// Add citation to the message
  ChatMessage addCitation(SourceCitation citation) {
    final newCitations = List<SourceCitation>.from(citations)..add(citation);
    return copyWith(citations: newCitations);
  }

  /// Add multiple source citations to the message
  ChatMessage addSourceCitations(List<SourceCitation> newCitations) {
    final allCitations = List<SourceCitation>.from(citations)..addAll(newCitations);
    return copyWith(citations: allCitations);
  }

  /// Add tool call to the message
  ChatMessage addToolCall(ToolCall toolCall) {
    final newToolCalls = List<ToolCall>.from(toolCalls)..add(toolCall);
    return copyWith(toolCalls: newToolCalls);
  }

  /// Update tool call with completion info
  ChatMessage updateToolCall(String toolName, {DateTime? endTime, String? result}) {
    final updatedToolCalls = toolCalls.map((tc) {
      if (tc.name == toolName && !tc.isCompleted) {
        return tc.copyWith(endTime: endTime, result: result);
      }
      return tc;
    }).toList();
    
    return copyWith(toolCalls: updatedToolCalls);
  }
}

/// Chat session model
@JsonSerializable()
class ChatSession {
  final String id;
  final AiModel aiModel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final bool isActive;

  const ChatSession({
    required this.id,
    required this.aiModel,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.isActive = true,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);

  /// Create a new chat session
  factory ChatSession.create({
    required AiModel aiModel,
    String? id,
  }) {
    final now = DateTime.now();
    return ChatSession(
      // Use temporary ID - backend will provide the real session ID via SessionID event
      id: id ?? 'temp_${now.millisecondsSinceEpoch}',
      aiModel: aiModel,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  bool get isEmpty => messages.isEmpty;
  bool get hasMessages => messages.isNotEmpty;
  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
  
  int get messageCount => messages.length;
  int get userMessageCount => messages.where((m) => m.isUser).length;
  int get assistantMessageCount => messages.where((m) => m.isAssistant).length;

  ChatSession copyWith({
    String? id,
    AiModel? aiModel,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    bool? isActive,
  }) {
    return ChatSession(
      id: id ?? this.id,
      aiModel: aiModel ?? this.aiModel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Add a message to the session
  ChatSession addMessage(ChatMessage message) {
    final newMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Update a message in the session
  ChatSession updateMessage(String messageId, ChatMessage updatedMessage) {
    final newMessages = messages.map((m) {
      return m.id == messageId ? updatedMessage : m;
    }).toList();
    
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a message from the session
  ChatSession removeMessage(String messageId) {
    final newMessages = messages.where((m) => m.id != messageId).toList();
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Clear all messages
  ChatSession clearMessages() {
    return copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );
  }
}


