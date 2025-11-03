import 'package:dharak_flutter/app/types/citation/citation.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CitationModal extends StatelessWidget {
  final CitationRM citation;
  final AppThemeColors? themeColors;
  final String contentType; // 'verse' or 'definition'

  const CitationModal({
    Key? key,
    required this.citation,
    required this.themeColors,
    required this.contentType,
  }) : super(key: key);

  Color get _getThemeColor {
    return contentType == 'definition' 
        ? Colors.red 
        : (themeColors?.primary ?? Colors.green);
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
                // Header
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
          
          // Citation formats
          _buildCitationFormat(context, 'APA', citation.apa),
          TdResGaps.v_16,
          _buildCitationFormat(context, 'MLA', citation.mla),
          TdResGaps.v_16,
          _buildCitationFormat(context, 'Harvard', citation.harvard),
          TdResGaps.v_16,
          _buildCitationFormat(context, 'Chicago', citation.chicago),
          TdResGaps.v_16,
          _buildCitationFormat(context, 'Vancouver', citation.vancouver),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationFormat(BuildContext context, String title, String citation) {
    return Container(
      padding: EdgeInsets.all(TdResDimens.dp_16),
      decoration: BoxDecoration(
        color: themeColors?.onSurface.withOpacity(0.05) ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(TdResDimens.dp_12),
        border: Border.all(
          color: themeColors?.onSurface.withOpacity(0.1) ?? Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TdResTextStyles.h5.copyWith(
                  color: _getThemeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _copyCitation(context, citation),
                icon: Icon(
                  Icons.copy,
                  size: TdResDimens.dp_18,
                  color: themeColors?.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          TdResGaps.v_8,
          Text(
            citation,
            style: TdResTextStyles.p2.copyWith(
              color: themeColors?.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _copyCitation(BuildContext context, String citation) {
    Clipboard.setData(ClipboardData(text: citation));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Citation copied to clipboard'),
        backgroundColor: _getThemeColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

