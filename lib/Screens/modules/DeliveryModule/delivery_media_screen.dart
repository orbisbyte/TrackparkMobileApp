import 'dart:io';

import 'package:driver_tracking_airport/models/vehicle_video_slot.dart';
import 'package:driver_tracking_airport/utils/confirm_discard_dialog.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:driver_tracking_airport/widgets/media_capture_view.dart';
import 'package:driver_tracking_airport/widgets/vehicle_video_slots_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Result returned from the delivery media screen.
class DeliveryMediaResult {
  final List<String> imagePaths;
  final Map<VehicleVideoSlot, String?> videoPaths;
  final bool isDamaged;
  final bool isScratched;
  final bool isDirty;
  final String? conditionNotes;

  DeliveryMediaResult({
    required this.imagePaths,
    required this.videoPaths,
    required this.isDamaged,
    required this.isScratched,
    required this.isDirty,
    this.conditionNotes,
  });

  List<String> get videoPathList => VehicleVideoSlot.values
      .map((s) => videoPaths[s])
      .whereType<String>()
      .toList(growable: false);
}

/// Controller for capturing delivery media (photos + video).
class DeliveryMediaController extends GetxController {
  static const Duration _durationTolerance = Duration(seconds: 2);

  final RxList<XFile> images = <XFile>[].obs;
  final RxMap<VehicleVideoSlot, XFile?> videos =
      <VehicleVideoSlot, XFile?>{}.obs;
  final ImagePicker picker = ImagePicker();

  // Vehicle condition flags for delivery media
  final RxBool isDamaged = false.obs;
  final RxBool isScratched = false.obs;
  final RxBool isDirty = false.obs;
  final TextEditingController conditionNotesController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    for (final slot in VehicleVideoSlot.values) {
      videos[slot] = null;
    }
  }

  Future<void> captureImageFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      imageQuality: 90,
    );
    if (image != null) {
      images.add(image);
    }
  }

  Future<void> captureVideo(VehicleVideoSlot slot) async {
    final XFile? capturedVideo = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: slot.maxDuration,
    );
    if (capturedVideo == null) return;

    final max = slot.maxDuration;
    if (max != null) {
      final duration = await _getVideoDuration(capturedVideo.path);
      // Allow a small tolerance because many devices report a 1:00 recording
      // as slightly above 60s due to encoding/container metadata.
      if (duration > max + _durationTolerance) {
        MessageHelper.showError(
          '${slot.title} must be ${slot.limitLabel}. Please record again.',
        );
        return;
      }
    }

    videos[slot] = capturedVideo;
  }

  Future<void> retakeVideo(VehicleVideoSlot slot) async {
    videos[slot] = null;
    await captureVideo(slot);
  }

  void clearVideo(VehicleVideoSlot slot) {
    videos[slot] = null;
  }

  List<VehicleVideoSlot> missingRequiredSlots() {
    return VehicleVideoSlot.values
        .where((s) => s.isRequired && videos[s] == null)
        .toList(growable: false);
  }

  void removeImage(int index) {
    images.removeAt(index);
  }

  void clearAll() {
    images.clear();
    for (final slot in VehicleVideoSlot.values) {
      videos[slot] = null;
    }
  }

  Future<Duration> _getVideoDuration(String videoPath) async {
    final player = VideoPlayerController.file(File(videoPath));
    await player.initialize();
    final duration = player.value.duration;
    await player.dispose();
    return duration;
  }
}

/// Screen shown for capturing delivery media (pickup or completion).
class DeliveryMediaScreen extends StatelessWidget {
  final String headerTitle;
  final String headerSubtitle;
  final String photosTitle;
  final String videoTitle;
  final String buttonText;

  const DeliveryMediaScreen({
    super.key,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.photosTitle,
    required this.videoTitle,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final DeliveryMediaController controller = Get.put(
      DeliveryMediaController(),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final hasChanges =
            controller.images.isNotEmpty ||
            controller.videos.values.any((e) => e != null) ||
            controller.isDamaged.value ||
            controller.isScratched.value ||
            controller.isDirty.value ||
            controller.conditionNotesController.text.trim().isNotEmpty;

        if (!hasChanges) {
          Get.back();
          return;
        }

        final leave = await ConfirmDiscardDialog.show(context);
        if (leave) Get.back();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(headerTitle)),
        backgroundColor: Colors.white,
        body: MediaCaptureView(
          images: controller.images,
          // Multi-slot videos; legacy single-video field unused because we override
          // the section below.
          video: Rxn<XFile>(),
          customVideoSection: VehicleVideoSlotsSection(
            videos: controller.videos,
            onCapture: controller.captureVideo,
            onRetake: controller.retakeVideo,
            onDelete: controller.clearVideo,
            title: videoTitle,
          ),
          parkingNotesController: null, // No notes for delivery
          // Delivery capture must be from camera only
          onCaptureFromGallery: null,
          onCaptureFromCamera: controller.captureImageFromCamera,
          onCaptureVideo: () {},
          onRetakeVideo: () {},
          onClearAll: controller.clearAll,
          onRemoveImage: controller.removeImage,
          onDeleteVideo: () {},
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle,
          photosTitle: photosTitle,
          videoTitle: videoTitle,
          isDamaged: controller.isDamaged,
          isScratched: controller.isScratched,
          isDirty: controller.isDirty,
          conditionNotesController: controller.conditionNotesController,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final missing = controller.missingRequiredSlots();
                  if (controller.images.isEmpty || missing.isNotEmpty) {
                    final missingText = missing.isEmpty
                        ? ''
                        : ' Missing videos: ${missing.map((e) => e.title).join(', ')}';
                    MessageHelper.showError(
                      'Please capture photos and required videos before continuing.$missingText',
                    );
                    return;
                  }

                  final result = DeliveryMediaResult(
                    imagePaths: controller.images.map((e) => e.path).toList(),
                    videoPaths: {
                      for (final slot in VehicleVideoSlot.values)
                        slot: controller.videos[slot]?.path,
                    },
                    isDamaged: controller.isDamaged.value,
                    isScratched: controller.isScratched.value,
                    isDirty: controller.isDirty.value,
                    conditionNotes:
                        controller.conditionNotesController.text.trim().isEmpty
                        ? null
                        : controller.conditionNotesController.text.trim(),
                  );

                  Get.back(result: result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
