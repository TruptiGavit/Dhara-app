import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/share/api.dart';
import 'package:dharak_flutter/app/types/share/share_link.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Exception thrown when content is too long for image sharing
class TooLongForImageException implements Exception {
  final String message;
  TooLongForImageException(this.message);
  
  @override
  String toString() => message;
}

class ShareService {
  final ShareApiRepo _shareApiRepo;
  final Logger _logger = Logger();
  final ScreenshotController _screenshotController = ScreenshotController();

  ShareService({required ShareApiRepo shareApiRepo}) : _shareApiRepo = shareApiRepo;

  /// Captures widget as image and shares it with native apps
  Future<bool> shareWidgetAsImage({
    required GlobalKey widgetKey,
    required String contentType, // 'verse' or 'definition'
    required String contentId,
    required String contentText,
    String? customMessage,
    String? searchedWord, // The word user searched for (for definitions)
  }) async {
    try {
      _logger.i('Starting share widget as image for $contentType:$contentId');

      // Check if content is too long for image sharing (prevents corruption)
      const maxCharacterLimit = 64000;
      if (contentText.length > maxCharacterLimit) {
        _logger.w('Content too long for image sharing: ${contentText.length} characters (limit: $maxCharacterLimit)');
        throw TooLongForImageException('Content is too long to share as image. Please use text sharing instead.');
      }

      // Generate share link first
      final shareLink = await _generateShareLink(contentType, contentId);
      if (shareLink == null) {
        _logger.e('Failed to generate share link');
        return false;
      }

      // Smart content handling for image sharing
      final boundary = widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _logger.e('Cannot find render boundary for widget');
        // Fallback to text sharing
        return await shareText(
          contentType: contentType,
          contentId: contentId,
          contentText: contentText,
          customMessage: customMessage,
        );
      }

      final size = boundary.size;
      const maxOptimalHeight = 2000.0; // Height for optimal quality (more aggressive)

      // If content is too long for good quality, create a truncated version
      if (size.height > maxOptimalHeight) {
        _logger.w('Content is long (${size.height}px). Creating truncated image for better quality.');
        return await _shareWithTruncatedImage(
          widgetKey: widgetKey,
          contentType: contentType,
          contentId: contentId,
          contentText: contentText,
          shareLink: shareLink,
          customMessage: customMessage,
          searchedWord: searchedWord,
        );
      }

      // Capture widget as image (no banner overlay for definitions)
      final imageBytes = await _captureTruncatedWidgetAsImage(widgetKey);
        
      if (imageBytes == null) {
        _logger.e('Failed to capture widget as image. Falling back to text sharing.');
        return await shareText(
          contentType: contentType,
          contentId: contentId,
          contentText: contentText,
          customMessage: customMessage,
        );
      }

      // Save image to temporary file
      final imageFile = await _saveImageToFile(imageBytes, '$contentType\_$contentId');
      if (imageFile == null) {
        _logger.e('Failed to save image file');
        return false;
      }

      // Create share message
      final shareMessage = customMessage ?? _createShareMessage(contentType, contentText, shareLink.shortUrl, searchedWord);

      // Share using native dialog
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: shareMessage,
        subject: _getShareSubject(contentType),
      );

      // Track the share using new unified API
      if (contentType == 'definition') {
        await logImageShareActivity(word: searchedWord, defId: contentId);
      } else if (contentType == 'verse') {
        await logImageShareActivity(verseId: contentId);
      }

