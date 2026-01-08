import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageHelper {
  /// Show success message
  static void showSuccess(String message, {String? title}) {
    _showMessage(
      title ?? 'Success',
      message,
      Colors.green.shade100,
      Colors.green.shade900,
    );
  }

  /// Show error message
  static void showError(String message, {String? title}) {
    _showMessage(
      title ?? 'Error',
      message,
      Colors.red.shade100,
      Colors.red.shade900,
    );
  }

  /// Show warning message
  static void showWarning(String message, {String? title}) {
    _showMessage(
      title ?? 'Warning',
      message,
      Colors.orange.shade100,
      Colors.orange.shade900,
    );
  }

  /// Show info message
  static void showInfo(String message, {String? title}) {
    _showMessage(
      title ?? 'Info',
      message,
      Colors.blue.shade100,
      Colors.blue.shade900,
    );
  }

  /// Internal method to show message
  static void _showMessage(
    String title,
    String message,
    Color backgroundColor,
    Color textColor,
  ) {
    // Try to get context from navigator
    final context = Get.context;

    if (context != null && context.mounted) {
      // Use ScaffoldMessenger if context is available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(message, style: TextStyle(color: textColor)),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Fallback to GetX snackbar if context is not available
      // Use Future.microtask to ensure overlay is ready
      Future.microtask(() {
        if (Get.isSnackbarOpen == false) {
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: backgroundColor,
            colorText: textColor,
            duration: const Duration(seconds: 3),
          );
        }
      });
    }
  }
}
