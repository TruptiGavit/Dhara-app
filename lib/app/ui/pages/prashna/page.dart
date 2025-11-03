import 'dart:async';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/args.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/controller.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/state.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/ai_model_selector.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/chat_input.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/chat_message_widget.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/empty_chat_state.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/chat_history_drawer.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class PrashnaPage extends StatefulWidget {
  final PrashnaArgsRequest mRequestArgs;
  final String title;
  
  const PrashnaPage({
    super.key,
    required this.mRequestArgs,
    this.title = 'Prashna',
  });

  @override
  PrashnaPageState createState() => PrashnaPageState();
}

class PrashnaPageState extends State<PrashnaPage> {
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  PrashnaController mBloc = Modular.get<PrashnaController>();
  
  // Scroll detection for dynamic navbar title with throttling
  final Map<int, GlobalKey> _messageKeys = {};
  Timer? _scrollThrottleTimer;
  

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener for dynamic navbar title
    mBloc.scrollController.addListener(_onScroll);
    
    
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Update route for tab tracking (following existing pattern)
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.prashna);
      
      mBloc.initData(widget.mRequestArgs);
    });
  }

  @override
  void dispose() {
    mBloc.scrollController.removeListener(_onScroll);
    _scrollThrottleTimer?.cancel();
    mBloc.close();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    prepareTheme(context);
  }

    void prepareTheme(BuildContext context) {
    // Get base theme colors from current theme context
    final baseThemeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: Color(0xFF6CE18D), isDark: false);
    
    // Create custom indigo-based theme colors for Prashna module with better contrast
    if (baseThemeColors.isDark) {
      // Custom dark mode colors for better visibility and appeal
      themeColors = AppThemeColors(
        surface: Color(0xFF1A1B2E), // Deep navy for surfaces
        back: Color(0xFF0F0F1A), // Very dark navy for background
        onSurface: Color(0xFFE8E8F0), // Light gray-blue for primary text
        onSurfaceHigh: Color(0xFFF8F8FF), // Almost white for high emphasis text
        onSurfaceMedium: Color(0xFFB8B8D0), // Medium gray-blue for secondary text
        onSurfaceDisable: Color(0xFF808090), // Darker gray for disabled text
        onSurfaceLowest: Color(0xFF606070), // Low emphasis text
        primaryHigh: Color(0xFF9FA8DA), // Lighter indigo for high emphasis
        primary: Color(0xFF7986CB), // Medium indigo
        primaryLight: Color(0xFF3F4A7A), // Darker indigo for light emphasis
        secondaryLight: Color(0xFF2A2F4A), // Secondary accent
        secondaryColor: Color(0xFF3F4A7A), // Secondary color
        seedColor: Colors.indigo,
        errorColor: Color(0xFFEF5350), // Red for errors
        isDark: true,
      );
    } else {
      // Custom light mode colors for better visual appeal
      themeColors = AppThemeColors(
        surface: Color(0xFFFAFAFF), // Very light indigo-tinted background
        back: Color(0xFFFFFFFF), // Pure white for background
        onSurface: Color(0xFF1A1B2E), // Dark navy for primary text
        onSurfaceHigh: Color(0xFF0F0F1A), // Very dark for high emphasis text
        onSurfaceMedium: Color(0xFF5A5B6E), // Medium gray for secondary text
        onSurfaceDisable: Color(0xFF9A9AAE), // Light gray for disabled text
        onSurfaceLowest: Color(0xFFB8B8D0), // Very light for low emphasis
        primaryHigh: Color(0xFF3F51B5), // Strong indigo for high emphasis
        primary: Color(0xFF5C6BC0), // Medium indigo
        primaryLight: Color(0xFFE8EAF6), // Very light indigo for backgrounds
        secondaryLight: Color(0xFFF3E5F5), // Light purple accent
        secondaryColor: Color(0xFF9C27B0), // Purple secondary
        seedColor: Colors.indigo,
        errorColor: Color(0xFFD32F2F), // Red for errors
        isDark: false,
      );
    }
    
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
  }

  // Throttled scroll detection method
  void _onScroll() {
    if (!mounted || !mBloc.scrollController.hasClients) return;
    
    // Throttle scroll events to prevent excessive state updates
    _scrollThrottleTimer?.cancel();
    _scrollThrottleTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _processScrollUpdate();
    });
  }
  
  // Process scroll update after throttling
  void _processScrollUpdate() {
    if (!mounted || !mBloc.scrollController.hasClients) return;
    
    final messages = mBloc.state.messages;
    if (messages.isEmpty) return;
    
    // Use a fixed viewport height to avoid BuildContext issues in async callbacks
    const double screenHeight = 800.0;
    
    // Find the message that is most visible in the viewport
    String? currentVisibleQuestion;
    double bestIntersection = 0;
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final key = _messageKeys[i];
      
      if (key?.currentContext != null) {
        final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          
          // Calculate intersection with viewport (approximating AppBar height as 100)
          final viewportTop = 100.0;
          final viewportBottom = screenHeight - 100; // Subtract input area
          
          final messageTop = position.dy;
          final messageBottom = position.dy + size.height;
          
          // Calculate intersection ratio
          final intersectionTop = messageTop.clamp(viewportTop, viewportBottom);
          final intersectionBottom = messageBottom.clamp(viewportTop, viewportBottom);
          final intersection = (intersectionBottom - intersectionTop).clamp(0.0, double.infinity);
          
          if (intersection > bestIntersection && intersection > 50) { // Minimum 50px visible
            bestIntersection = intersection;
            
            // Find the corresponding user question for this message
            if (message.isUser) {
              currentVisibleQuestion = message.content;
            } else {
              // For AI messages, find the previous user message
              for (int j = i - 1; j >= 0; j--) {
                if (messages[j].isUser) {
                  currentVisibleQuestion = messages[j].content;
                  break;
                }
              }
            }
          }
        }
      }
    }
    
    // Update the current visible question
    mBloc.updateCurrentVisibleQuestion(currentVisibleQuestion);
  }


  @override
  Widget build(BuildContext context) {
    // Prepare theme first
    prepareTheme(context);
    
    return BlocBuilder<PrashnaController, PrashnaCubitState>(
      bloc: mBloc,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: themeColors.back,
          appBar: _buildAppBar(context, state),
            drawer: _buildChatHistoryDrawer(state),
            body: _buildBody(context, state),
            floatingActionButton: state.hasMessages ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0), // Move up to avoid send button
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  mBloc.scrollToBottom();
                },
                backgroundColor: themeColors.primary,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: themeColors.onSurface,
                ),
              ),
            ) : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, PrashnaCubitState state) {
    return AppBar(
      backgroundColor: Color.alphaBlend(
        themeColors.primary.withAlpha(0x02),
        themeColors.surface,
      ),
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // Prashna logo/badge - flexible
          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: themeColors.primaryHigh,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Prashna',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeColors.primaryHigh,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.hasMessages) ...[
            const SizedBox(width: 8),
            // Dynamic title - takes remaining space
            Expanded(
              child: Text(
                state.displayTitle,
                style: TextStyle(
                  fontSize: 13,
                  color: themeColors.onSurfaceMedium,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // New Chat Button - Compact design to prevent overflow
        IconButton(
          onPressed: () {
            mBloc.createNewChat();
            // Close drawer if open
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.of(context).pop();
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: Colors.white,
            ),
          ),
          tooltip: 'Start New Chat',
        ),

      ],
    );
  }

  Widget _buildChatHistoryDrawer(PrashnaCubitState state) {
    return ChatHistoryDrawer(
      chatHistory: state.chatHistory,
      currentSession: state.currentSession,
      onSessionSelected: (sessionId) {
        Navigator.of(context).pop(); // Close drawer
        mBloc.switchToSession(sessionId);
      },
      onSessionDeleted: (sessionId) {
        mBloc.deleteSession(sessionId);
      },
      onNewChatPressed: () {
        Navigator.of(context).pop(); // Close drawer
        mBloc.createNewChat();
      },
      themeColors: themeColors,
      appThemeDisplay: appThemeDisplay,
    );
  }

  Widget _buildBody(BuildContext context, PrashnaCubitState state) {
    return Column(
      children: [
        // AI Model Selector (shown when toggled)
        if (state.showModelSelector)
          AiModelSelector(
            selectedModel: state.selectedAiModel,
            onModelSelected: (model) => mBloc.changeAiModel(model),
            onClose: () => mBloc.toggleModelSelector(),
            themeColors: themeColors,
            appThemeDisplay: appThemeDisplay,
            isDeveloperMode: false,
          ),
        
        // Chat Messages Area
        Expanded(
          child: state.hasMessages
              ? _buildChatList(context, state)
              : EmptyChatState(
                  selectedModel: state.selectedAiModel,
                  onSampleQuestionTap: (question) {
                    mBloc.messageController.text = question;
                    mBloc.onMessageChanged(question);
                  },
                  // Pass controller and callbacks for middle search bar
                  controller: mBloc.messageController,
                  onChanged: (value) => mBloc.onMessageChanged(value),
                  onSubmitted: () => mBloc.onFormSubmitted(),
                  canSend: state.canSendMessage,
                  onSend: () => mBloc.sendMessage(),
                  themeColors: themeColors,
                  appThemeDisplay: appThemeDisplay,
                  isDeveloperMode: false,
                ),
        ),
        
        // Chat Input (only show when there are messages)
        if (state.hasMessages) ...[
          // Debug logging for ChatInput
          if (kDebugMode) Builder(
            builder: (context) {
              return const SizedBox.shrink();
            },
          ),
          ChatInput(
            controller: mBloc.messageController,
            isStreaming: state.isStreaming,
            canSend: state.canSendMessage,
            onSend: () => mBloc.sendMessage(),
            onChanged: (value) => mBloc.onMessageChanged(value),
            onSubmitted: () => mBloc.onFormSubmitted(),
            selectedModel: state.selectedAiModel,
            currentTool: state.currentTool,
            themeColors: themeColors,
            appThemeDisplay: appThemeDisplay,
            isDeveloperMode: false,
          ),
        ],
      ],
    );
  }

  Widget _buildChatList(BuildContext context, PrashnaCubitState state) {
    return ListView.builder(
      key: PageStorageKey('prashna_chat_${state.currentSession?.id ?? 'default'}'),
      controller: mBloc.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isStreaming = state.isStreaming && 
                           message.id == state.currentStreamingMessageId;
        
        // Ensure we have a global key for this message index
        if (!_messageKeys.containsKey(index)) {
          _messageKeys[index] = GlobalKey();
        }
        
        return ChatMessageWidget(
          key: ValueKey('message_${message.id}'),
          message: message,
          isStreaming: isStreaming,
          currentTool: state.currentTool,
          isDeveloperMode: false,
          onCopy: () {
            // Copy the cleaned version (without source citations)
            _copyMessageTextCleaned(message.content);
            _showCopyFeedback();
            // Log the copy action
            mBloc.copyMessage(message.content);
          },
          onShare: () => _shareMessage(message),
          onRetry: message.hasError ? () => mBloc.retryMessage(message) : null,
          themeColors: themeColors,
          appThemeDisplay: appThemeDisplay,
        );
      },
    );
  }

  IconData _getModelIcon(AiModel model) {
    switch (model) {
      case AiModel.gemini:
        return Icons.flash_on;
      case AiModel.qwen:
        return Icons.chat_bubble_outline;
    }
  }

  /// Show feedback when message is copied
  void _showCopyFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: themeColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  /// Share message (frontend-only implementation)
  /// Directly shares as text without modal since we don't support image generation for chat
  void _shareMessage(ChatMessage message) {
    _shareMessageAsText(message.content);
  }

  /// Remove source citation numbers like [1], [2], [3] from text
  /// These are only relevant within the app and should be removed when sharing
  String _removeSourceCitations(String text) {
    // Remove citation numbers in format [1], [2], [3], etc.
    String cleaned = text.replaceAll(RegExp(r'\[\d+\]'), '');
    
    // Clean up multiple consecutive spaces (but preserve newlines)
    cleaned = cleaned.replaceAll(RegExp(r'  +'), ' ');
    
    return cleaned.trim();
  }

  /// Copy message text to clipboard (with citations cleaned)
  void _copyMessageTextCleaned(String content) {
    // Remove source citations before copying
    String cleanedContent = _removeSourceCitations(content);
    Clipboard.setData(ClipboardData(text: cleanedContent));
  }

  /// Copy message text to clipboard (original method, kept for ShareModal)
  void _copyMessageText(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Message copied to clipboard'),
          ],
        ),
        backgroundColor: themeColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Share message as text using native share dialog
  Future<void> _shareMessageAsText(String content) async {
    try {
      // Clean the content by removing source citation numbers [1], [2], etc.
      // These are meaningless outside the app context
      String cleanedContent = _removeSourceCitations(content);
      
      // Use share_plus directly to share plain text
      // No backend API needed - just native platform sharing
      final result = await Share.share(
        cleanedContent,
        subject: 'Shared from Dhara - Prashna',
      );
      
      // Show success feedback if share dialog was shown
      // Note: result.status will be ShareResultStatus.success or dismissed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Message shared'),
              ],
            ),
            backgroundColor: themeColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Failed to share message'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    }
  }

}
