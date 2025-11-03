import 'package:flutter/widgets.dart';

typedef HandleSignInFn = void Function();

/// Renders a SIGN IN button that calls `handleSignIn` onclick.
Widget googleSignInButton({
  required HandleSignInFn? onPressed,
  bool isDense = false,
}) {
  return const Placeholder(
    fallbackHeight: 50,
    fallbackWidth: 200,
    child: Text('Google Sign-In not supported on this platform'),
  );
}