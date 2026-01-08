import 'package:flutter/material.dart';

import '../../../../main.dart';

/// Displays a toast message using ScaffoldMessenger.
void showToastMessage(String message) {
  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 2000),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
