import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/args.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/controller.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/cubit_states.dart';
import 'package:dharak_flutter/app/ui/shared/common/scrollbar/fix/index.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';

import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/markdown.dart';

class BookChunkBookmarksModal extends StatefulWidget {
  final BookChunkBookmarksArgsRequest mRequestArgs;
  const BookChunkBookmarksModal({super.key, required this.mRequestArgs});
  @override
  BookChunkBookmarksModalState createState() => BookChunkBookmarksModalState();
}

class BookChunkBookmarksModalState extends State<BookChunkBookmarksModal> {
  BookChunkBookmarksController mBloc = Modular.get<BookChunkBookmarksController>();

  var mLogger = Logger();
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  final GlobalKey<ScaffoldState> _mScaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      mBloc.initData(widget.mRequestArgs);
      //
      // TODO set argument request
      // mBloc.setAuthCase(widget.authCase);
      // mBloc.setModalState(AuthUiConstants.STATE_BOTTOM_SHEET);
    });

    // _subscribeCubit();
  }

  @override
  Widget build(BuildContext context) {
    prepareTheme(context);
    return BlocListener<BookChunkBookmarksController, BookChunkBookmarksCubitState>(
      bloc: mBloc,
      listener: (context, state) {
        if (state.result != null) {
          // Check for modal result
          Navigator.of(context).pop(state.result);
        }
      },
      child: BlocBuilder<BookChunkBookmarksController, BookChunkBookmarksCubitState>(
        bloc: mBloc,
        buildWhen: (previous, current) =>
            previous.isLoading != current.isLoading ||
            previous.isInitialized != current.isInitialized ||
            previous.bookmarkedChunks != current.bookmarkedChunks,
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              color: themeColors.surface,
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
                    color: themeColors.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Content
                Flexible(
                  child: state.isLoading && !state.isInitialized
                      ? Container(
                          height: 320,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        )
                      : _widgetContent(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void prepareTheme(BuildContext context) {
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
  }

  Widget _widgetAppbar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: TdResDimens.dp_16,
        vertical: TdResDimens.dp_12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "My Bookmarks",
              style: TdResTextStyles.h3.copyWith(color: themeColors.onSurface),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: themeColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: 320,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // Padding(
        //   padding: EdgeInsets.symmetric(
        //     horizontal: TdResDimens.dp_16,
        //     vertical: TdResDimens.dp_16,
        //   ),
        //   child: _widgetAppbar(context),
        // ),
        _widgetAppbar(context),
        TdResGaps.line,

        Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: Container(
            constraints: const BoxConstraints(minHeight: 220),
            child: ScrollbarFix(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _widgetChunkList(),
              ),
            ),
          ),
        ),

        // _widgetChunkList(),
        // if (appThemeDisplay.breakpointType == BreakpointType.sm)
        //   ..._widgetHeading(context),

        // if (appThemeDisplay?.breakpointType != BreakpointType.sm)
        //   ..._widgetHeading(context),
        TdResGaps.v_8,

        //  .._widgetHeading(context) : SizedBox.shrink(),
        if (!appThemeDisplay.isSamllHeight)
          const SizedBox(width: TdResDimens.dp_16, height: TdResDimens.dp_16),
      ],
      ),
    );
  }

  Widget _widgetChunkList() {
    return BlocBuilder<BookChunkBookmarksController, BookChunkBookmarksCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) =>
              current.bookmarkedChunks != previous.bookmarkedChunks ||
              current.removedChunkIds != previous.removedChunkIds,
      builder: (context, state) {
        print('🔖 BookChunkList: State - bookmarkedChunks: ${state.bookmarkedChunks?.length ?? 0}, isLoading: ${state.isLoading}, isInitialized: ${state.isInitialized}');
        
        if (state.bookmarkedChunks == null || state.bookmarkedChunks!.isEmpty) {
          return Container(
            constraints: const BoxConstraints(minHeight: 220),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 48,
                    color: themeColors.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: TdResTextStyles.h4.copyWith(
                      color: themeColors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your bookmarked content will appear here',
                    style: TdResTextStyles.p2.copyWith(
                      color: themeColors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Container(
          constraints: const BoxConstraints(minHeight: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: state.bookmarkedChunks!
                .where((chunk) => !state.removedChunkIds.contains(chunk.chunkRefId))
                .map((chunk) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  child: BookChunkItemLightweightWidget(
                    appThemeDisplay: appThemeDisplay,
                    themeColors: themeColors,
                    chunk: chunk,
                    searchQuery: '', // No search query in bookmarks
                    onClickCopy: (chunkRefId) => _handleCopy(chunk),
                    onClickShare: (widgetKey) => _showShareOptions(chunk, widgetKey),
                    onClickExternalUrl: (urlLink) => _launchExternalUrl(urlLink),
                    onClickCitation: (chunkRefId) => _showCitationModal(chunk),
                    onSourceClick: (url) => _launchExternalUrl(url),
                    onNavigatePrevious: () {}, // No navigation in bookmarks modal
                    onNavigateNext: () {}, // No navigation in bookmarks modal
                  ),
                ))
                .toList(),
          ),
        );
      },
    );
  }

  // Helper methods for the BookChunkItemLightweightWidget callbacks
  void _handleCopy(BookChunkRM chunk) {
    if (chunk.text != null) {
      Clipboard.setData(ClipboardData(text: chunk.text!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text copied to clipboard!'),
          backgroundColor: themeColors.primary,
        ),
      );
    }
  }

  void _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch URL: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showShareOptions(BookChunkRM chunk, GlobalKey widgetKey) {
    if (chunk.chunkRefId == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareModal(
        themeColors: themeColors,
        textToShare: chunk.text ?? '',
        onCopyText: () {
          Navigator.pop(context);
          _handleCopy(chunk);
        },
        onShareImage: () {
          Navigator.pop(context);
          // Handle share image
        },
        contentType: 'chunk',
      ),
    );
  }

  void _showCitationModal(BookChunkRM chunk) {
    if (chunk.chunkRefId == null) return;
    
    // For now, show a simple message. Citation modal can be implemented later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Citation for chunk ${chunk.chunkRefId}'),
        backgroundColor: themeColors.primary,
      ),
    );
  }
}
