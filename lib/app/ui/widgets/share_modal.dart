import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';

class ShareModal extends StatelessWidget {
  final AppThemeColors? themeColors;
  final String textToShare;
  final VoidCallback? onCopyText;
  final VoidCallback? onShareImage;
  final bool isScreenShare; // New parameter for screen sharing
  final String contentType; // 'verse' or 'definition' for theme colors

  const ShareModal({
    super.key,
    this.themeColors,
    required this.textToShare,
    this.onCopyText,
    this.onShareImage,
    this.isScreenShare = false,
    this.contentType = 'definition', // Default to definition
  });

  /// Get theme color based on content type
  Color get _getThemeColor {
    switch (contentType) {
      case 'verse':
        // Use primary color (green) for verses/quickverse
        return themeColors?.primary ?? const Color(0xFF6CE18D);
      case 'definition':
        // Use secondary color (orange/red) for word definitions
        return themeColors?.secondaryColor ?? const Color(0xFFF9140C);
      case 'chunk':
        // Use blue color for books/chunks
        return Colors.blue;
      case 'chat':
        // Use indigo/purple color for chat messages
        return Colors.indigo;
      default:
        // Fallback to primary color
        return themeColors?.primary ?? const Color(0xFF6CE18D);
    }
  }

  /// Get copy button title based on content type
  String _getCopyTitle() {
    if (isScreenShare) {
      switch (contentType) {
        case 'chunk':
          return "Copy All Chunks";
        case 'definition':
          return "Copy All Definitions";
        case 'verse':
          return "Copy All Verses";
        case 'chat':
          return "Copy All Messages";
        default:
          return "Copy All Text";
      }
    } else {
      switch (contentType) {
        case 'chunk':
          return "Copy Chunk";
        case 'definition':
          return "Copy Definition";
        case 'verse':
          return "Copy Verse";
        case 'chat':
          return "Copy Message";
        default:
          return "Copy Text";
      }
    }
  }

  /// Get copy button subtitle based on content type
  String _getCopySubtitle() {
    if (isScreenShare) {
      switch (contentType) {
        case 'chunk':
          return "Copy all chunk texts to clipboard";
        case 'definition':
          return "Copy all definition texts to clipboard";
        case 'verse':
          return "Copy all verse texts to clipboard";
        case 'chat':
          return "Copy all message texts to clipboard";
        default:
          return "Copy all text to clipboard";
      }
    } else {
      switch (contentType) {
        case 'chunk':
          return "Copy chunk text to clipboard";
        case 'definition':
          return "Copy definition text to clipboard";
        case 'verse':
          return "Copy verse text to clipboard";
        case 'chat':
          return "Copy message text to clipboard";
        default:
          return "Copy text to clipboard";
      }
    }
  }

  /// Get share button title based on content type
  String _getShareTitle() {
    if (isScreenShare) {
      return "Share Full Screen";
    } else {
      switch (contentType) {
        case 'chunk':
          return "Share Chunk as Image";
        case 'definition':
          return "Share Definition as Image";
        case 'verse':
          return "Share Verse as Image";
        case 'chat':
          return "Share Message";
        default:
          return "Share as Image";
      }
    }
  }

  /// Get share button subtitle based on content type
  String _getShareSubtitle() {
    if (isScreenShare) {
      return "Share entire screen as image with others";
    } else {
      switch (contentType) {
        case 'chunk':
          return "Share this chunk as beautiful image";
        case 'definition':
          return "Share this definition as beautiful image";
        case 'verse':
          return "Share this verse as beautiful image";
        case 'chat':
          return "Share message with others";
        default:
          return "Share as beautiful image";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors?.surface ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeColors?.onSurfaceDisable ?? Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getThemeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.share,
                        color: _getThemeColor,
                        size: 20,
                      ),
                    ),
                    TdResGaps.h_12,
                    Expanded(
                      child: Text(
                        'Share Options',
                        style: TdResTextStyles.h3.copyWith(
                          color: themeColors?.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: themeColors?.onSurface,
                      ),
                    ),
                  ],
                ),
                
                TdResGaps.v_24,
                
                // Share options
                _buildShareOption(
                  context,
                  icon: Icons.copy,
                  title: _getCopyTitle(),
                  subtitle: _getCopySubtitle(),
                  onTap: onCopyText,
                ),
                
                TdResGaps.v_16,
                
                _buildShareOption(
                  context,
                  icon: Icons.image,
                  title: _getShareTitle(),
                  subtitle: _getShareSubtitle(),
                  onTap: onShareImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColors?.onSurface.withOpacity(0.05) ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColors?.onSurface.withOpacity(0.1) ?? Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getThemeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: _getThemeColor,
                size: 24,
              ),
            ),
            TdResGaps.h_16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TdResTextStyles.h5.copyWith(
                      color: themeColors?.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TdResGaps.v_4,
                  Text(
                    subtitle,
                    style: TdResTextStyles.p2.copyWith(
                      color: themeColors?.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: themeColors?.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

