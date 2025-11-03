import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';

class PrashnaCubitState {
  final bool isInitialized;
  final bool isLoading;
  final bool isStreaming;
  final String? currentMessage;
  final AiModel selectedAiModel;
  final ChatSession? currentSession;
  final List<ChatSession> chatHistory;
  final String? errorMessage;
  final String? currentStreamingMessageId;
  final String? currentTool;
  final bool showModelSelector;
  final String? lastSentMessage;
  final String? currentVisibleQuestion;
  final DateTime? lastQuestionTime;

  const PrashnaCubitState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isStreaming = false,
    this.currentMessage,
    this.selectedAiModel = AiModel.qwen, // GPT OSS as default
    this.currentSession,
    this.chatHistory = const [],
    this.errorMessage,
    this.currentStreamingMessageId,
    this.currentTool,
    this.showModelSelector = false,
    this.lastSentMessage,
    this.currentVisibleQuestion,
    this.lastQuestionTime,
  });

  PrashnaCubitState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isStreaming,
    String? currentMessage,
    AiModel? selectedAiModel,
    ChatSession? currentSession,
    List<ChatSession>? chatHistory,
    String? errorMessage,
    String? currentStreamingMessageId,
    String? currentTool,
    bool? showModelSelector,
    String? lastSentMessage,
    String? currentVisibleQuestion,
    DateTime? lastQuestionTime,
  }) {
    return PrashnaCubitState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      currentMessage: currentMessage ?? this.currentMessage,
      selectedAiModel: selectedAiModel ?? this.selectedAiModel,
      currentSession: currentSession ?? this.currentSession,
      chatHistory: chatHistory ?? this.chatHistory,
      errorMessage: errorMessage ?? this.errorMessage,
      currentStreamingMessageId: currentStreamingMessageId ?? this.currentStreamingMessageId,
      currentTool: currentTool ?? this.currentTool,
      showModelSelector: showModelSelector ?? this.showModelSelector,
      lastSentMessage: lastSentMessage ?? this.lastSentMessage,
      currentVisibleQuestion: currentVisibleQuestion ?? this.currentVisibleQuestion,
      lastQuestionTime: lastQuestionTime ?? this.lastQuestionTime,
    );
  }

  bool get hasMessages => currentSession?.hasMessages ?? false;
  bool get canSendMessage => !isStreaming && (currentMessage?.trim().isNotEmpty ?? false);
  List<ChatMessage> get messages => currentSession?.messages ?? [];
  String get sessionTitle => currentSession?.messages.isNotEmpty == true
      ? _truncateText(currentSession!.messages.first.content, 30)
      : 'New Chat';
  
  /// Get the display title for navbar - prioritize recent questions
  String get displayTitle {
    // If we just sent a question recently (within 3 seconds), prioritize lastSentMessage
    if (lastSentMessage != null && lastQuestionTime != null) {
      final timeSinceQuestion = DateTime.now().difference(lastQuestionTime!);
      if (timeSinceQuestion.inSeconds < 3) {
        return _truncateText(lastSentMessage!, 40);
      }
    }
    
    // Otherwise use currentVisibleQuestion or session title
    return currentVisibleQuestion != null
        ? _truncateText(currentVisibleQuestion!, 40)
        : sessionTitle;
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}

