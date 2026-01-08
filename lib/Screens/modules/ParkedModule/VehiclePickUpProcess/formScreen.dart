import 'dart:developer';
import 'dart:typed_data';

import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/consentScreen.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/controller/form_Controller.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/imagesUpload.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/vehicleInfo.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:driver_tracking_airport/models/vehicle_video_slot.dart';
import 'package:driver_tracking_airport/utils/colors.dart';
import 'package:driver_tracking_airport/utils/toast_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/message_helper.dart';

class ReceiveJobForm extends StatefulWidget {
  final JobModel? job; // Optional job if starting from incoming jobs

  const ReceiveJobForm({super.key, this.job});

  @override
  State<ReceiveJobForm> createState() => _ReceiveJobFormState();
}

class _ReceiveJobFormState extends State<ReceiveJobForm> {
  // Form data

  final FormController controller = Get.put(FormController());

  @override
  void initState() {
    super.initState();

    // If job is provided (from incoming jobs), initialize form with job data
    if (widget.job != null) {
      _initializeFormWithJob(widget.job!);

      // Only set vehicleInfoStartTime if not already set (resuming job)
      controller.vehicleInfoStartTime ??= DateTime.now();
    } else {
      // New job - set vehicle info start time
      controller.vehicleInfoStartTime = DateTime.now();
    }
  }

  void _initializeFormWithJob(JobModel job) {
    // Store the job in controller
    controller.currentJob = job;

    // Restore timestamps if they exist (resuming job)
    controller.vehicleInfoStartTime = job.vehicleInfoStartTime;
    controller.vehicleInfoEndTime = job.vehicleInfoEndTime;
    controller.imagesInfoStartTime = job.imagesInfoStartTime;
    controller.imagesInfoEndTime = job.imagesInfoEndTime;
    controller.consentStartTime = job.consentStartTime;
    controller.consentEndTime = job.consentEndTime;

    // Pre-fill form with job data if available Step 1
    if (job.vehicle != null) {
      controller.plateController.text = job.vehicle!.regNo ?? '';
      controller.makeController.text = job.vehicle!.make ?? '';
      controller.colorController.text = job.vehicle!.colour ?? '';
      controller.modelController.text = job.vehicle!.model ?? '';
    }

    // Step 3
    if (job.signature != null) {
      controller.signatureController.text = job.signature!;
      controller.hasSignature.value = job.signature!.isNotEmpty;
    }
    //valuables
    if (job.valuables != null) {
      controller.valuablesController.text = job.valuables!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Obx(() => Text('Step ${controller.currentStep.value + 1}/3')),
      ),
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => controller.currentStep.value = index,
        children: [VehicleInfoScreen(), ImagesPickerScreen(), ConsentScreen()],
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomBar()),
    );
  }

  Widget _buildBottomBar() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            // Back Button (only shown when not on first step)
            if (controller.currentStep.value > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.blue.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (controller.currentStep > 0) const SizedBox(width: 12),

            // Continue/Create Button
            Expanded(
              flex: controller.currentStep > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.currentStep.value == 0) {
                    if (controller.plateController.text.isEmpty) {
                      showToastMessage('Please add License Plate No');
                    } else {
                      // Leaving Step 1 → Set end time and Step 2 start time (only if not already set)
                      controller.vehicleInfoEndTime ??= DateTime.now();
                      controller.imagesInfoStartTime ??= DateTime.now();

                      controller.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  } else if (controller.currentStep.value == 1) {
                    final missing = controller.missingRequiredPickupSlots();
                    if (controller.pickupImages.isNotEmpty &&
                        missing.isEmpty) {
                      // Leaving Step 2 → Set end time and Step 3 start time (only if not already set)
                      controller.imagesInfoEndTime ??= DateTime.now();
                      controller.consentStartTime ??= DateTime.now();

                      controller.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      final missingText = missing.isEmpty
                          ? ''
                          : '\nMissing videos: ${missing.map((e) => e.title).join(', ')}';
                      MessageHelper.showError(
                        'Please add images and required videos.$missingText',
                      );
                    }
                  } else {
                    if (controller.signatureController.text.isEmpty &&
                        controller.signaturePadController.isEmpty) {
                      MessageHelper.showError('Please add Signature');
                    } else {
                      Uint8List? sigs;
                      if (controller.signaturePadController.isNotEmpty) {
                        sigs = await controller.signaturePadController
                            .toPngBytes();
                      }
                      log(
                        "${controller.valuablesController.text}++ ${controller.signatureController.text} ++ ${sigs?.length}",
                      );
                      controller.startJob();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: controller.currentStep.value == 2
                      ? Colors.green.shade600
                      : Colors.blue.shade600,
                  elevation: 2,
                  shadowColor: controller.currentStep.value == 2
                      ? Colors.green.shade200
                      : Colors.blue.shade200,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (controller.currentStep.value == 2)
                      const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: white,
                      ),
                    if (controller.currentStep < 2)
                      const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.black,
                      ),
                    const SizedBox(width: 8),
                    Obx(
                      () => Text(
                        controller.currentStep < 2
                            ? 'Continue'
                            : controller.isSubmitting.value
                            ? 'Submitting...'
                            : 'Start Job',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
