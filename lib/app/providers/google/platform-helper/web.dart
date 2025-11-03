import 'dart:developer';

import 'package:google_sign_in_web/google_sign_in_web.dart';

import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class GoogleSignInPlatformHelper {

  
  GoogleSignInPlugin? _googleSignInPlugin;

  
  void listenPlatformEvent(Function(bool isLoggedIn)? onLoggedIn) {
    _googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;
    // _googleSignInPlugin?.initWithParams(SignInInitParameters());

    _googleSignInPlugin?.userDataEvents?.listen((event) {
      if (event != null) {
        // event.idToken

        inspect(event);
        print("_googleSignInPlugin: $event");

        if (event != null && event.idToken != null) {
          onLoggedIn?.call(true);
        }

        // onPress(event.idToken!);
      }
    });
  }
}
