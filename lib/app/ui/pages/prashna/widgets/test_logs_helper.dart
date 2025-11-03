import 'dart:convert';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:flutter/services.dart';

/// Helper class to create test messages with logs for development
class TestLogsHelper {
  /// Create a test chat message with real logs using the prashna.json data
  static Future<ChatMessage> createTestMessageWithRealLogs() async {
    // Load the sample prashna.json data
    final String jsonString = await rootBundle.loadString('assets/prashna.json');
    
    return ChatMessage.assistant(
      content: '''**Who is Rama?**  
Rama is the legendary prince and the central hero of the *Ramayana*, celebrated for his devotion, courage, and adherence to dharma.

**Who is his father?**  
His father is King **Dasharatha** of Ayodhya, the king who ruled the kingdom before Rama's exile.

**Verse about *vanavas* (forest exile)**  
A Sanskrit verse that mentions a king living in *vanavas* (forest exile) is found in the *Mahābhārata*.

These references provide a concise overview of Rama, his parentage, and a textual example of the term *vanavas* in classical Indian literature.''',
      rawContent: jsonString, // This contains the EventData
      aiModel: AiModel.qwen,
      status: MessageStatus.completed,
      citations: [
        const SourceCitation(
          id: 4970354,
          type: 'chunk',
          text: 'Rama is the legendary prince and the central hero of the Ramayana',
          reference: 'Ramayana Reference',
        ),
        const SourceCitation(
          id: 4970353,
          type: 'chunk', 
          text: 'King Dasharatha of Ayodhya, the king who ruled the kingdom',
          reference: 'Dasharatha Reference',
        ),
        const SourceCitation(
          id: 271581,
          type: 'verse',
          text: 'Sanskrit verse about forest exile',
          reference: 'Mahābhārata, Aranyaka, Chapter 9',
        ),
      ],
      toolCalls: [
        ToolCall(
          name: 'dict_lookup',
          parameters: {'dict_word': 'Rama'},
          startTime: DateTime.now().subtract(const Duration(seconds: 30)),
          endTime: DateTime.now().subtract(const Duration(seconds: 30, milliseconds: -203)),
        ),
        ToolCall(
          name: 'verse_lookup', 
          parameters: {'verse_part': 'vanavas'},
          startTime: DateTime.now().subtract(const Duration(seconds: 25)),
          endTime: DateTime.now().subtract(const Duration(seconds: 25, milliseconds: -91)),
        ),
        ToolCall(
          name: 'chunk_lookup',
          parameters: {'chunk_query': 'Rama hero of Ramayana father Dasharatha'},
          startTime: DateTime.now().subtract(const Duration(seconds: 20)),
          endTime: DateTime.now().subtract(const Duration(seconds: 20, milliseconds: -3646)),
        ),
      ],
    );
  }
}
