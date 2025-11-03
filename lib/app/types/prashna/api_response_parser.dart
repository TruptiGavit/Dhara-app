import 'dart:convert';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart';
import 'package:dharak_flutter/app/types/prashna/execution_log.dart';
import 'package:logger/logger.dart';

/// Parser for Prashna API streaming response
class PrashnaApiResponseParser {
  static final Logger _logger = Logger();

  /// Parse tool calls from the streaming API response
  static List<ToolCall> parseToolCalls(String apiResponse) {
    try {
      final lines = apiResponse.split('\n').where((line) => line.trim().isNotEmpty);
      final toolCalls = <ToolCall>[];
      final toolStartTimes = <String, double>{};
      
      for (final line in lines) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final event = json['event'] as String?;
          final content = json['content'];
          
          if (event == 'ToolParameters' && content is Map<String, dynamic>) {
            // Extract tool parameters
            final toolName = content['tool_name'] as String?;
            final toolArgs = content['tool_args'] as Map<String, dynamic>?;
            
            if (toolName != null && toolArgs != null) {
              toolCalls.add(ToolCall(
                toolName: toolName,
                toolArgs: toolArgs,
              ));
            }
          } else if (event == 'EventData' && content is Map<String, dynamic>) {
            // Process timing information from EventData
            _processEventDataTimings(content, toolCalls, toolStartTimes);
          }
        } catch (e) {
          // Skip malformed JSON lines
          _logger.d('Skipping malformed JSON line: $line');
          continue;
        }
      }
      
