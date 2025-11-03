
import 'package:dharak_flutter/app/ui/shared/common/error/error404_modal.dart';
import 'package:flutter/material.dart';

class ErrorDialog {
  BuildContext? mDialogContext;

  // late BuildContext context;

  ErrorDialog();

  // this is where you would do your fullscreen loading
  Future<void> start(
    BuildContext pContext, [
    String? message,
    Function()? onRetry,
  ]) async {
    if (mDialogContext != null) return;
    return await showDialog<void>(
      context: pContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        mDialogContext = context;
        return Error404Modal(
          onRetry: () {
            stop(context);
            onRetry?.call();
          },
        );
      },
    );
  }

  Future<void> stop(BuildContext context) async {
    if (mDialogContext != null) {
      Navigator.of(mDialogContext!).pop();
      mDialogContext = null;
    }
  }

  // Future<void> showError(BuildContext context, Object? error) async {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       action: SnackBarAction(
  //         label: 'Dismiss',
  //         onPressed: () {
  //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //         },
  //       ),
  //       backgroundColor: Colors.red,
  //       content: Text("error"),// Text(handleError(error))
  //     ),
  //   );
  // }
}
