import 'package:dharak_flutter/app/types/citation/verse_citation.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerseCitationModal extends StatelessWidget {
  final VerseCitationRM citation;
  final AppThemeColors? themeColors;

  const VerseCitationModal({
    Key? key,
    required this.citation,
    required this.themeColors,
  }) : super(key: key);

  Color get _getThemeColor {
    return themeColors?.primary ?? Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors?.surface ?? Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(TdResDimens.dp_20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: TdResDimens.dp_8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeColors?.onSurfaceDisable ?? Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(TdResDimens.dp_24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon (matching definition citation modal)
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(TdResDimens.dp_8),
                        decoration: BoxDecoration(
                          color: _getThemeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.format_quote,
                          color: _getThemeColor,
                          size: TdResDimens.dp_20,
                        ),
                      ),
                      TdResGaps.h_12,
                      Expanded(
                        child: Text(
                          'Citation Formats',
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
                  
                  // Footnote Citation
                  _buildCitationFormat(
                    context,
                    'Footnote',
                    citation.footnote,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationFormat(BuildContext context, String formatName, String citationText) {
    return Container(
      margin: EdgeInsets.only(bottom: TdResDimens.dp_16),
      padding: EdgeInsets.all(TdResDimens.dp_16),
      decoration: BoxDecoration(
        color: themeColors?.onSurfaceLowest ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(TdResDimens.dp_12),
        border: Border.all(
          color: themeColors?.onSurfaceDisable ?? Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatName,
                style: TdResTextStyles.h5.copyWith(
                  color: themeColors?.onSurface ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyCitation(context, citationText, formatName),
                icon: Icon(
                  Icons.copy,
                  size: 16,
                  color: _getThemeColor,
                ),
                label: Text(
                  'Copy',
                  style: TdResTextStyles.h6.copyWith(
                    color: _getThemeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          
          TdResGaps.v_8,
          
          Text(
            citationText,
            style: TdResTextStyles.h6.copyWith(
              color: themeColors?.onSurface ?? Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _copyCitation(BuildContext context, String citation, String formatName) {
    Clipboard.setData(ClipboardData(text: citation));
    
    // Show a quick feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$formatName citation copied to clipboard!',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: _getThemeColor,
      ),
    );
  }
}