// ENTIRE DEEP LINK SERVICE COMMENTED OUT FOR THIS RELEASE
// 
// import 'dart:async';
// import 'package:app_links/app_links.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_modular/flutter_modular.dart';
// 
// class DeepLinkService {
//   static final DeepLinkService _instance = DeepLinkService._internal();
//   factory DeepLinkService() => _instance;
//   DeepLinkService._internal();
// 
//   late AppLinks _appLinks;
//   StreamSubscription<Uri>? _linkSubscription;
// 
//   /// Initialize deep link listening
//   Future<void> init() async {
//     _appLinks = AppLinks();
//     
//     // Handle app in foreground (when app is already running)
//     _linkSubscription = _appLinks.uriLinkStream.listen(
//       (uri) {
//         print('Deep link received: $uri');
//         _handleDeepLink(uri);
//       },
//       onError: (err) {
//         print('Deep link error: $err');
//       },
//     );
// 
//     // Handle app launch from deep link (when app is closed)
//     try {
//       final initialUri = await _appLinks.getInitialLink();
//       if (initialUri != null) {
//         print('Initial deep link: $initialUri');
//         _handleDeepLink(initialUri);
//       }
//     } catch (err) {
//       print('Failed to get initial link: $err');
//     }
//   }
// 
//   /// Handle incoming deep links
//   void _handleDeepLink(Uri uri) {
//     print('Processing deep link: ${uri.toString()}');
//     
//     // Parse the deep link and navigate accordingly
//     if (uri.host == 'bheri.in') {
//       _handleBheriLink(uri);
//     } else if (uri.scheme == 'dhara') {
//       _handleCustomSchemeLink(uri);
//     }
//   }
// 
//   /// Handle bheri.in universal links
//   void _handleBheriLink(Uri uri) {
//     final path = uri.path;
//     
//     if (path.startsWith('/s/')) {
//       final contentId = path.substring(3); // Remove '/s/'
//       
//       if (contentId.startsWith('v')) {
//         // Verse link: /s/v123456
//         final verseId = contentId.substring(1); // Remove 'v'
//         _navigateToVerse(verseId);
//       } else if (contentId.startsWith('d')) {
//         // Definition link: /s/d123456  
//         final definitionId = contentId.substring(1); // Remove 'd'
//         _navigateToDefinition(definitionId);
//       }
//     }
//   }
// 
//   /// Handle custom dhara:// scheme links
//   void _handleCustomSchemeLink(Uri uri) {
//     final segments = uri.pathSegments;
//     
//     if (segments.isNotEmpty) {
//       final type = segments[0];
//       
//       if (type == 'verse' && segments.length > 1) {
//         final verseId = segments[1];
//         _navigateToVerse(verseId);
//       } else if (type == 'definition' && segments.length > 1) {
//         final definitionId = segments[1];
//         _navigateToDefinition(definitionId);
//       }
//     }
//   }
// 
//   /// Navigate to specific verse
//   void _navigateToVerse(String verseId) {
//     print('Navigating to verse: $verseId');
//     
//     // Import the args class for proper navigation
//     // Navigate to verse page with specific verse ID
//     Modular.to.pushNamed('/dhara/verses', arguments: {
//       'default1': 'deeplink',
//       'scrollToVerse': verseId,
//       'fromDeepLink': true,
//     });
//   }
// 
//   /// Navigate to specific definition
//   void _navigateToDefinition(String definitionId) {
//     print('Navigating to definition: $definitionId');
//     
//     // Navigate to word define page with specific definition
//     Modular.to.pushNamed('/dhara/word-define', arguments: {
//       'scrollToDefinition': definitionId,
//       'fromDeepLink': true,
//     });
//   }
// 
//   /// Generate share link for verse
//   static String generateVerseLink(String verseId) {
//     return 'https://bheri.in/s/v$verseId';
//   }
// 
//   /// Generate share link for definition
//   static String generateDefinitionLink(String definitionId) {
//     return 'https://bheri.in/s/d$definitionId';
//   }
// 
//   /// Generate custom scheme link for verse (fallback)
//   static String generateVerseSchemeLink(String verseId) {
//     return 'dhara://verse/$verseId';
//   }
// 
//   /// Generate custom scheme link for definition (fallback)
//   static String generateDefinitionSchemeLink(String definitionId) {
//     return 'dhara://definition/$definitionId';
//   }
// 
//   /// Clean up resources
//   void dispose() {
//     _linkSubscription?.cancel();
//   }
// }