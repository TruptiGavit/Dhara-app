import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final ChatSession? currentSession;
  final Function(String sessionId) onSessionSelected;
  final Function(String sessionId) onSessionDeleted;
  final VoidCallback onNewChatPressed;
  final Function(String appName)? onComingSoonTapped;
  final AppThemeColors themeColors;
  final AppThemeDisplay appThemeDisplay;

  const ChatHistoryDrawer({
    super.key,
    required this.chatHistory,
    required this.currentSession,
    required this.onSessionSelected,
    required this.onSessionDeleted,
    required this.onNewChatPressed,
    this.onComingSoonTapped,
    required this.themeColors,
    required this.appThemeDisplay,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: themeColors.surface,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildNewChatButton(),
            _buildDivider(),
            _buildSpecialAppsSection(),
            _buildDivider(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Row(
        children: [
          // Simplified icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeColors.primary.withAlpha(0x15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: themeColors.primary,
            ),
          ),
          TdResGaps.h_12,
          Expanded(
            child: Text(
              'Prashna AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: themeColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Minimalist close button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: themeColors.onSurfaceMedium,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: InkWell(
        onTap: onNewChatPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: themeColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),
              TdResGaps.h_8,
              const Text(
                'New Chat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 1,
      color: themeColors.onSurface?.withAlpha(0x10) ?? Colors.grey.withAlpha(0x10),
    );
  }

  Widget _buildSpecialAppsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Dhara Apps',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurfaceMedium,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Naming App
          _buildSpecialAppItem(
            icon: Icons.badge_outlined,
            title: 'Dhara Names',
            subtitle: 'Generate meaningful Sanskrit names',
            color: const Color(0xFF7B61FF),
            onTap: () {
              // TODO: Navigate to Naming App
              onComingSoonTapped?.call('Dhara Names');
            },
          ),
          
          TdResGaps.v_8,
          
          // Essay Writing App
          _buildSpecialAppItem(
            icon: Icons.auto_stories_outlined,
            title: 'Dhara Essays',
            subtitle: 'Sanskrit literature essay assistance',
            color: const Color(0xFFFF6B35),
            onTap: () {
              // TODO: Navigate to Essay Writing App
              onComingSoonTapped?.call('Dhara Essays');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialAppItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: themeColors.onSurface?.withAlpha(0x08) ?? Colors.grey.withAlpha(0x08),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(0x20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            
            TdResGaps.h_10,
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: themeColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: themeColors.onSurfaceMedium,
                    ),
                  ),
                ],
              ),
            ),
            
            // Coming soon badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(0x20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Recent Chats',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurfaceMedium,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (chatHistory.isEmpty) {
      return _buildEmptyHistoryState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final session = chatHistory[index];
        final isCurrentSession = currentSession?.id == session.id;
        
        return _buildHistoryItem(session, isCurrentSession);
      },
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 32,
                color: themeColors.primary,
              ),
            ),
            TdResGaps.v_16,
            Text(
              'No chat history yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurfaceMedium,
              ),
            ),
            TdResGaps.h_8,
            Text(
              'Start your first conversation to see it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: themeColors.onSurfaceLowest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ChatSession session, bool isCurrentSession) {
    final title = _getSessionTitle(session);
    final subtitle = _getSessionSubtitle(session);
    final timeAgo = _getTimeAgo(session.updatedAt);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSessionSelected(session.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentSession 
                  ? themeColors.primary.withAlpha(0x15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isCurrentSession 
                  ? Border.all(
                      color: themeColors.primary.withAlpha(0x30),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrentSession 
                        ? themeColors.primary
                        : themeColors.primary.withAlpha(0x40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TdResGaps.h_12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrentSession ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrentSession 
                              ? themeColors.primary
                              : themeColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        TdResGaps.v_2,
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColors.onSurfaceMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      TdResGaps.v_4,
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: themeColors.onSurfaceLowest,
                        ),
                      ),
                    ],
                  ),
                ),
                TdResGaps.h_8,
                if (isCurrentSession)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: themeColors.onSurfaceMedium,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          TdResGaps.h_8,
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      onSessionDeleted(session.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSessionTitle(ChatSession session) {
    // ChatSession doesn't have a title field, so we generate one from the first message
    
    // Generate title from first user message
    if (session.messages.isNotEmpty) {
      final firstUserMessage = session.messages.firstWhere(
        (msg) => msg.isUser,
        orElse: () => session.messages.first,
      );
      
      final content = firstUserMessage.content.trim();
      if (content.isNotEmpty) {
        return content.length > 40 
            ? '${content.substring(0, 40)}...'
            : content;
      }
    }
    
    return 'New Chat';
  }

  String _getSessionSubtitle(ChatSession session) {
    if (session.messages.length <= 1) {
      return 'No messages yet';
    }
    
    return '${session.messages.length} messages';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
