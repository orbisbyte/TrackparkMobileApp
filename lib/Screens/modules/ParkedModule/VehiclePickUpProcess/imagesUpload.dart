import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/controller/form_Controller.dart';
import 'package:driver_tracking_airport/utils/confirm_discard_dialog.dart';
import 'package:driver_tracking_airport/widgets/media_capture_view.dart';
import 'package:driver_tracking_airport/widgets/vehicle_video_slots_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Step 2 screen in the valet form (pickup media)
/// Uses the reusable [MediaCaptureView] with pickup-specific configuration.
class ImagesPickerScreen extends StatelessWidget {
  ImagesPickerScreen({super.key});

  final FormController controller = Get.find<FormController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final hasChanges =
            controller.pickupImages.isNotEmpty ||
            controller.pickupVideos.values.any((e) => e != null) ||
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
        backgroundColor: Colors.white,
        body: MediaCaptureView(
          images: controller.pickupImages,
          // Multi-slot video capture (legacy single-video param is unused because
          // we override the section below).
          video: Rxn<XFile>(),
          customVideoSection: VehicleVideoSlotsSection(
            videos: controller.pickupVideos,
            onCapture: controller.captureVideo,
            onRetake: controller.retakeVideo,
            onDelete: controller.clearVideo,
            title: 'Vehicle Video Clips (Pickup)',
          ),
          onCaptureFromGallery: controller.captureImages,
          onCaptureFromCamera: controller.captureImageFromCamera,
          onCaptureVideo: () {},
          onRetakeVideo: () {},
          onClearAll: controller.clearAll,
          onRemoveImage: controller.removeImage,
          onDeleteVideo: () {},
          headerTitle: 'Vehicle Documentation',
          headerSubtitle:
              'Capture clear photos and video of the vehicle condition',
          photosTitle: 'Vehicle Photos',
          videoTitle: '360° Video Walkaround',
          isDamaged: controller.isDamaged,
          isScratched: controller.isScratched,
          isDirty: controller.isDirty,
          conditionNotesController: controller.conditionNotesController,
        ),
      ),
    );
  }
}