      _logger.i('Share completed successfully');
      return true;
    } on TooLongForImageException {
      // Rethrow the specific exception so UI can handle it
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Error sharing widget as image', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Shares text with native apps
  Future<bool> shareText({
    required String contentType,
    required String contentId,
    required String contentText,
    String? customMessage,
    String? searchTerm, // The search term user used
  }) async {
    try {
      _logger.i('Starting share text for $contentType:$contentId');

      // Generate share link
      final shareLink = await _generateShareLink(contentType, contentId);
      if (shareLink == null) {
        _logger.e('Failed to generate share link');
        return false;
      }

      // Create share message
      final shareMessage = customMessage ?? _createShareMessage(contentType, contentText, shareLink.shortUrl, searchTerm);

      // Share using native dialog
      await Share.share(
        shareMessage,
        subject: _getShareSubject(contentType),
      );

      // Track the share using new unified API
      if (contentType == 'definition') {
        await _shareApiRepo.getShareContentForCopy(word: searchTerm, defId: contentId);
      } else if (contentType == 'verse') {
        await _shareApiRepo.getShareContentForCopy(verseId: contentId);
      } else if (contentType == 'chunk') {
        // For chunks, we'll skip the tracking for now since the API doesn't support it yet
        _logger.d('Skipping share tracking for chunk: $contentId');
      }

      _logger.i('Text share completed successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Error sharing text', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Shares long content with a truncated image and full text
  Future<bool> _shareWithTruncatedImage({
    required GlobalKey widgetKey,
    required String contentType,
    required String contentId,
    required String contentText,
    required ShareLinkRM shareLink,
    String? customMessage,
    String? searchedWord,
  }) async {
    try {
      // Capture widget as image (no banner overlay)
      final imageBytes = await _captureTruncatedWidgetAsImage(widgetKey);
        
      if (imageBytes == null) {
        _logger.e('Failed to capture truncated image. Falling back to text sharing.');
        return await shareText(
          contentType: contentType,
          contentId: contentId,
          contentText: contentText,
          customMessage: customMessage,
        );
      }

      // Save truncated image to temporary file
      final imageFile = await _saveImageToFile(imageBytes, '${contentType}_${contentId}_truncated');
      if (imageFile == null) {
        _logger.e('Failed to save truncated image file');
        return false;
      }

      // Create message indicating this is a preview
      final previewMessage = customMessage ?? _createTruncatedShareMessage(contentType, contentText, shareLink.shortUrl, searchedWord);

      // Share truncated image with explanation
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: previewMessage,
        subject: _getShareSubject(contentType),
      );

      // Track the share using new unified API  
      if (contentType == 'definition') {
        await logImageShareActivity(word: searchedWord, defId: contentId);
      } else if (contentType == 'verse') {
        await logImageShareActivity(verseId: contentId);
      }

      _logger.i('Successfully shared truncated image for long content');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Error sharing truncated image', error: e, stackTrace: stackTrace);
      // Fallback to text sharing
      return await shareText(
        contentType: contentType,
        contentId: contentId,
        contentText: contentText,
        customMessage: customMessage,
      );
    }
  }

  /// Captures only the top portion of a widget with 9:16 aspect ratio
  Future<Uint8List?> _captureTruncatedWidgetAsImage(GlobalKey widgetKey) async {
    try {
      // Find the render object
      final RenderRepaintBoundary boundary = widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final size = boundary.size;
      _logger.d('Original widget size: ${size.width} x ${size.height}');

      // Calculate optimal dimensions with 9:16 aspect ratio
      final maxWidth = size.width;
      final maxHeight = (maxWidth * 16 / 9).clamp(0.0, 2500.0); // Max 2500px height for quality
      
      _logger.d('Target truncated size: ${maxWidth} x $maxHeight (9:16 ratio)');

      // If content fits within our ratio, use full content
      if (size.height <= maxHeight) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }

      // For long content, we need to create a cropped version
      return await _createCroppedImage(boundary, maxWidth, maxHeight);
    } catch (e, stackTrace) {
      _logger.e('Error capturing truncated widget as image', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Creates a cropped image from the top portion of the widget
  Future<Uint8List?> _createCroppedImage(RenderRepaintBoundary boundary, double targetWidth, double targetHeight) async {
    try {
      // Capture the full image first with high quality
      final ui.Image fullImage = await boundary.toImage(pixelRatio: 2.0);
      
      _logger.d('Full image size: ${fullImage.width} x ${fullImage.height}');
      
      // Calculate crop dimensions (take from top)
      final cropWidth = fullImage.width;
      final cropHeight = (fullImage.height * (targetHeight / boundary.size.height)).round();
      
      _logger.d('Cropping to: ${cropWidth} x $cropHeight');

      // Create a picture recorder to draw the cropped portion
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw only the top portion of the image
      final srcRect = Rect.fromLTWH(0, 0, fullImage.width.toDouble(), cropHeight.toDouble());
      final dstRect = Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble());
      
      canvas.drawImageRect(fullImage, srcRect, dstRect, Paint());
      
      // Convert to image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropWidth, cropHeight);
      
      // Convert to bytes
      final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      
      // Clean up
      fullImage.dispose();
      croppedImage.dispose();
      picture.dispose();
      
      return byteData?.buffer.asUint8List();
    } catch (e, stackTrace) {
      _logger.e('Error creating cropped image', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Saves image bytes to a temporary file
  Future<File?> _saveImageToFile(Uint8List imageBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/$fileName\_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);

      await imageFile.writeAsBytes(imageBytes);
      _logger.d('Image saved to: $imagePath');

      return imageFile;
    } catch (e, stackTrace) {
      _logger.e('Error saving image to file', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Generates share link
  Future<ShareLinkRM?> _generateShareLink(String contentType, String contentId) async {
    try {
      _logger.d('Generating share link for $contentType:$contentId');

      // Simple Play Store link for this release
      const playStoreUrl = 'https://play.google.com/store/apps/details?id=in.bheri.dhara';

      return ShareLinkRM(
        shareId: 'share_${DateTime.now().millisecondsSinceEpoch}',
        shortUrl: playStoreUrl,
        deepLink: playStoreUrl,
        shareMessage: _createShareMessage(contentType, '', playStoreUrl),
      );
    } catch (e, stackTrace) {
      _logger.e('Error generating share link', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Creates appropriate share message based on content type
  String _createShareMessage(String contentType, String contentText, String shareUrl, [String? searchTerm]) {
    switch (contentType) {
      case 'verse':
        final searchText = searchTerm ?? 'verse';
        return 'Hey! I just searched for the verse "$searchText" on Dhara — look what I found!\n\n'
            'Have a shloka, mantra, verse or kriti humming in your mind?\n\n'
            'Just type in the parts you remember to get started!\n\n'
            '🔍 Search, cite, share and read in the script of your choice!\n\n'
            '✨ Find more such verses only in Dhara.\n\n'
            '📲 Download now on https://play.google.com/store/apps/details?id=in.bheri.dhara';

      case 'definition':
        final searchText = searchTerm ?? 'word';
        return 'Hey! I just searched for the word "$searchText" on Dhara — look what I found!\n\n'
            'Explore names, words, places or concepts. Enter a single word & discover the world of Indic Knowledge with our smart AI word lookup.\n\n'
            '🔍Search, cite, share more such words only on Dhara.\n\n'
            '📲 Download now on https://play.google.com/store/apps/details?id=in.bheri.dhara';

      case 'chunk':
        final searchText = searchTerm ?? 'text';
        return 'Hey! I just found this amazing content about "$searchText" on Dhara — check it out!\n\n'
            'Discover profound texts, books, and knowledge from ancient and modern sources with Dhara\'s smart search.\n\n'
            '🔍 Search, cite, share more such content only on Dhara.\n\n'
            '📲 Download now on https://play.google.com/store/apps/details?id=in.bheri.dhara';

      default:
        return 'Hey! Check this out from Dhara App:\n\n'
            'Find your favorite words and verses here!\n\n'
            'Get Dhara App → $shareUrl';
    }
  }

  /// Creates a message for truncated image shares
  String _createTruncatedShareMessage(String contentType, String contentText, String shareUrl, [String? searchTerm]) {
    return _createShareMessage(contentType, contentText, shareUrl, searchTerm);
  }

  /// Gets appropriate share subject based on content type
  String _getShareSubject(String contentType) {
    switch (contentType) {
      case 'verse':
        return 'Found this verse on Dhara App';
      case 'definition':
        return 'Found this word definition on Dhara App';
      case 'chunk':
        return 'Found this content on Dhara App';
      default:
        return 'Check this out from Dhara App';
    }
  }

  /// Copy verse content to clipboard using new unified API
  Future<bool> copyVerseToClipboard(String verseId) async {
    try {
      _logger.i('Fetching verse copy content from backend for verse ID: $verseId');
      
      final result = await _shareApiRepo.getShareContentForCopy(verseId: verseId);
      
      if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
        final shareContent = result.data!;
        await Clipboard.setData(ClipboardData(text: shareContent));
        _logger.i('Successfully copied verse content to clipboard');
        return true;
      } else {
        _logger.e('Failed to fetch verse copy content: ${result.error}');
        return false;
      }
    } catch (e) {
      _logger.e('Exception while copying verse to clipboard: $e');
      return false;
    }
  }

  /// Copy single definition content to clipboard using new unified API
  Future<bool> copyDefinitionToClipboard(String defId) async {
    try {
      _logger.i('Fetching definition copy content from backend for definition ID: $defId');
      
      final result = await _shareApiRepo.getShareContentForCopy(defId: defId);
      
      if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
        final shareContent = result.data!;
        await Clipboard.setData(ClipboardData(text: shareContent));
        _logger.i('Successfully copied definition content to clipboard');
        return true;
      } else {
        _logger.e('Failed to fetch definition copy content: ${result.error}');
        return false;
      }
    } catch (e) {
      _logger.e('Exception while copying definition to clipboard: $e');
      return false;
    }
  }

  /// Copy all definitions for a word to clipboard using new unified API
  Future<bool> copyAllDefinitionsToClipboard(String word) async {
    try {
      _logger.i('Fetching all definitions copy content from backend for word: $word');
      
      final result = await _shareApiRepo.getShareContentForCopy(word: word);
      
      if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
        final shareContent = result.data!;
        await Clipboard.setData(ClipboardData(text: shareContent));
        _logger.i('Successfully copied all definitions content to clipboard');
        return true;
      } else {
        _logger.e('Failed to fetch all definitions copy content: ${result.error}');
        return false;
      }
    } catch (e) {
      _logger.e('Exception while copying all definitions to clipboard: $e');
      return false;
    }
  }

  /// Log image sharing activity using new unified API
  Future<void> logImageShareActivity({
    String? word,
    String? defId,
    String? verseId,
  }) async {
    try {
      _logger.i('Logging image share activity - word: $word, defId: $defId, verseId: $verseId');
      
      final result = await _shareApiRepo.getShareContentForImage(
        word: word,
        defId: defId,
        verseId: verseId,
      );
      
      if (result.status == ApiResponseStatus.SUCCESS) {
        _logger.i('Successfully logged image share activity');
      } else {
        _logger.w('Failed to log image share activity: ${result.error}');
        // Don't fail the share operation if logging fails
      }
    } catch (e) {
      _logger.w('Exception while logging image share activity: $e');
      // Don't fail the share operation if logging fails
    }
  }

  /// Get verse content from backend API for sharing using new unified API
  Future<String?> getVerseShareContent(String verseId) async {
    try {
      _logger.i('Fetching verse share content from backend for verse ID: $verseId');
      
      final result = await _shareApiRepo.getShareContentForCopy(verseId: verseId);
      
      if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
        _logger.d('Successfully fetched verse share content');
        return result.data!;
      } else {
        _logger.e('Failed to fetch verse share content: ${result.error}');
        return null;
      }
    } catch (e) {
      _logger.e('Exception while fetching verse share content: $e');
      return null;
    }
  }

  /// Get definition content from backend API for sharing using new unified API
  Future<String?> getDefinitionShareContent(String defId) async {
    try {
      _logger.i('Fetching definition share content from backend for definition ID: $defId');
      
      final result = await _shareApiRepo.getShareContentForCopy(defId: defId);
      
      if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
        _logger.d('Successfully fetched definition share content');
        return result.data!;
      } else {
        _logger.e('Failed to fetch definition share content: ${result.error}');
        return null;
      }
    } catch (e) {
      _logger.e('Exception while fetching definition share content: $e');
      return null;
    }
  }
}

