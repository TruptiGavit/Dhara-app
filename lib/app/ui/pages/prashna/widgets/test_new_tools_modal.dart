import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/new_tools_sources_modal.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';

/// Test page to demonstrate the new tools modal implementation
class TestNewToolsModal extends StatelessWidget {
  const TestNewToolsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test New Tools Modal'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showTestModal(context),
          child: const Text('Show Tools Modal'),
        ),
      ),
    );
  }

  void _showTestModal(BuildContext context) {
    // Create a test message with the Arjuna API response content
    final testMessage = ChatMessage(
      id: 'test',
      content: _getTestApiResponse(),
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      citations: [], // Add test citations if needed
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NewToolsAndSourcesModal(
          message: testMessage,
          sourceKeys: {},
          sourcesScrollController: ScrollController(),
        );
      },
    );
  }

  String _getTestApiResponse() {
    // Return the actual API response from the prashna.json file
    return '''
{"content": "UitOEfTPnrj4jPohScZbnQ", "event": "SessionID"}
{"content": "Run started", "event": "RunStarted"}
{"content": {"tool_name": "chunk_lookup", "tool_args": {"chunk_query": "story of Arjuna meaning and details"}}, "event": "ToolParameters"}
{"content": {"tool_name": "dict_lookup", "tool_args": {"dict_word": "Arjuna"}}, "event": "ToolParameters"}
{"content": {"tool_name": "chunk_lookup", "tool_args": {"chunk_query": "story of arjuna"}}, "event": "ToolParameters"}
{"content": {"tool_name": "chunk_lookup", "tool_args": {"chunk_query": "Arjuna story meaning 'agnimeele'"}}, "event": "ToolParameters"}
{"content": {"tool_name": "verse_lookup", "tool_args": {"verse_part": "agnimeele"}}, "event": "ToolParameters"}
{"content": "**", "event": "RunResponse"}
{"content": "Ar", "event": "RunResponse"}
    ''';
  }
}

/// Extension to handle missing enum
extension ChatMessageExtension on ChatMessage {
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    List<dynamic>? citations,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      citations: citations ?? this.citations,
    );
  }
}

/// Mock message role enum
enum MessageRole {
  user,
  assistant,
}



























