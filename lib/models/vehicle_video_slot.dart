/// Defines the required vehicle video clips for documentation.
///
/// The first 4 are required and capped at 1 minute.
/// The 5th ("Other") is optional and has no max duration.
enum VehicleVideoSlot { front, left, back, right, other }

extension VehicleVideoSlotX on VehicleVideoSlot {
  String get title {
    switch (this) {
      case VehicleVideoSlot.front:
        return 'Front view';
      case VehicleVideoSlot.left:
        return 'Left view';
      case VehicleVideoSlot.back:
        return 'Back view';
      case VehicleVideoSlot.right:
        return 'Right view';
      case VehicleVideoSlot.other:
        return 'Other';
    }
  }

  String get subtitle {
    switch (this) {
      case VehicleVideoSlot.front:
        return 'Record the front of the vehicle';
      case VehicleVideoSlot.left:
        return 'Record the left side';
      case VehicleVideoSlot.back:
        return 'Record the rear of the vehicle';
      case VehicleVideoSlot.right:
        return 'Record the right side';
      case VehicleVideoSlot.other:
        return 'Any additional clip (optional)';
    }
  }

  bool get isRequired => this != VehicleVideoSlot.other;

  /// Max duration for recording (camera capture). `null` means no limit.
  Duration? get maxDuration =>
      isRequired ? const Duration(minutes: 1) : null;

  /// UI helper (e.g., "Max 1:00" or "No limit").
  String get limitLabel => isRequired ? 'Max 1:00' : 'No limit';

  String get keyName {
    // Useful for sending to backend if you later want typed fields.
    switch (this) {
      case VehicleVideoSlot.front:
        return 'front';
      case VehicleVideoSlot.left:
        return 'left';
      case VehicleVideoSlot.back:
        return 'back';
      case VehicleVideoSlot.right:
        return 'right';
      case VehicleVideoSlot.other:
        return 'other';
    }
  }
}


