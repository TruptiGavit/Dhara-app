import 'package:dharak_flutter/app/types/citation/citation.dart';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookCitationModal extends StatefulWidget {
  final int chunkRefId;
  final CitationRepository citationRepo;

  const BookCitationModal({
    Key? key,
    required this.chunkRefId,
    required this.citationRepo,
  }) : super(key: key);

  @override
  State<BookCitationModal> createState() => _BookCitationModalState();
}

class _BookCitationModalState extends State<BookCitationModal> {
  CitationRM? citation;
  bool isLoading = true;
  String? error;
  AppThemeColors? themeColors;

  @override
  void initState() {
    super.initState();
    _loadCitation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>();
  }

  Future<void> _loadCitation() async {
    try {
      final result = await widget.citationRepo.getChunkCitation(widget.chunkRefId);
      if (mounted) {
        setState(() {
          citation = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Color get _getThemeColor {
    return themeColors?.primary ?? Colors.blue;
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
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: _getThemeColor),
        ),
      );
    }

    if (error != null) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load citation',
                style: TdResTextStyles.h4.copyWith(
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                error!,
                style: TdResTextStyles.p2.copyWith(
                  color: themeColors?.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (citation == null) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No citation available',
            style: TdResTextStyles.h4.copyWith(
              color: themeColors?.onSurface,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon
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
        if (citation!.apa.isNotEmpty) _buildCitationFormat(context, 'APA', citation!.apa),
        if (citation!.mla.isNotEmpty) _buildCitationFormat(context, 'MLA', citation!.mla),
        if (citation!.harvard.isNotEmpty) _buildCitationFormat(context, 'Harvard', citation!.harvard),
        if (citation!.chicago.isNotEmpty) _buildCitationFormat(context, 'Chicago', citation!.chicago),
        if (citation!.vancouver.isNotEmpty) _buildCitationFormat(context, 'Vancouver', citation!.vancouver),
      ],
    );
  }

  Widget _buildCitationFormat(BuildContext context, String format, String citationText) {
    return Container(
      margin: EdgeInsets.only(bottom: TdResDimens.dp_16),
      padding: EdgeInsets.all(TdResDimens.dp_16),
      decoration: BoxDecoration(
        color: _getThemeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TdResDimens.dp_8),
        border: Border.all(
          color: _getThemeColor.withOpacity(0.2),
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
                format,
                style: TdResTextStyles.h4.copyWith(
                  color: _getThemeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () => _copyCitation(context, citationText),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: TdResDimens.dp_12,
                    vertical: TdResDimens.dp_6,
                  ),
                  decoration: BoxDecoration(
                    color: _getThemeColor,
                    borderRadius: BorderRadius.circular(TdResDimens.dp_16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        color: themeColors?.surface ?? Colors.white,
                        size: TdResDimens.dp_14,
                      ),
                      TdResGaps.h_4,
                      Text(
                        'Copy',
                        style: TdResTextStyles.caption.copyWith(
                          color: themeColors?.surface ?? Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          TdResGaps.v_12,
          SelectableText(
            citationText,
            style: TdResTextStyles.p2.copyWith(
              color: themeColors?.onSurface,
              height: 1.5,
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
        content: Text('Citation copied to clipboard'),
        backgroundColor: _getThemeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 2),
      ),
    );
  }
}



