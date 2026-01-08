import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utility class for job countdown timer
class CountdownTimerUtil {
  /// Calculate time remaining from target DateTime to now
  /// Returns a map with formatted string and color
  static Map<String, dynamic> getCountdownInfo(DateTime? targetDateTime) {
    if (targetDateTime == null) {
      return {'formatted': 'N/A', 'color': Colors.grey, 'isExpired': false};
    }

    final now = DateTime.now();
    final difference = targetDateTime.difference(now);

    // Check if expired
    if (difference.isNegative) {
      return {
        'formatted': 'TIME UP!',
        'color': Colors.red.shade700,
        'isExpired': true,
      };
    }

    // Calculate time components
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    // Format the countdown string
    String formatted = '';
    if (days > 0) {
      formatted += '${days}d ';
    }
    if (hours > 0 || days > 0) {
      formatted += '${hours}h ';
    }
    if (minutes > 0 || hours > 0 || days > 0) {
      formatted += '${minutes}m ';
    }
    formatted += '${seconds}s';
    formatted += ' left';

    // Determine color based on time remaining
    Color countdownColor;
    if (days >= 1) {
      // More than 1 day: Green
      countdownColor = Colors.green.shade600;
    } else if (difference.inHours >= 1) {
      // Less than 1 day but more than 1 hour: Orange
      countdownColor = Colors.orange.shade600;
    } else {
      // Less than 1 hour: Red
      countdownColor = Colors.red.shade600;
    }

    return {
      'formatted': formatted.trim(),
      'color': countdownColor,
      'isExpired': false,
    };
  }

  /// Get formatted countdown string only
  static String getCountdownString(DateTime? targetDateTime) {
    final info = getCountdownInfo(targetDateTime);
    return info['formatted'] as String;
  }

  /// Get countdown color only
  static Color getCountdownColor(DateTime? targetDateTime) {
    final info = getCountdownInfo(targetDateTime);
    return info['color'] as Color;
  }
}

/// GetX Controller for Countdown Timer
class CountdownTimerController extends GetxController {
  final DateTime? targetDateTime;
  final Duration updateInterval;
  final String tag;

  Timer? _timer;
  final currentTime = DateTime.now().obs;
  final isExpired = false.obs;

  CountdownTimerController({
    required this.targetDateTime,
    required this.tag,
    this.updateInterval = const Duration(seconds: 1),
  });

  @override
  void onInit() {
    super.onInit();
    // Check if already expired before starting timer
    if (targetDateTime != null) {
      final difference = targetDateTime!.difference(DateTime.now());
      if (difference.isNegative || difference.inSeconds <= 0) {
        isExpired.value = true;
        log('Already expired');
        return; // Don't start timer if already expired
      }
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(updateInterval, (_) {
      if (_timer == null || !_timer!.isActive) {
        return; // Timer was stopped
      }

      final now = DateTime.now();
      // Update currentTime to trigger reactive rebuilds
      currentTime.value = now;

      // Check if expired and stop timer if so
      if (targetDateTime != null) {
        final difference = targetDateTime!.difference(now);
        if (difference.isNegative || difference.inSeconds <= 0) {
          isExpired.value = true;
          _stopTimer();
          // Don't auto-dispose, let the widget handle it
          // This ensures the UI can still show "TIME UP!"
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Map<String, dynamic> get countdownInfo {
    return CountdownTimerUtil.getCountdownInfo(targetDateTime);
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}

/// Widget that displays a countdown timer using GetX
class CountdownTimerWidget extends StatefulWidget {
  final DateTime? targetDateTime;
  final String? uniqueId; // Unique identifier for each timer (e.g., jobId)
  final TextStyle? textStyle;
  final Duration updateInterval;

  const CountdownTimerWidget({
    super.key,
    required this.targetDateTime,
    this.uniqueId,
    this.textStyle,
    this.updateInterval = const Duration(seconds: 1),
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late String _tag;
  CountdownTimerController? _controller;

  @override
  void initState() {
    super.initState();
    // Create a unique tag using uniqueId or fallback to timestamp
    _tag =
        widget.uniqueId ??
        widget.targetDateTime?.millisecondsSinceEpoch.toString() ??
        'timer_${DateTime.now().millisecondsSinceEpoch}';

    // Check if expired before creating controller
    if (widget.targetDateTime != null) {
      final difference = widget.targetDateTime!.difference(DateTime.now());
      if (difference.isNegative || difference.inSeconds <= 0) {
        // Already expired, don't create timer
        return;
      }
    }

    // Check if controller already exists, if not create it
    if (!Get.isRegistered<CountdownTimerController>(tag: _tag)) {
      _controller = Get.put(
        CountdownTimerController(
          targetDateTime: widget.targetDateTime,
          tag: _tag,
          updateInterval: widget.updateInterval,
        ),
        tag: _tag,
      );
    } else {
      _controller = Get.find<CountdownTimerController>(tag: _tag);
      // Update targetDateTime if it changed
      if (_controller!.targetDateTime != widget.targetDateTime) {
        // Stop and delete old controller
        _controller!.onClose();
        Get.delete<CountdownTimerController>(tag: _tag);
        // Create new controller with updated targetDateTime
        _controller = Get.put(
          CountdownTimerController(
            targetDateTime: widget.targetDateTime,
            tag: _tag,
            updateInterval: widget.updateInterval,
          ),
          tag: _tag,
        );
      }
    }
  }

  @override
  void dispose() {
    // Always dispose the controller when widget is disposed
    if (_controller != null &&
        Get.isRegistered<CountdownTimerController>(tag: _tag)) {
      // Stop the timer first (onClose will handle it)
      _controller!.onClose();
      // Then delete the controller
      Get.delete<CountdownTimerController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If controller is null (expired or not created), show expired message
    if (_controller == null) {
      return Text(
        'TIME UP!',
        style: (widget.textStyle ?? const TextStyle()).copyWith(
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Check if controller is still registered
    if (!Get.isRegistered<CountdownTimerController>(tag: _tag)) {
      return Text(
        'TIME UP!',
        style: (widget.textStyle ?? const TextStyle()).copyWith(
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Use GetBuilder with init to ensure controller exists
    return GetBuilder<CountdownTimerController>(
      tag: _tag,
      init: _controller,
      builder: (controller) {
        // Use Obx to reactively update when currentTime changes
        return Obx(() {
          // Check if expired
          if (controller.isExpired.value) {
            return Text(
              'TIME UP!',
              style: (widget.textStyle ?? const TextStyle()).copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            );
          }

          // Access currentTime to trigger reactivity - this is the key!
          // The value is accessed to ensure Obx rebuilds when it changes
          final _ = controller.currentTime.value;

          // Calculate countdown info using current time
          final countdownInfo = CountdownTimerUtil.getCountdownInfo(
            controller.targetDateTime,
          );

          // If expired from countdown info, update state
          if (countdownInfo['isExpired'] == true) {
            controller.isExpired.value = true;
            return Text(
              'TIME UP!',
              style: (widget.textStyle ?? const TextStyle()).copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            );
          }

          return Text(
            "${countdownInfo['formatted'] as String} ",
            style: (widget.textStyle ?? const TextStyle()).copyWith(
              color: countdownInfo['color'] as Color,
              fontWeight: FontWeight.bold,
            ),
          );
        });
      },
    );
  }
}
