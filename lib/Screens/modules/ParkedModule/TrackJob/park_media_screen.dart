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

/// Result returned from the parking media screen.
class ParkingMediaResult {
  final List<String> imagePaths;
  final Map<VehicleVideoSlot, String?> videoPaths;
  final String? parkingNotes;
  final bool isDamaged;
  final bool isScratched;
  final bool isDirty;
  final String? conditionNotes;

  ParkingMediaResult({
    required this.imagePaths,
    required this.videoPaths,
    required this.parkingNotes,
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

/// Controller for capturing parking-time media (photos + video).
class ParkMediaController extends GetxController {
  static const Duration _durationTolerance = Duration(seconds: 2);

  final RxList<XFile> parkImages = <XFile>[].obs;
  final RxMap<VehicleVideoSlot, XFile?> parkVideos =
      <VehicleVideoSlot, XFile?>{}.obs;
  final ImagePicker picker = ImagePicker();
  final TextEditingController parkingNotesController = TextEditingController();

  // Vehicle condition flags for parking media
  final RxBool isDamaged = false.obs;
  final RxBool isScratched = false.obs;
  final RxBool isDirty = false.obs;
  final TextEditingController conditionNotesController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Ensure all slots exist in the map (keeps UI stable / deterministic).
    for (final slot in VehicleVideoSlot.values) {
      parkVideos[slot] = null;
    }
  }

  Future<void> captureImageFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      imageQuality: 90,
    );
    if (image != null) {
      parkImages.add(image);
    }
  }

  Future<void> captureVideo(VehicleVideoSlot slot) async {
    final XFile? capturedVideo = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: slot.maxDuration,
    );
    if (capturedVideo == null) return;

    // Defensive duration validation (some devices ignore maxDuration).
    final max = slot.maxDuration;
    if (max != null) {
      final duration = await _getVideoDuration(capturedVideo.path);
      if (duration > max + _durationTolerance) {
        MessageHelper.showError(
          '${slot.title} must be ${slot.limitLabel}. Please record again.',
        );
        return;
      }
    }

    parkVideos[slot] = capturedVideo;
  }

  Future<void> retakeVideo(VehicleVideoSlot slot) async {
    parkVideos[slot] = null;
    await captureVideo(slot);
  }

  void clearVideo(VehicleVideoSlot slot) {
    parkVideos[slot] = null;
  }

  List<VehicleVideoSlot> missingRequiredSlots() {
    return VehicleVideoSlot.values
        .where((s) => s.isRequired && parkVideos[s] == null)
        .toList(growable: false);
  }

  void removeImage(int index) {
    parkImages.removeAt(index);
  }

  void clearAll() {
    parkImages.clear();
    for (final slot in VehicleVideoSlot.values) {
      parkVideos[slot] = null;
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

/// Screen shown before completing a job to capture parking-time media.
class ParkMediaScreen extends StatelessWidget {
  ParkMediaScreen({super.key});

  final ParkMediaController controller = Get.put(ParkMediaController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final hasChanges =
            controller.parkImages.isNotEmpty ||
            controller.parkVideos.values.any((e) => e != null) ||
            controller.parkingNotesController.text.trim().isNotEmpty ||
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
        appBar: AppBar(title: const Text('Parking Media')),
        backgroundColor: Colors.white,
        body: MediaCaptureView(
          images: controller.parkImages,
          // The Parked module now uses multi-slot video capture; the legacy single
          // video param is unused because we override the section below.
          video: Rxn<XFile>(),
          customVideoSection: VehicleVideoSlotsSection(
            videos: controller.parkVideos,
            onCapture: controller.captureVideo,
            onRetake: controller.retakeVideo,
            onDelete: controller.clearVideo,
            title: 'Vehicle Video Clips (Parking)',
          ),
          parkingNotesController: controller.parkingNotesController,
          // Parking capture must be from camera only
          onCaptureFromGallery: null,
          onCaptureFromCamera: controller.captureImageFromCamera,
          onCaptureVideo: () {},
          onRetakeVideo: () {},
          onClearAll: controller.clearAll,
          onRemoveImage: controller.removeImage,
          onDeleteVideo: () {},
          headerTitle: 'Parking Documentation',
          headerSubtitle:
              'Capture photos and video of the vehicle at the time of parking.',
          photosTitle: 'Parking Photos',
          videoTitle: 'Parking Video Walkaround',
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
                  if (controller.parkImages.isEmpty || missing.isNotEmpty) {
                    final missingText = missing.isEmpty
                        ? ''
                        : ' Missing videos: ${missing.map((e) => e.title).join(', ')}';
                    MessageHelper.showError(
                      'Please capture photos and required videos before completing the job.$missingText',
                    );
                    return;
                  }

                  final result = ParkingMediaResult(
                    imagePaths: controller.parkImages
                        .map((e) => e.path)
                        .toList(),
                    videoPaths: {
                      for (final slot in VehicleVideoSlot.values)
                        slot: controller.parkVideos[slot]?.path,
                    },
                    parkingNotes: controller.parkingNotesController.text,
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
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Attach & Continue',
                  style: TextStyle(
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
