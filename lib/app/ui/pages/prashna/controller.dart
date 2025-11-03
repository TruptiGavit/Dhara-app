import 'dart:async';

import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/prashna/repo.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/args.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class PrashnaController extends Cubit<PrashnaCubitState> {
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  // Performance timing measurements
  DateTime? _lastMessageSentTime;
  DateTime? _lastResponseStartTime;
  DateTime? _lastResponseCompleteTime;
  
  
  final PrashnaRepository _prashnaRepository;

  // Subscriptions
  StreamSubscription<ChatSession?>? _currentSessionSubscription;
  StreamSubscription<AiModel>? _aiModelSubscription;
  StreamSubscription<bool>? _isStreamingSubscription;
  StreamSubscription<List<ChatSession>>? _chatHistorySubscription;
  StreamSubscription<String?>? _streamingMessageSubscription;
  StreamSubscription<String?>? _currentToolSubscription;
  StreamSubscription<String>? _errorSubscription;

  PrashnaController({
    required PrashnaRepository prashnaRepository,
  })  : _prashnaRepository = prashnaRepository,
        super(const PrashnaCubitState()) {
    _setupFormListener();
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions
    _currentSessionSubscription?.cancel();
    _aiModelSubscription?.cancel();
    _isStreamingSubscription?.cancel();
    _chatHistorySubscription?.cancel();
    _streamingMessageSubscription?.cancel();
    _currentToolSubscription?.cancel();
    _errorSubscription?.cancel();
    
    // Dispose controllers
    messageController.dispose();
    scrollController.dispose();
    
    return super.close();
  }

  Future<void> initData(PrashnaArgsRequest args) async {
    
    try {
      // Subscribe to repository streams FIRST
      _subscribeToRepository();
      
      // Sync current model from repository immediately
      final repositoryModel = _prashnaRepository.selectedAiModel;
      emit(state.copyWith(selectedAiModel: repositoryModel));
      
      // Initialize repository (this will create session and trigger model sync)
      _prashnaRepository.initData();
      
      // Handle initial message if provided
      if (args.initialMessage?.isNotEmpty == true) {
        messageController.text = args.initialMessage!;
        emit(state.copyWith(currentMessage: args.initialMessage));
      }
      
      // Switch to specific session if provided
      if (args.sessionId?.isNotEmpty == true) {
        _prashnaRepository.switchToSession(args.sessionId!);
      }
      
      emit(state.copyWith(isInitialized: true));
      
    } catch (e, stackTrace) {
      emit(state.copyWith(
        isInitialized: true,
        errorMessage: 'Failed to initialize chat: ${e.toString()}',
      ));
    }
  }

  void _setupFormListener() {
    messageController.addListener(() {
      final currentText = messageController.text;
      emit(state.copyWith(currentMessage: currentText));
    });
  }

  void _subscribeToRepository() {
    // Subscribe to current session changes
    _currentSessionSubscription = _prashnaRepository.currentSessionObservable.listen((session) {
      // 📊 TIMING: Check if this is a new AI response
      if (session?.messages.isNotEmpty == true && _lastMessageSentTime != null) {
        final lastMessage = session!.messages.last;
        if (!lastMessage.isUser && _lastResponseStartTime == null) {
          _lastResponseStartTime = DateTime.now();
          final responseLatency = _lastResponseStartTime!.difference(_lastMessageSentTime!).inMilliseconds;
          // Show performance logs in both debug and release mode for testing
          // Keep performance logs visible in release mode for monitoring
          print('📥 First response received (${responseLatency}ms latency)');
        }
      }
      
      emit(state.copyWith(
        currentSession: session,
      ));
      
      // Auto-scroll to bottom for new user messages
      if (session?.messages.isNotEmpty == true) {
        final lastMessage = session!.messages.last;
        if (lastMessage.isUser) {
          _scrollToBottom();
        }
      }
    });

    // Subscribe to AI model changes
    _aiModelSubscription = _prashnaRepository.selectedAiModelObservable.listen((aiModel) {
      emit(state.copyWith(selectedAiModel: aiModel));
    });

    // Subscribe to streaming status
    _isStreamingSubscription = _prashnaRepository.isStreamingObservable.listen((isStreaming) {
      final wasStreaming = state.isStreaming;
      emit(state.copyWith(
        isStreaming: isStreaming,
      ));
      
      // Scroll to bottom when streaming completes (not when it starts)
      if (wasStreaming && !isStreaming) {
        // 📊 TIMING: Record when streaming completes and UI is ready
        _lastResponseCompleteTime = DateTime.now();
        if (_lastMessageSentTime != null && _lastResponseStartTime != null) {
          final totalLatency = _lastResponseCompleteTime!.difference(_lastMessageSentTime!).inMilliseconds;
          final renderingTime = _lastResponseCompleteTime!.difference(_lastResponseStartTime!).inMilliseconds;
          // Show performance logs in both debug and release mode for testing
          // Keep performance summary visible for monitoring
          print('✅ Response complete: ${totalLatency}ms total (${renderingTime}ms render)');
          
          // Reset timers for next message
          _lastMessageSentTime = null;
          _lastResponseStartTime = null;
          _lastResponseCompleteTime = null;
        }
        
        // Scroll immediately after streaming completes - WidgetsBinding already ensures UI is ready
        _scrollToBottom();
      }
    });

    // Subscribe to chat history
    _chatHistorySubscription = _prashnaRepository.chatHistoryObservable.listen((history) {
      emit(state.copyWith(chatHistory: history));
    });

    // Subscribe to current streaming message
    _streamingMessageSubscription = _prashnaRepository.currentStreamingMessageIdObservable.listen((messageId) {
      emit(state.copyWith(currentStreamingMessageId: messageId));
    });

    // Subscribe to current tool
    _currentToolSubscription = _prashnaRepository.currentToolObservable.listen((toolName) {
      emit(state.copyWith(currentTool: toolName));
    });

    // Subscribe to errors
    _errorSubscription = _prashnaRepository.errorObservable.listen((error) {
      emit(state.copyWith(errorMessage: error));
    });

    // Subscribe to authentication changes
    // Note: Using mAccountCommonObservable as per existing pattern in other controllers
    // _authSubscription = _authAccountRepository.mAccountCommonObservable.listen((user) {
    //   // Handle authentication state changes if needed
    //   _logger.d('Auth state changed: ${user?.displayName ?? 'Not logged in'}');
    // });
  }

  // ===== USER ACTIONS =====

  /// Send a message
  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty || state.isStreaming) {
      return;
    }

    // 📊 TIMING: Record when message is sent
    _lastMessageSentTime = DateTime.now();
    // Show performance logs in both debug and release mode for testing
    // Keep send timing visible for monitoring
    print('🚀 Message sent');


    try {
      // Update navbar title immediately with the new question and timestamp
      final now = DateTime.now();
      emit(state.copyWith(
        currentVisibleQuestion: message,
        lastSentMessage: message,
        lastQuestionTime: now,
      ));

      // Send message through repository
      final result = await _prashnaRepository.sendMessage(message);
      
      // Clear input only after successful API call
      if (result.status == DomainResultStatus.SUCCESS) {
        messageController.clear();
        emit(state.copyWith(
          currentMessage: '',
        ));
      }
      
      if (result.status != DomainResultStatus.SUCCESS) {
        emit(state.copyWith(
          errorMessage: result.message ?? 'Failed to send message',
        ));
        
        // Restore message to input on error
        messageController.text = message;
        emit(state.copyWith(currentMessage: message));
      }
    } catch (e, stackTrace) {
      emit(state.copyWith(
        errorMessage: 'Failed to send message: ${e.toString()}',
      ));
      
      // Restore message to input on error
      messageController.text = message;
      emit(state.copyWith(currentMessage: message));
    }
  }

  /// Change AI model
  void changeAiModel(AiModel aiModel) {
    if (aiModel == state.selectedAiModel) return;
    
    _prashnaRepository.changeAiModel(aiModel);
    
    // Hide model selector
    emit(state.copyWith(showModelSelector: false));
  }

  /// Toggle model selector visibility
  void toggleModelSelector() {
    emit(state.copyWith(showModelSelector: !state.showModelSelector));
  }

  /// Create new chat session
  void createNewChat() {
    _prashnaRepository.createNewSession();
    
    // Clear current message and visible question
    messageController.clear();
    emit(state.copyWith(
      currentMessage: '',
      currentVisibleQuestion: null, // Clear the navbar question
    ));
  }

  /// Switch to a different chat session
  void switchToSession(String sessionId) {
    _prashnaRepository.switchToSession(sessionId);
    
    // Clear the current visible question when switching sessions
    emit(state.copyWith(currentVisibleQuestion: null));
  }

  /// Delete a chat session
  void deleteSession(String sessionId) {
    _prashnaRepository.deleteSession(sessionId);
  }

  /// Clear current session messages
  void clearCurrentSession() {
    _prashnaRepository.clearCurrentSession();
  }

  /// Cancel current streaming
  Future<void> cancelStreaming() async {
    await _prashnaRepository.cancelCurrentStream();
  }

  /// Handle form submission (Enter key)
  void onFormSubmitted() {
    sendMessage();
  }

  /// Handle message input changes
  void onMessageChanged(String value) {
    emit(state.copyWith(currentMessage: value));
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Update the current visible question based on scroll position (optimized)
  void updateCurrentVisibleQuestion(String? question) {
    // Don't override recently sent questions (within 3 seconds)
    if (state.lastQuestionTime != null) {
      final timeSinceQuestion = DateTime.now().difference(state.lastQuestionTime!);
      if (timeSinceQuestion.inSeconds < 3) {
        return;
      }
    }
    
    // Only emit if the value actually changed (prevents redundant rebuilds)
    if (state.currentVisibleQuestion != question) {
      emit(state.copyWith(currentVisibleQuestion: question));
    }
  }

  /// Copy message to clipboard
  Future<void> copyMessage(String content) async {
    try {
      // Safely truncate content for logging
      final truncatedContent = content.length > 50 
          ? '${content.substring(0, 50)}...' 
          : content;
      
      // The actual copying is handled in the widget via Clipboard.setData
      // This method is just for logging and potential additional logic
    } catch (e) {
    }
  }

  /// Share message
  Future<void> shareMessage(ChatMessage message) async {
    try {
      // Implementation will be added when we create the UI
    } catch (e) {
    }
  }

  /// Retry failed message
  Future<void> retryMessage(ChatMessage message) async {
    if (message.role == MessageRole.user) {
      messageController.text = message.content;
      emit(state.copyWith(currentMessage: message.content));
      await sendMessage();
    }
  }

  /// Auto-scroll to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Force scroll to bottom (for manual trigger)
  void scrollToBottom() {
    _scrollToBottom();
  }

  // ===== GETTERS =====

  bool get canSendMessage => state.canSendMessage;
  bool get hasMessages => state.hasMessages;
  bool get isStreaming => state.isStreaming;
  AiModel get selectedAiModel => state.selectedAiModel;
  List<ChatMessage> get messages => state.messages;
  List<ChatSession> get chatHistory => state.chatHistory;
  String? get errorMessage => state.errorMessage;
}
