import 'package:flutter/material.dart';

class ConfirmDiscardDialog {
  /// Returns true if user chooses "Leave", false if user cancels.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'If you go back now, you will lose the captured media and notes on this screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
