import 'dart:async';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/app/domain/share/repo.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';

import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart'; // Old format used by BooksController
import 'package:dharak_flutter/app/types/books/book_chunk.dart' as new_book_chunk; // New format used by widget
import 'package:dharak_flutter/app/ui/widgets/citation_modal.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/modal.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/args.dart';
import 'package:dharak_flutter/app/utils/util_string.dart';
import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BooksPage extends StatefulWidget {
  final BooksArgsRequest mRequestArgs;
  final String title;
  const BooksPage({
    super.key,
    required this.mRequestArgs,
    this.title = 'BooksPage',
  });
  @override
  BooksPageState createState() => BooksPageState();
}

class BooksPageState extends State<BooksPage> {
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  BooksController mBloc = Modular.get<BooksController>();

  // 🚀 PERFORMANCE: Removed SliverAnimatedList - now using SliverList.builder
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Books module blue color
  static const Color _booksBlue = Colors.blue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.books);
      mBloc.initData(widget.mRequestArgs);
    });
  }

  @override
  void dispose() {
    // Only dispose the controller if this page is NOT embedded in unified search
    if (widget.mRequestArgs.default1 != "embedded_search") {
      mBloc.close();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    prepareTheme(context);
    mLogger.d(
      "message: ${appThemeDisplay.breakpointType} ${appThemeDisplay.breakpointType == BreakpointType.sm}",
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<BooksController, BooksCubitState>(
          bloc: mBloc,
          listenWhen: (previous, current) =>
              (previous.isInitialized != current.isInitialized),
          listener: (context, state) {
            if (state.isInitialized == true) {}
          },
        ),
        BlocListener<BooksController, BooksCubitState>(
          bloc: mBloc,
          listenWhen: (previous, current) =>
              previous.toastCounter != current.toastCounter,
          listener: (context, state) {
            _showToast(state.message ?? "");
          },
        ),
        // 🚀 PERFORMANCE: Removed SliverAnimatedList listener - now using efficient SliverList.builder
      ],
      child: _widgetContents(context),
    );
  }

  Future<void> copyChunkToClipboard(int chunkRefId) async {
    try {
      final shareRepo = Modular.get<ShareRepository>();
      final success = await shareRepo.copyChunkToClipboard(chunkRefId.toString());

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Chunk copied to clipboard!",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: _booksBlue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to copy chunk. Please try again.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error copying chunk. Please try again.",
            style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> copyAllChunksToClipboard() async {
    try {
      final shareRepo = Modular.get<ShareRepository>();
      final searchedQuery = mBloc.mSearchController.text.trim();

      if (searchedQuery.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No query available to copy chunks for.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
          ),
        );
        return;
      }

      final success = await shareRepo.copyAllChunksToClipboard(searchedQuery);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "All chunks copied to clipboard!",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: _booksBlue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to copy chunks. Please try again.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error copying chunks. Please try again.",
            style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showShareModal(String text, String chunkId, [GlobalKey? widgetKey]) {
    ShareModal.show(
      context: context,
      themeColors: themeColors,
      textToShare: text,
      onCopyText: () {
        final chunkRefId = int.tryParse(chunkId);
        if (chunkRefId != null) {
          copyChunkToClipboard(chunkRefId);
        } else {
          // Fallback to legacy copy if ID is not a valid int
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Copied to clipboard!",
                style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
              ),
              backgroundColor: _booksBlue,
            ),
          );
        }
      },
      onShareImage: () => _handleShareImage(chunkId, text, widgetKey),
      contentType: 'chunk', // Blue theme for chunks
    );
  }

  void showScreenShareModal() {
    ShareModal.show(
      context: context,
      themeColors: themeColors,
      textToShare: mBloc.getAllText(),
      onCopyText: () => copyAllChunksToClipboard(),
      onShareImage: () => _handleScreenShare(),
      isScreenShare: true,
      contentType: 'chunk', // Blue theme for books page
    );
  }

  Future<void> _handleShareImage(String chunkId, String chunkText, GlobalKey? widgetKey) async {
    try {
      final shareRepo = Modular.get<ShareRepository>();
      bool success;

      if (widgetKey != null) {
        success = await shareRepo.shareChunkAsImage(
          widgetKey: widgetKey,
          chunkId: chunkId,
          chunkText: chunkText,
          searchedQuery: mBloc.mSearchController.text.trim(),
        );
      } else {
        success = await shareRepo.shareChunkAsText(
          chunkId: chunkId,
          chunkText: chunkText,
          searchTerm: mBloc.mSearchController.text.trim(),
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Shared successfully!",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: _booksBlue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to share. Please try again.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    } on Exception catch (e) {
      if (e.toString().contains('too long to share as image')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Chunk is too long to share as image. Please use text sharing instead.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: themeColors.errorColor,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: ${e.toString()}",
            style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
          ),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _handleScreenShare() async {
    try {
      final shareRepo = Modular.get<ShareRepository>();
      await _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      await Future.delayed(const Duration(milliseconds: 350));
      final searchedQuery = mBloc.mSearchController.text.trim();
      final screenTitle = searchedQuery.isNotEmpty
          ? 'Books: "$searchedQuery" - Dhara App'
          : 'Books - Dhara App';
      final success = await shareRepo.shareScreenCapture(
        screenTitle: screenTitle,
        screenContext: context,
        searchTerm: searchedQuery.isNotEmpty ? searchedQuery : null,
        repaintBoundaryKey: _repaintBoundaryKey,
      );
      if (!mounted) return;
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Screen shared successfully!',
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: _booksBlue,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share screen',
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share screen',
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void launchExternalUrl(String? urlLink) {
    if (urlLink != null) {
      var uriLinkUri = Uri.parse(urlLink);
      launchUrl(uriLinkUri);
    }
  }

  Widget _widgetContents(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Container(
        decoration: BoxDecoration(
          color: themeColors.surface,
          // Subtle gradient background for visual appeal
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColors.surface,
              themeColors.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                _widgetTitle(),
                // Conditionally show search bar based on hideSearchBar parameter
                if (!widget.mRequestArgs.hideSearchBar)
                  SliverAppBar(
                    pinned: true,
                    leadingWidth: 0,
                    actionsPadding: EdgeInsets.zero,
                    floating: true,
                    backgroundColor: themeColors.surface,
                    surfaceTintColor: themeColors.surface,
                    title: _widgetSearch(),
                    actions: [
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: themeColors.onSurface,
                        ),
                        onSelected: (String value) {
                          switch (value) {
                            case 'bookmarks':
                              _showBookmarksModal();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'bookmarks',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmarks,
                                  color: themeColors.onSurface,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'My Bookmarks',
                                  style: TdResTextStyles.buttonSmall.copyWith(
                                    color: themeColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                BlocBuilder<BooksController, BooksCubitState>(
                  bloc: mBloc,
                  buildWhen: (previous, current) =>
                      current.isLoading != previous.isLoading ||
                      current.bookChunks != previous.bookChunks,
                  builder: (context, state) {
                    if (state.isLoading == true || state.bookChunks.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: CommonContainer(
                        appThemeDisplay: appThemeDisplay,
                        child: Container(
                          margin: EdgeInsets.only(top: TdResDimens.dp_24),
                          height: TdResDimens.dp_48,
                          child: Row(
                            children: [
                              Flexible(
                                flex: 1,
                                fit: FlexFit.tight,
                                child: Text(
                                  "Book Chunks",
                                  textAlign: TextAlign.start,
                                  style: TdResTextStyles.h4Medium.copyWith(
                                    color: themeColors.onSurface.withAlpha(0xb6),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  showScreenShareModal();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: _booksBlue.withAlpha(0x22),
                                ),
                                label: Text(
                                  "Share",
                                  textAlign: TextAlign.start,
                                  style: TdResTextStyles.buttonSmall.copyWith(
                                    color: _booksBlue,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.share,
                                  color: _booksBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<BooksController, BooksCubitState>(
                  bloc: mBloc,
                  buildWhen: (previous, current) =>
                      current.isLoading != previous.isLoading ||
                      current.bookChunks != previous.bookChunks ||
                      current.searchCounter != previous.searchCounter,
                  builder: (context, state) {
                    if (state.isLoading == true) {
                      return SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: TdResDimens.dp_24,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _booksBlue,
                            ),
                          ),
                        ),
                      );
                    } else if (state.bookChunks.isEmpty && state.searchCounter != 0) {
                      return SliverToBoxAdapter(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 400,
                            minHeight: 200,
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: themeColors.onSurfaceDisable,
                              ),
                              SizedBox(height: TdResDimens.dp_16),
                              Text(
                                "No chunks found",
                                style: TdResTextStyles.h3.copyWith(
                                  color: themeColors.onSurfaceDisable,
                                ),
                              ),
                              SizedBox(height: TdResDimens.dp_8),
                              Text(
                                "Try a different search term",
                                style: TdResTextStyles.h5.copyWith(
                                  color: themeColors.onSurfaceMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (state.bookChunks.isNotEmpty) {
                      return const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      );
                    } else {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                  },
                ),
                BlocBuilder<BooksController, BooksCubitState>(
                  bloc: mBloc,
                  buildWhen: (previous, current) =>
                      current.isLoading != previous.isLoading ||
                      current.bookChunks != previous.bookChunks ||
                      current.searchCounter != previous.searchCounter,
                  builder: (context, state) {
                    if (state.isLoading == true) {
                      return const SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      );
                    }
                    print("📱 BlocBuilder: Rendering ${state.bookChunks.length} chunks");
                    return SliverList.builder(
                      itemCount: state.bookChunks.length,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          key: ValueKey('chunk_${state.bookChunks[index].chunkRefId}'),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          child: BookChunkItemLightweightWidget(
                            appThemeDisplay: appThemeDisplay,
                            themeColors: themeColors,
                            chunk: _convertChunk(state.bookChunks[index]), // Convert old format to new
                            searchQuery: state.searchQuery, // ✅ Pass search query for share functionality
                            onClickCopy: (chunkRefId) => copyChunkToClipboard(chunkRefId),
                            onClickShare: (widgetKey) => showShareModal(
                              state.bookChunks[index].text ?? '',
                              state.bookChunks[index].chunkRefId?.toString() ?? '',
                              widgetKey,
                            ),
                            onClickExternalUrl: (urlLink) => launchExternalUrl(urlLink),
                            onClickCitation: (chunkRefId) => showCitationModal(chunkRefId),
                            onSourceClick: (url) => launchExternalUrl(url),
                            // ✅ Navigation callbacks - now properly connected
                            onNavigatePrevious: () => _handlePreviousChunk(state.bookChunks[index]),
                            onNavigateNext: () => _handleNextChunk(state.bookChunks[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _widgetTitle() {
    return BlocBuilder<BooksController, BooksCubitState>(
      bloc: mBloc,
      buildWhen: (previous, current) =>
          current.searchCounter != previous.searchCounter,
      builder: (context, state) {
        // Hide welcome message if explicitly requested or if search has been performed
        if (widget.mRequestArgs.hideWelcomeMessage || state.searchCounter != 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_20),
              child: Column(
                spacing: TdResDimens.dp_24,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_rounded,
                    size: 80,
                    color: _booksBlue.withOpacity(0.8),
                  ),
                  Text(
                    "Welcome to Books",
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(1.0),
                    style: (appThemeDisplay.isSamllHeight
                            ? TdResTextStyles.h1Bold
                            : TdResTextStyles.h0Bold)
                        .copyWith(
                          color: _booksBlue,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Search and explore ancient texts",
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(1.0),
                    style: (appThemeDisplay.isSamllHeight
                            ? TdResTextStyles.h4Medium
                            : TdResTextStyles.h3Medium)
                        .copyWith(color: themeColors.onSurfaceHigh),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _widgetSearch() {
    return CommonContainer(
      appThemeDisplay: appThemeDisplay,
      defaultPadding: 2,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: BorderRadius.circular(TdResDimens.dp_12),
          border: Border.all(
            color: _booksBlue,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _booksBlue.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlocBuilder<BooksController, BooksCubitState>(
              bloc: mBloc,
              buildWhen: (previous, current) =>
                  current.formSearchText != previous.formSearchText,
              builder: (context, state) {
                return Flexible(
                  flex: 1,
                  child: TextFormField(
                    controller: mBloc.mSearchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: TdResTextStyles.h5.merge(
                      TextStyle(
                        color: Color.alphaBlend(
                          TdResColors.colorInput.withOpacity(0.2),
                          themeColors.onSurface,
                        ),
                      ),
                    ),
                    focusNode: _focusNode,
                    maxLines: 1,
                    textInputAction: TextInputAction.search,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.text,
                    onChanged: (String value) {
                      mBloc.onFormSearchTextChanged(value);
                    },
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        FocusScope.of(context).unfocus();
                        mBloc.onFormSubmit();
                      }
                    },
                    decoration: TdResDecorations.inputSmallDecorationInner(
                      themeColors,
                    ).copyWith(
                      hintText: "Search ancient texts and scriptures...",
                      hintStyle: TdResTextStyles.h5.copyWith(
                        color: themeColors.onSurfaceMedium,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _booksBlue,
                      ),
                      suffixIcon:
                          UtilString.isStringsEmpty(state.formSearchText)
                              ? null
                              : IconButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: TdResDimens.dp_14,
                                  ),
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    mBloc.onFormSearchTextChanged(null);
                                  },
                                  color: themeColors.onSurfaceMedium,
                                ),
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<BooksController, BooksCubitState>(
              bloc: mBloc,
              buildWhen: (previous, current) =>
                  current.isSubmitEnabled != previous.isSubmitEnabled,
              builder: (context, state) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: TdResDimens.dp_8),
                  child: ElevatedButton(
                    onPressed: state.isSubmitEnabled
                        ? () {
                            FocusScope.of(context).unfocus();
                            mBloc.onFormSubmit();
                          }
                        : null,
                    clipBehavior: Clip.hardEdge,
                    style: ElevatedButton.styleFrom(
                      shadowColor: _booksBlue.withOpacity(0.3),
                      backgroundColor: _booksBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TdResDimens.dp_16,
                        vertical: TdResDimens.dp_12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 20),
                        SizedBox(width: TdResDimens.dp_8),
                        Text("Search", style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookChunkBookmarksModal(
        mRequestArgs: BookChunkBookmarksArgsRequest(),
      ),
    );
  }

  Future<void> showCitationModal(int chunkRefId) async {
    OverlayEntry? loadingOverlay;
    try {
      final citationRepo = Modular.get<CitationRepository>();
      loadingOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: CircularProgressIndicator(
              color: _booksBlue,
            ),
          ),
        ),
      );
      Overlay.of(context).insert(loadingOverlay);
      final citation = await citationRepo.getChunkCitation(chunkRefId);
      loadingOverlay.remove();
      loadingOverlay = null;
      await Future.delayed(const Duration(milliseconds: 50));
      if (citation != null && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: true,
          isDismissible: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.67,
          ),
          builder: (modalContext) => CitationModal(
            citation: citation,
            themeColors: themeColors,
            contentType: 'chunk',
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Citation not available for this chunk.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: _booksBlue,
          ),
        );
      }
    } catch (e) {
      if (loadingOverlay != null) {
        try {
          loadingOverlay.remove();
        } catch (_) {}
        loadingOverlay = null;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error loading citation. Please try again.",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
        ),
        backgroundColor: _booksBlue,
      ),
    );
  }

  prepareTheme(BuildContext context) {
    themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
  }

  /// Convert old BookChunkRM format to new format for the widget
  new_book_chunk.BookChunkRM _convertChunk(BookChunkRM oldChunk) {
    return new_book_chunk.BookChunkRM(
      text: oldChunk.text,
      chunkRefId: oldChunk.chunkRefId,
      score: oldChunk.score,
      reference: oldChunk.reference,
      // Old format doesn't have these fields, so set to null for now
      sourceTitle: null,
      sourceUrl: null,
      sourceType: null,
    );
  }

  /// 🔄 Handle previous chunk navigation
  void _handlePreviousChunk(BookChunkRM chunk) async {
    if (chunk.chunkRefId == null) return;
    
    print('📖 Navigate to previous chunk from: ${chunk.chunkRefId}');
    
    // Use BooksService to handle navigation (QuickSearch should update via stream)
    final booksService = BooksService.instance;
    final newChunk = await booksService.navigateChunk(chunk.chunkRefId!, false);
    
    if (newChunk != null) {
      print('✅ Books Page: Navigation successful ${chunk.chunkRefId} -> ${newChunk.chunkRefId}');
    } else {
      print('❌ Books Page: Navigation failed');
    }
  }

  /// ⏭️ Handle next chunk navigation  
  void _handleNextChunk(BookChunkRM chunk) async {
    if (chunk.chunkRefId == null) return;
    
    print('📖 Navigate to next chunk from: ${chunk.chunkRefId}');
    
    // Use BooksService to handle navigation (QuickSearch should update via stream)
    final booksService = BooksService.instance;
    final newChunk = await booksService.navigateChunk(chunk.chunkRefId!, true);
    
    if (newChunk != null) {
      print('✅ Books Page: Navigation successful ${chunk.chunkRefId} -> ${newChunk.chunkRefId}');
    } else {
      print('❌ Books Page: Navigation failed');
    }
  }
}