      _logger.i('Parsed ${toolCalls.length} tool calls: ${toolCalls.map((t) => '${t.toolName}(${t.query})').join(', ')}');
      return toolCalls;
    } catch (e) {
      _logger.e('Error parsing tool calls: $e');
      return [];
    }
  }

  /// Parse execution logs from the streaming API response
  static ExecutionLog? parseExecutionLog(String apiResponse) {
    try {
      final lines = apiResponse.split('\n').where((line) => line.trim().isNotEmpty);
      ExecutionLog? foundLog;
      
      // Check all lines, EventData might be at the end
      for (final line in lines) {
        try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final event = json['event'] as String?;
      final content = json['content'];

      // Handle both formats: {"event": "EventData", "content": {...}} and {"content": {...}, "event": "EventData"}
      if (event == 'EventData' && content is Map<String, dynamic>) {
            // Found EventData with execution logs
            final model = content['model'] as String? ?? 'unknown';
            final eventsData = content['events'] as List<dynamic>? ?? [];
            
            final events = <ExecutionEvent>[];
            
            for (final eventData in eventsData) {
              if (eventData is Map<String, dynamic>) {
                try {
                  final eventType = _parseEventType(eventData['event'] as String?);
                  final time = (eventData['time'] as num?)?.toDouble() ?? 0.0;
                  final eventContent = eventData['content'] as String? ?? '';
                  
                  events.add(ExecutionEvent(
                    event: eventType,
                    time: time,
                    content: eventContent,
                  ));
                } catch (e) {
                  _logger.w('Skipping malformed event: $eventData');
                  continue;
                }
              }
            }
            
            foundLog = ExecutionLog(
              model: model,
              events: events,
            );
            
            _logger.i('✅ Parsed execution log with ${events.length} events, model: $model, total time: ${events.isNotEmpty ? events.last.time : 0}s');
            // Don't return immediately, continue checking all lines in case there are multiple EventData
          }
        } catch (e) {
          // Skip malformed JSON lines - this is normal for streaming content
          continue;
        }
      }
      
      if (foundLog == null) {
        _logger.w('❌ No EventData found in API response (${lines.length} lines checked)');
        // Debug: Show a sample of lines to help diagnose
        for (int i = 0; i < lines.length && i < 3; i++) {
          final line = lines.elementAt(i);
          _logger.d('  Line $i: ${line.substring(0, line.length > 100 ? 100 : line.length)}...');
        }
      } else {
        _logger.i('✅ Successfully found and parsed EventData with ${foundLog.events.length} events');
      }
      
      return foundLog;
    } catch (e) {
      _logger.e('Error parsing execution log: $e');
      return null;
    }
  }

  /// Parse event type from string
  static ExecutionEventType _parseEventType(String? eventString) {
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

  /// Process timing information from EventData
  static void _processEventDataTimings(
    Map<String, dynamic> eventData,
    List<ToolCall> toolCalls,
    Map<String, double> toolStartTimes,
  ) {
    try {
      final events = eventData['events'] as List<dynamic>?;
      if (events == null) return;

      for (final event in events) {
        if (event is! Map<String, dynamic>) continue;
        
        final eventType = event['event'] as String?;
        final time = (event['time'] as num?)?.toDouble();
        final content = event['content'] as String?;
        
        if (eventType == 'ToolCallStarted' && time != null && content != null) {
          // Extract tool name and query from content like "dict_lookup(dict_word=Arjuna)"
          final match = RegExp(r'(\w+)\((.+)\)').firstMatch(content);
          if (match != null) {
            final toolName = match.group(1)!;
            final toolKey = '$toolName:${match.group(2)}';
            toolStartTimes[toolKey] = time;
          }
        } else if (eventType == 'ToolCallCompleted' && time != null && content != null) {
          // Extract completion information
          final match = RegExp(r'(\w+)\((.+)\) completed in ([\d.]+)s').firstMatch(content);
          if (match != null) {
            final toolName = match.group(1)!;
            final duration = double.tryParse(match.group(3)!) ?? 0.0;
            final toolKey = '$toolName:${match.group(2)}';
            final startTime = toolStartTimes[toolKey];
            
            // Update corresponding tool call with timing info
            _updateToolCallTimings(toolCalls, toolName, match.group(2)!, startTime, time, duration);
          }
        }
      }
    } catch (e) {
      _logger.w('Error processing EventData timings: $e');
    }
  }

  /// Update tool call with timing information
  static void _updateToolCallTimings(
    List<ToolCall> toolCalls,
    String toolName,
    String argsString,
    double? startTime,
    double completionTime,
    double duration,
  ) {
    // Find matching tool call and create updated version
    for (int i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];
      if (toolCall.toolName == toolName && _matchesArgs(toolCall, argsString)) {
        toolCalls[i] = ToolCall(
          toolName: toolCall.toolName,
          toolArgs: toolCall.toolArgs,
          startTime: startTime,
          completionTime: completionTime,
          duration: duration,
        );
        break;
      }
    }
  }

  /// Check if tool call matches the arguments string
  static bool _matchesArgs(ToolCall toolCall, String argsString) {
    try {
      // Extract query from args string
      if (argsString.contains('dict_word=')) {
        final word = argsString.split('dict_word=')[1];
        return toolCall.toolArgs['dict_word'] == word;
      } else if (argsString.contains('verse_part=')) {
        final part = argsString.split('verse_part=')[1];
        return toolCall.toolArgs['verse_part'] == part;
      } else if (argsString.contains('chunk_query=')) {
        final query = argsString.split('chunk_query=')[1];
        return toolCall.toolArgs['chunk_query'] == query;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Parse sources from the API response
  static Map<String, List<int>> parseSources(String apiResponse) {
    try {
      final sources = <String, List<int>>{};
      final lines = apiResponse.split('\n').where((line) => line.trim().isNotEmpty);
      
      for (final line in lines) {
        try {
          // Look for source blocks in the format: {'chunk': [123, 456, ...]}
          if (line.contains("{'") && line.contains("':") && line.contains("]")) {
            final sourceMatch = RegExp(r"\{'(\w+)':\s*\[([^\]]+)\]").firstMatch(line);
            if (sourceMatch != null) {
              final sourceType = sourceMatch.group(1)!;
              final idsString = sourceMatch.group(2)!;
              final ids = idsString
                  .split(',')
                  .map((s) => int.tryParse(s.trim()))
                  .where((id) => id != null)
                  .cast<int>()
                  .toList();
              
              if (ids.isNotEmpty) {
                sources[sourceType] = ids;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      _logger.i('Parsed sources: ${sources.keys.join(', ')}');
      return sources;
    } catch (e) {
      _logger.e('Error parsing sources: $e');
      return {};
    }
  }

  /// Get tool call statistics
  static Map<String, dynamic> getToolCallStats(List<ToolCall> toolCalls) {
    final stats = <String, int>{};
    double totalDuration = 0.0;
    
    for (final toolCall in toolCalls) {
      stats[toolCall.toolName] = (stats[toolCall.toolName] ?? 0) + 1;
      if (toolCall.duration != null) {
        totalDuration += toolCall.duration!;
      }
    }
    
    return {
      'totalTools': toolCalls.length,
      'toolBreakdown': stats,
      'totalDuration': totalDuration,
    };
  }
}
