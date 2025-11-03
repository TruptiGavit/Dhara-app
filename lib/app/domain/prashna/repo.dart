import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:dharak_flutter/app/data/remote/api/parts/prashna/api.dart';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';

import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/types/prashna/execution_log.dart';
import 'package:dharak_flutter/app/types/prashna/sse_event.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class PrashnaRepository {
  final Logger _logger = Logger();
  final PrashnaApiRepo _prashnaApiRepo;

  // ===== CHAT SESSION MANAGEMENT =====
  final BehaviorSubject<ChatSession?> _currentSessionSubject = BehaviorSubject.seeded(null);
  BehaviorSubject<ChatSession?> get currentSessionObservable => _currentSessionSubject;

  final BehaviorSubject<AiModel> _selectedAiModelSubject = BehaviorSubject.seeded(AiModel.qwen); // GPT OSS as default
  BehaviorSubject<AiModel> get selectedAiModelObservable => _selectedAiModelSubject;

  final BehaviorSubject<bool> _isStreamingSubject = BehaviorSubject.seeded(false);
  BehaviorSubject<bool> get isStreamingObservable => _isStreamingSubject;

  // ===== CACHE FOR PERSISTENT CHAT HISTORY =====
  final BehaviorSubject<List<ChatSession>> _chatHistorySubject = BehaviorSubject.seeded([]);
  BehaviorSubject<List<ChatSession>> get chatHistoryObservable => _chatHistorySubject;

  final BehaviorSubject<String?> _currentStreamingMessageIdSubject = BehaviorSubject.seeded(null);
  BehaviorSubject<String?> get currentStreamingMessageIdObservable => _currentStreamingMessageIdSubject;

  // ===== CURRENT TOOL TRACKING =====
  final BehaviorSubject<String?> _currentToolSubject = BehaviorSubject.seeded(null);
  BehaviorSubject<String?> get currentToolObservable => _currentToolSubject;

  // ===== ERROR HANDLING =====
  final PublishSubject<String> _errorSubject = PublishSubject<String>();
  PublishSubject<String> get errorObservable => _errorSubject;

  // ===== CURRENT STREAMING CANCELLATION =====
  StreamSubscription<SseEventResult>? _currentStreamSubscription;

  PrashnaRepository({
    required PrashnaApiRepo prashnaApiRepo,
  }) : _prashnaApiRepo = prashnaApiRepo;

  void dispose() {
    _currentSessionSubject.close();
    _selectedAiModelSubject.close();
    _isStreamingSubject.close();
    _chatHistorySubject.close();
    _currentStreamingMessageIdSubject.close();
    _currentToolSubject.close();
    _errorSubject.close();
    _currentStreamSubscription?.cancel();
  }

  void initData() {
    // Listen to developer mode model changes if authenticated
    if (DeveloperModeService.instance.isAuthenticated) {
      DeveloperModeService.instance.preferredModelStream.listen((model) {
        if (kDebugMode) _logger.d('🔧 Developer mode preferred model changed to: ${model.displayName}');
        _selectedAiModelSubject.sink.add(model);
      });
    }
    
    // Start with a new session if none exists
    if (_currentSessionSubject.value == null) {
      createNewSession();
    }
  }
  
  /// Get the effective AI model (considers developer mode preferences)
  AiModel _getEffectiveAiModel() {
    if (DeveloperModeService.instance.isAuthenticated) {
      return DeveloperModeService.instance.preferredModel;
    }
    return _selectedAiModelSubject.value;
  }

  // ===== SESSION MANAGEMENT =====

  /// Create a new chat session
  ChatSession createNewSession({AiModel? aiModel}) {
    final model = aiModel ?? _getEffectiveAiModel();
    if (kDebugMode) _logger.d('🎯 Creating new session with model: ${model.displayName}');
    final session = ChatSession.create(aiModel: model);
    
    _currentSessionSubject.sink.add(session);
    _addToHistory(session);
    

    return session;
  }

  /// Switch to an existing session
  void switchToSession(String sessionId) {
    final history = _chatHistorySubject.value;
    final session = history.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => createNewSession(),
    );
    
    _currentSessionSubject.sink.add(session);
    _selectedAiModelSubject.sink.add(session.aiModel);
    
    
  }

  /// Change AI model (creates new session)
  void changeAiModel(AiModel aiModel) {
    _selectedAiModelSubject.sink.add(aiModel);
    
    // Create new session with the selected model
    createNewSession(aiModel: aiModel);
    

  }

  /// Clear current session messages
  void clearCurrentSession() {
    final currentSession = _currentSessionSubject.value;
    if (currentSession != null) {
      final clearedSession = currentSession.clearMessages();
      _currentSessionSubject.sink.add(clearedSession);
      _updateInHistory(clearedSession);
    }
  }

  /// Delete a session
  void deleteSession(String sessionId) {
    final currentHistory = _chatHistorySubject.value;
    final updatedHistory = currentHistory.where((s) => s.id != sessionId).toList();
    _chatHistorySubject.sink.add(updatedHistory);
    
    // If deleted session was current, create new one
    if (_currentSessionSubject.value?.id == sessionId) {
      createNewSession();
    }
    
    
  }

  // ===== CHAT FUNCTIONALITY =====

  /// Send a message and get streaming response
  Future<DomainResult<bool>> sendMessage(String message) async {
    _logger.d('🔧 SEND MESSAGE DEBUG: sendMessage called with: "$message"');
    try {
      final currentSession = _currentSessionSubject.value;
      if (currentSession == null) {
        return DomainResult.error(message: 'No active chat session');
      }

      // Cancel any ongoing stream
      _logger.d('🔧 SEND MESSAGE DEBUG: Cancelling any ongoing stream');
      await _cancelCurrentStream();
      
      // Clear any lingering tool state from previous sessions
      _currentToolSubject.sink.add(null);
      
      _logger.d('🔧 SEND MESSAGE DEBUG: Cancelled ongoing stream, proceeding with new message');

      // Add user message to session
      final userMessage = ChatMessage.user(content: message);
      final updatedSession = currentSession.addMessage(userMessage);
      _currentSessionSubject.sink.add(updatedSession);
      _updateInHistory(updatedSession);

      // Create assistant message placeholder
      final assistantMessageId = _generateMessageId();
      final assistantMessage = ChatMessage.assistant(
        content: '',
        aiModel: currentSession.aiModel,
        sessionId: currentSession.id,
        id: assistantMessageId,
        status: MessageStatus.streaming,
      );

      final sessionWithAssistant = updatedSession.addMessage(assistantMessage);
      _currentSessionSubject.sink.add(sessionWithAssistant);
      _updateInHistory(sessionWithAssistant);

      // Start streaming
      _logger.d('🔧 STREAMING DEBUG: Setting isStreaming = true');
      _isStreamingSubject.sink.add(true);
      _currentStreamingMessageIdSubject.sink.add(assistantMessageId);

      // Generate session ID for API if needed
      final apiSessionId = currentSession.id;

      // Start SSE stream - use the selected model for the session
      final apiModel = currentSession.aiModel;
      if (kDebugMode) _logger.d('🎯 Sending message with model: ${apiModel.displayName} (${apiModel.modelParameter})');
      
      _logger.d('🔧 SSE DEBUG: Starting SSE stream subscription');
      _currentStreamSubscription = _prashnaApiRepo.sendChatMessage(
        message: message,
        sessionId: apiSessionId,
        aiModel: apiModel,
      ).listen(
        (result) {
          _logger.d('🔧 SSE DEBUG: Received SSE event - handling...');
          _handleSseEvent(result, assistantMessageId);
        },
        onDone: () {
          _logger.d('🔧 SSE DEBUG: SSE stream completed');
          _handleStreamComplete(assistantMessageId);
        },
        onError: (error) {
          _logger.d('🔧 SSE DEBUG: SSE stream error: $error');
          _handleStreamError(error, assistantMessageId);
        },
      );
      _logger.d('🔧 SSE DEBUG: SSE stream subscription created successfully');

      return DomainResult.success(data: true);
    } catch (e, stackTrace) {
      _logger.e('Error sending message', error: e, stackTrace: stackTrace);
      _errorSubject.sink.add(e.toString());
      _isStreamingSubject.sink.add(false);
      _currentStreamingMessageIdSubject.sink.add(null);
      return DomainResult.error(message: e.toString());
    }
  }

  /// Cancel current streaming
  Future<void> cancelCurrentStream() async {
    await _cancelCurrentStream();
  }

  Future<void> _cancelCurrentStream() async {
    _logger.d('🔧 CANCEL STREAM DEBUG: _cancelCurrentStream called');
    await _currentStreamSubscription?.cancel();
    _currentStreamSubscription = null;
    _logger.d('🔧 CANCEL STREAM DEBUG: Setting isStreaming = false (cancelling previous stream)');
    _isStreamingSubject.sink.add(false);
    
    final messageId = _currentStreamingMessageIdSubject.value;
    if (messageId != null) {
      _updateMessageStatus(messageId, MessageStatus.cancelled);
      _currentStreamingMessageIdSubject.sink.add(null);
    }
  }

  // ===== SSE EVENT HANDLING =====

  void _handleSseEvent(SseEventResult result, String messageId) {
    try {
      if (result.hasError) {
        _handleStreamError(result.error!, messageId);
        return;
      }

      if (result.isComplete) {
        _handleStreamComplete(messageId);
        return;
      }

      final event = result.event;
      if (event == null) return;
      
      // Debug: Log what events we're actually receiving
      _logger.d('🔧 SSE EVENT DEBUG: Received ${event.runtimeType} with content: "${event.content ?? "null"}"');

      final currentSession = _currentSessionSubject.value;
      if (currentSession == null) return;

      // Find the message to update
      final messageIndex = currentSession.messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) return;

      final currentMessage = currentSession.messages[messageIndex];
      ChatMessage? updatedMessage;

      // Handle different event types
      if (event is ContentDeltaEvent || event is RunContentEvent) {
        // Clear tool message when we have accumulated a reasonable amount of content
        // This ensures the tool message is visible long enough for users to read
        final updatedContent = currentMessage.content + (event.content ?? "");
        if (currentMessage.content.trim().isEmpty && updatedContent.trim().length >= 10) {
          if (kDebugMode) _logger.d('🔧 TOOL DEBUG: Sufficient content accumulated (${updatedContent.trim().length} chars) - clearing tool message');
          _currentToolSubject.sink.add(null);
          _isStreamingSubject.sink.add(false);
        }
        
        // Add content to the message and extract source citations
        updatedMessage = currentMessage.appendContent(event.content ?? "");
        
        // Extract and add source citations from the content
        final sourceCitations = _extractSourceCitations(event.content ?? "");
        if (sourceCitations.isNotEmpty) {
          updatedMessage = updatedMessage!.addSourceCitations(sourceCitations);
        }
      } else if (event is SessionIdEvent) {
        // Update session ID from backend - this is the correct session ID to use
        // Backend session ID received - keep this log visible in release mode
        
        // Update the current session with the backend-provided session ID
        final updatedSession = currentSession.copyWith(id: event.content ?? "");
        _currentSessionSubject.sink.add(updatedSession);
        _updateInHistory(updatedSession);
        
        // Update the message with the correct session ID too
        updatedMessage = currentMessage.copyWith(sessionId: event.content ?? "");
            } else if (event is RunStartedEvent) {
        // Message already created, just continue
      } else if (event is ToolCallStartedEvent) {
        // Skip heritage_lookup as it will be broken down in ToolParametersEvent
        if (event.content != 'heritage_lookup') {
          // Update current tool - for simple tool names, just use the name
          _logger.d('🔧 TOOL DEBUG: ToolCallStartedEvent received - tool: ${event.content ?? "null"}');
          _currentToolSubject.sink.add(event.content);
          _logger.d('🔧 TOOL DEBUG: currentTool set to: ${event.content ?? "null"}');
        }
      } else if (event is ToolParametersEvent) {
        // ToolParametersEvent is the MAIN tool event in our API (no ToolCallStarted)
        // Handle heritage_lookup by breaking it down into individual tools
        if (event.toolName == 'heritage_lookup') {
          final individualTools = _breakDownHeritageTools(event.toolArgs);
          
          // Update current tool to the first individual tool with parameters
          if (individualTools.isNotEmpty) {
            final firstTool = individualTools.first;
            final toolWithParams = '${firstTool.name} with params: ${firstTool.parameters}';
            _logger.d('🔧 TOOL DEBUG: ToolParametersEvent (heritage) - Setting currentTool to: $toolWithParams');
            _currentToolSubject.sink.add(toolWithParams);
          }
          
          // Remove any existing heritage_lookup tool calls from the message
          updatedMessage = currentMessage.copyWith(
            toolCalls: currentMessage.toolCalls
                .where((tc) => tc.name.toLowerCase() != 'heritage_lookup')
                .toList(),
          );
          
          // Add the individual tools
          for (final toolCall in individualTools) {
            updatedMessage = updatedMessage!.addToolCall(toolCall);
          }
        } else {
          // Regular tool call - THIS IS THE PRIMARY ENTRY POINT for tool messages
          final toolWithParams = '${event.toolName} with params: ${event.toolArgs}';
          _logger.d('🔧 TOOL DEBUG: ToolParametersEvent (primary) - Setting currentTool to: $toolWithParams');
          _currentToolSubject.sink.add(toolWithParams);
          _logger.d('🔧 TOOL DEBUG: currentTool stream updated with: $toolWithParams');
          
          final toolCall = ToolCall(
            name: event.toolName,
            parameters: event.toolArgs,
            startTime: DateTime.now(),
          );
          updatedMessage = currentMessage.addToolCall(toolCall);
        }
      } else if (event is ToolCallCompletedEvent) {
        // Complete tool call
        final parts = (event.content ?? "").split(' completed in ');
        if (parts.length >= 2) {
          final toolName = parts[0];
          updatedMessage = currentMessage.updateToolCall(
            toolName,
            endTime: DateTime.now(),
            result: 'Completed',
          );
        }
      } else if (event is EventDataEvent) {
        // Handle execution logs from EventData
        if (kDebugMode) _logger.d('🔧 SSE DEBUG: Processing EventData with ${event.events.length} events');
        
        final executionLog = ExecutionLog(
          model: event.model,
          events: event.events.map((eventData) {
            final eventType = _parseEventType(eventData['event'] as String?);
            final time = (eventData['time'] as num?)?.toDouble() ?? 0.0;
            final content = eventData['content'] as String? ?? '';
            
            return ExecutionEvent(
              event: eventType,
              time: time,
              content: content,
            );
          }).toList(),
        );
        
        // Store execution log in the message
        updatedMessage = currentMessage.copyWith(executionLog: executionLog);
        if (kDebugMode) _logger.d('🔧 SSE DEBUG: Stored execution log with ${executionLog.events.length} events');
      } else {

      }

      // Update the session if message was modified
      if (updatedMessage != null) {
        final updatedSession = currentSession.updateMessage(messageId, updatedMessage);
        _currentSessionSubject.sink.add(updatedSession);
        _updateInHistory(updatedSession);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling SSE event', error: e, stackTrace: stackTrace);
      _handleStreamError(e.toString(), messageId);
    }
  }

  void _handleStreamComplete(String messageId) {
    _updateMessageStatus(messageId, MessageStatus.completed);
    _logger.d('🔧 STREAMING DEBUG: Stream complete - cleaning up');
    
    // Streaming indicator should already be off when content started appearing
    // Just ensure cleanup happens
    _isStreamingSubject.sink.add(false);
    _currentStreamingMessageIdSubject.sink.add(null);
    _currentToolSubject.sink.add(null);
    
    // Defer source data fetching to avoid blocking UI rendering
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _fetchDetailedSourceData(messageId);
      });
    });
  }

  void _handleStreamError(String error, String messageId) {
    _logger.e('Stream error for message $messageId: $error');
    _updateMessageStatus(messageId, MessageStatus.error);
    _isStreamingSubject.sink.add(false);
    _currentStreamingMessageIdSubject.sink.add(null);
    _errorSubject.sink.add(error);
  }


  void _updateMessageStatus(String messageId, MessageStatus status) {
    final currentSession = _currentSessionSubject.value;
    if (currentSession == null) return;

    final messageIndex = currentSession.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final currentMessage = currentSession.messages[messageIndex];
    final updatedMessage = currentMessage.copyWith(status: status);
    final updatedSession = currentSession.updateMessage(messageId, updatedMessage);
    
    _currentSessionSubject.sink.add(updatedSession);
    _updateInHistory(updatedSession);
  }

  // ===== HELPER METHODS =====

  void _addToHistory(ChatSession session) {
    final currentHistory = _chatHistorySubject.value;
    final updatedHistory = [session, ...currentHistory];
    _chatHistorySubject.sink.add(updatedHistory);
  }

  void _updateInHistory(ChatSession session) {
    final currentHistory = _chatHistorySubject.value;
    final updatedHistory = currentHistory.map((s) {
      return s.id == session.id ? session : s;
    }).toList();
    _chatHistorySubject.sink.add(updatedHistory);
  }

  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'msg_${timestamp}_$random';
  }

  /// Parse event type from string (copied from api_response_parser.dart)
  ExecutionEventType _parseEventType(String? eventString) {
    if (eventString == null) return ExecutionEventType.unknown;
    
    switch (eventString) {
      case 'RunStarted':
        return ExecutionEventType.runStarted;
      case 'ToolCallStarted':
        return ExecutionEventType.toolCallStarted;
      case 'ToolCallCompleted':
        return ExecutionEventType.toolCallCompleted;
      case 'RunContent':
        return ExecutionEventType.runContent;
      case 'RunCompleted':
        return ExecutionEventType.runCompleted;
      default:
        return ExecutionEventType.unknown;
    }
  }

  /// Break down heritage_lookup into individual tool calls (matching webapp logic)
  List<ToolCall> _breakDownHeritageTools(Map<String, dynamic> params) {
    final List<ToolCall> tools = [];
    
    // Helper function to check if parameter is valid
    bool isValidParam(dynamic param) {
      return param != null && 
             param != "" && 
             param != "None" && 
             param != "null" &&
             param.toString().isNotEmpty;
    }
    
    try {
      // Check verse_part parameter
      if (params.containsKey('verse_part') && isValidParam(params['verse_part'])) {
        tools.add(ToolCall(
          name: 'verse_lookup',
          parameters: {'verse_part': params['verse_part']},
          startTime: DateTime.now(),
        ));
      }
      
      // Check dict_words parameter (array format) and dict_word (legacy single format)
      List<String> dictWords = [];
      
      // Handle new array format
      if (params.containsKey('dict_words') && params['dict_words'] is List) {
        for (final word in params['dict_words']) {
          if (isValidParam(word)) {
            dictWords.add(word.toString());
          }
        }
      }
      // Handle legacy single word format
      else if (params.containsKey('dict_word') && isValidParam(params['dict_word'])) {
        dictWords.add(params['dict_word'].toString());
      }
      
      // Create dictionary tool call if we have words
      if (dictWords.isNotEmpty) {
        tools.add(ToolCall(
          name: 'dict_lookup',
          parameters: {
            'dict_words': dictWords,
            'words': dictWords, // Also include 'words' for compatibility
          },
          startTime: DateTime.now(),
        ));
      }
      
      // Check chunk_query parameter
      if (params.containsKey('chunk_query') && isValidParam(params['chunk_query'])) {
        tools.add(ToolCall(
          name: 'chunk_search',
          parameters: {'chunk_query': params['chunk_query']},
          startTime: DateTime.now(),
        ));
      }
      
      // Check pattern parameter for regex_word_search
      if (params.containsKey('pattern') && isValidParam(params['pattern'])) {
        tools.add(ToolCall(
          name: 'regex_word_search',
          parameters: {'pattern': params['pattern']},
          startTime: DateTime.now(),
        ));
      }
      

      
    } catch (e) {
      _logger.e('Error breaking down heritage_lookup tools', error: e);
      // Fallback: create a generic heritage_lookup tool
      tools.add(ToolCall(
        name: 'heritage_lookup',
        parameters: params,
        startTime: DateTime.now(),
      ));
    }
    
    return tools;
  }

  /// Global source counter and mapping (like webapp)
  static int _globalSourceCounter = 1;
  static final Map<String, int> _sourceIdToNumber = {};
  
  /// Extract source citations from content with webapp-style processing
  List<SourceCitation> _extractSourceCitations(String content) {
    final List<SourceCitation> citations = [];
    
    // Pattern to match ```source blocks exactly like webapp
    final RegExp sourcePattern = RegExp(
      r'```source\s*\n?(.*?)\n?```',
      multiLine: true,
      dotAll: true,
    );
    
    final matches = sourcePattern.allMatches(content);
    for (final match in matches) {
      final sourceContent = match.group(1)?.trim() ?? '';
      
      try {
        // Parse source data (handle dict-like format: {'chunk': [123], 'defn': [456]})
        final Map<String, dynamic> sourceData = _parseSourceData(sourceContent);
        
        // Process each source type (verse, defn, chunk)
        _processSourceType(sourceData, 'verse', citations);
        _processSourceType(sourceData, 'defn', citations);
        _processSourceType(sourceData, 'chunk', citations);
        
      } catch (e) {
        _logger.w('Error parsing source data: $sourceContent', error: e);
        // Create a basic citation for unparseable sources
        final citation = SourceCitation(
          id: _getOrAssignSourceNumber('unknown', 'unknown'),
          type: 'unknown',
          text: sourceContent,
          reference: 'Source ${citations.length + 1}',
        );
        citations.add(citation);
      }
    }
    
    return citations;
  }

  /// Extract source title from source data
  String _extractSourceTitle(String sourceData) {
    if (sourceData.contains('chunk')) {
      return 'Text Reference';
    } else if (sourceData.contains('defn')) {
      return 'Definition Reference';
    } else {
      return 'Source Reference';
    }
  }
  
  /// Parse source data from string (handles Python dict format)
  Map<String, dynamic> _parseSourceData(String sourceContent) {
    try {
      // Handle Python dict format: {'chunk': [123], 'defn': [456]}
      // Convert to JSON format first
      String jsonStr = sourceContent
          .replaceAll("'", '"')  // Single quotes to double quotes
          .replaceAll('True', 'true')
          .replaceAll('False', 'false')
          .replaceAll('None', 'null');
      
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('Failed to parse as JSON, trying manual parsing');
      // Fallback: try to extract arrays manually
      return _extractSourceArrays(sourceContent);
    }
  }
  
  /// Extract source arrays manually (fallback)
  Map<String, dynamic> _extractSourceArrays(String content) {
    final Map<String, dynamic> result = {};
    
    // Extract chunk arrays: 'chunk': [123, 456]
    final chunkPattern = RegExp(r"'chunk'\s*:\s*\[([^\]]+)\]");
    final chunkMatch = chunkPattern.firstMatch(content);
    if (chunkMatch != null) {
      final ids = chunkMatch.group(1)!.split(',').map((s) => int.tryParse(s.trim())).where((id) => id != null).toList();
      result['chunk'] = ids;
    }
    
    // Extract defn arrays: 'defn': [123, 456]
    final defnPattern = RegExp(r"'defn'\s*:\s*\[([^\]]+)\]");
    final defnMatch = defnPattern.firstMatch(content);
    if (defnMatch != null) {
      final ids = defnMatch.group(1)!.split(',').map((s) => int.tryParse(s.trim())).where((id) => id != null).toList();
      result['defn'] = ids;
    }
    
    // Extract verse arrays: 'verse': [123, 456]
    final versePattern = RegExp(r"'verse'\s*:\s*\[([^\]]+)\]");
    final verseMatch = versePattern.firstMatch(content);
    if (verseMatch != null) {
      final ids = verseMatch.group(1)!.split(',').map((s) => int.tryParse(s.trim())).where((id) => id != null).toList();
      result['verse'] = ids;
    }
    
    return result;
  }
  
  /// Process source type and add citations
  void _processSourceType(Map<String, dynamic> sourceData, String type, List<SourceCitation> citations) {
    final sourceIds = sourceData[type];
    if (sourceIds != null && sourceIds is List) {
      for (final sourceId in sourceIds) {
        if (sourceId != null) {
          final sourceNumber = _getOrAssignSourceNumber(sourceId.toString(), type);
          final citation = SourceCitation(
            id: sourceNumber,
            type: type,
            text: 'Source ID: $sourceId',
            reference: _getSourceReference(type, sourceId),
          );
          citations.add(citation);
        }
      }
    }
  }
  
  /// Get or assign source number (like webapp's getSourceNumber function)
  int _getOrAssignSourceNumber(String sourceId, String sourceType) {
    final key = '${sourceType}_$sourceId';
    if (_sourceIdToNumber.containsKey(key)) {
      return _sourceIdToNumber[key]!;
    }
    final number = _globalSourceCounter++;
    _sourceIdToNumber[key] = number;
    return number;
  }
  
  /// Get source reference text
  String _getSourceReference(String type, dynamic sourceId) {
    switch (type) {
      case 'chunk':
        return 'Chunk $sourceId';
      case 'verse':
        return 'Verse $sourceId';
      case 'defn':
        return 'Definition $sourceId';
      default:
        return 'Source $sourceId';
    }
  }

  /// Fetch detailed source data after stream completion (optimized for performance)
  Future<void> _fetchDetailedSourceData(String messageId) async {
    try {
      final currentSession = _currentSessionSubject.value;
      if (currentSession == null) {
        _logger.w('🔍 No current session, skipping source data fetch');
        return;
      }
      
      final message = currentSession.messages.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => throw Exception('Message not found'),
      );
      
      // Extract all source IDs from the complete message content (optimized)
      final allSourceIds = await _extractAllSourceIdsOptimized(message.content);
      
      if (allSourceIds['verse']!.isNotEmpty || 
          allSourceIds['defn']!.isNotEmpty || 
          allSourceIds['chunk']!.isNotEmpty) {
        
        // Fetch detailed data from API
        final refData = await fetchReferenceData(allSourceIds);
        
        // Create detailed citations from API response
        final detailedCitations = _createDetailedCitations(refData);
        
        // Update message with detailed citations
        final updatedMessage = message.copyWith(citations: detailedCitations);
        _updateMessageInSession(updatedMessage);

      }
      
    } catch (e) {
      _logger.e('❌ Error fetching detailed source data for message $messageId', error: e);
    }
  }
  
  /// Optimized async source extraction with yielding
  Future<Map<String, List<dynamic>>> _extractAllSourceIdsOptimized(String content) async {
    final Map<String, List<dynamic>> allSourceIds = {
      'verse': [],
      'defn': [],
      'chunk': []
    };
    
    // Yield control periodically during processing
    int processedCount = 0;
    
    // Pattern to match ```source blocks exactly like webapp
    final RegExp sourcePattern = RegExp(
      r'```source\s*\n?(.*?)\n?```',
      multiLine: true,
      dotAll: true,
    );
    
    final matches = sourcePattern.allMatches(content);
    if (kDebugMode) _logger.d('🔍 Found ${matches.length} source blocks in content');
    
    for (final match in matches) {
      final sourceContent = match.group(1)?.trim() ?? '';
      
      try {
        // Parse source data (handle dict-like format)
        final Map<String, dynamic> sourceData = _parseSourceData(sourceContent);
        
        for (final entry in sourceData.entries) {
          final sourceType = entry.key;
          final ids = entry.value;
          
          if (allSourceIds.containsKey(sourceType)) {
            if (ids is List) {
              allSourceIds[sourceType]!.addAll(ids);
            } else {
              allSourceIds[sourceType]!.add(ids);
            }
          }
        }
        
        // Yield control every 10 sources to prevent blocking
        processedCount++;
        if (processedCount % 10 == 0) {
          await Future.delayed(Duration.zero);
        }
        
      } catch (e) {
        if (kDebugMode) _logger.w('🔍 Failed to parse source data: $sourceContent', error: e);
      }
    }
    
    return allSourceIds;
  }

  /// Extract all source IDs from message content (webapp style) - Legacy sync version
  Map<String, List<dynamic>> _extractAllSourceIds(String content) {
    final Map<String, List<dynamic>> allSourceIds = {
      'verse': [],
      'defn': [],
      'chunk': []
    };
    
    // Pattern to match ```source blocks exactly like webapp
    final RegExp sourcePattern = RegExp(
      r'```source\s*\n?(.*?)\n?```',
      multiLine: true,
      dotAll: true,
    );
    
          final matches = sourcePattern.allMatches(content);
      _logger.d('🔍 Found ${matches.length} source blocks in content');
      
      for (final match in matches) {
        final sourceContent = match.group(1)?.trim() ?? '';
        _logger.d('🔍 Raw source content: $sourceContent');
        
        try {
          // Parse source data (handle dict-like format)
          final Map<String, dynamic> sourceData = _parseSourceData(sourceContent);
          _logger.d('🔍 Parsed source data: $sourceData');
        
        // Collect source IDs by type
        if (sourceData['verse'] != null && sourceData['verse'] is List) {
          allSourceIds['verse']!.addAll(sourceData['verse']);
        }
        if (sourceData['defn'] != null && sourceData['defn'] is List) {
          allSourceIds['defn']!.addAll(sourceData['defn']);
        }
        if (sourceData['chunk'] != null && sourceData['chunk'] is List) {
          allSourceIds['chunk']!.addAll(sourceData['chunk']);
        }
      } catch (e) {
        _logger.w('Error parsing source data: $sourceContent', error: e);
      }
    }
    
    return allSourceIds;
  }
  
  /// Create detailed citations from API response (matching your curl example)
  List<SourceCitation> _createDetailedCitations(Map<String, dynamic> refData) {
    final List<SourceCitation> citations = [];
    
    // Creating citations from API response
    
    // Process each source type from API response
    ['verse', 'defn', 'chunk'].forEach((sourceType) {
      if (refData[sourceType] != null && refData[sourceType] is List) {
        final List<dynamic> sourceList = refData[sourceType];
        
        // Processing sources
        
        for (int i = 0; i < sourceList.length; i++) {
          final sourceItem = sourceList[i];
          
          if (sourceItem is Map<String, dynamic>) {
            // Each item is like: {"671": {"word": "...", "text": "...", ...}}
            sourceItem.forEach((id, data) {
              
              if (data is Map<String, dynamic>) {
                final sourceNumber = _getOrAssignSourceNumber(id, sourceType);
                final reference = _getApiSourceReference(sourceType, data);
                
                // For verses, try different text fields
                String? text;
                if (sourceType == 'verse') {
                  text = data['text']?.toString() ?? 
                         data['verse_text']?.toString() ?? 
                         data['content']?.toString() ?? 
                         data['iast']?.toString();
                } else {
                  text = data['text']?.toString();
                }
                
                citations.add(SourceCitation(
                  id: sourceNumber,
                  type: sourceType,
                  reference: reference,
                  text: text,
                ));
              }
            });
          }
        }
      }
    });
    
    // Citations created successfully
    
    return citations;
  }
  
  /// Get reference text from API response data
  String _getApiSourceReference(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'verse':
        // Try different possible fields for verse reference
        return data['verse_ref']?.toString() ?? 
               data['ref']?.toString() ?? 
               data['source_title']?.toString() ?? 
               'Verse Source';
      case 'defn':
        return data['word']?.toString() ?? 'Definition';
      case 'chunk':
        return data['ref']?.toString() ?? 'Text Source';
      default:
        return 'Source';
    }
  }
  
  /// Update message in current session
  void _updateMessageInSession(ChatMessage updatedMessage) {
    final currentSession = _currentSessionSubject.value;
    if (currentSession == null) return;
    
    final updatedMessages = currentSession.messages.map((msg) {
      return msg.id == updatedMessage.id ? updatedMessage : msg;
    }).toList();
    
    final updatedSession = currentSession.copyWith(messages: updatedMessages);
    _currentSessionSubject.add(updatedSession);
  }

  /// Fetch detailed reference data for source citations (like webapp API call)
  Future<Map<String, dynamic>> fetchReferenceData(Map<String, List<dynamic>> sourceIds) async {
    try {

      return await _prashnaApiRepo.fetchReferenceData(sourceIds);
    } catch (e) {
      _logger.e('Error fetching reference data', error: e);
      rethrow;
    }
  }

  // ===== GETTERS =====

  ChatSession? get currentSession => _currentSessionSubject.value;
  AiModel get selectedAiModel => _selectedAiModelSubject.value;
  bool get isStreaming => _isStreamingSubject.value;
  List<ChatSession> get chatHistory => _chatHistorySubject.value;
  bool get hasActiveSession => _currentSessionSubject.value != null;
  bool get hasMessages => currentSession?.hasMessages ?? false;
  int get messageCount => currentSession?.messageCount ?? 0;
}
