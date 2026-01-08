import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomSnackBar({
  required String title,
  required String message,
  bool isError = false,
}) {
  Get.showSnackbar(
    GetSnackBar(
      title: title,
      message: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      borderRadius: 8,
      margin: const EdgeInsets.all(12),
      isDismissible: true,
      icon: Icon(
        isError ? Icons.error : Icons.check_circle,
        color: Colors.white,
      ),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
    ),
  );
}
