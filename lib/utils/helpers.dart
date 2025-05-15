import 'package:flutter/material.dart';

// LEARN: This file can contain utility functions that are used across the app,
// such as showing snackbars or dialogs.

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any existing snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Theme.of(context).snackBarTheme.backgroundColor,
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<bool?> showConfirmationDialog(
  BuildContext context,
  String title,
  String content, {
  String confirmText = "Confirm",
  String cancelText = "Cancel",
}) async {
  // LEARN: showDialog is a Flutter function to display a modal dialog.
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext dialogContext) {
      // LEARN: AlertDialog is a standard Material Design dialog.
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText),
            onPressed: () {
              Navigator.of(dialogContext).pop(false); // Returns false
            },
          ),
          TextButton(
            child: Text(confirmText),
            onPressed: () {
              Navigator.of(dialogContext).pop(true); // Returns true
            },
          ),
        ],
      );
    },
  );
}