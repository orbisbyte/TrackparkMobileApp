import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/license_plate_camera_screen.dart';
import 'package:driver_tracking_airport/data/services/firebase/job_firebase_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:video_player/video_player.dart';

import '../../../../../COntrollers/location_controller.dart';
import '../../../../../data/remote/repositories/updateJobParameters_repo.dart';
import '../../../../../data/services/media_upload_isolate_service.dart';
import '../../../../../models/vehicle_video_slot.dart';
import '../../TrackJob/trackJobScreen.dart';

class FormController extends GetxController {
  static const Duration _durationTolerance = Duration(seconds: 2);
  final UpdateJobParametersRepository _updateJobParametersRepo =
      UpdateJobParametersRepository();
  final PageController pageController = PageController();
  final JobFirebaseService _firebaseService = JobFirebaseService();
  final LoginController _loginController = Get.find<LoginController>();

  var currentStep = 0.obs;
  var isSubmitting = false.obs;

  // Store the job if started from incoming jobs
  JobModel? currentJob;

  // Timestamps are stored locally and updated to Firebase only once on final submission
  DateTime? vehicleInfoStartTime;
  DateTime? vehicleInfoEndTime;
  DateTime? imagesInfoStartTime;
  DateTime? imagesInfoEndTime;
  DateTime? consentStartTime;
  DateTime? consentEndTime;
  //stepp 1
  final plateController = TextEditingController();
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final colorController = TextEditingController();

  // Text Recognition
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Scans license plate from custom camera screen using ML Kit Text Recognition
  /// Returns true if text was successfully extracted, false otherwise
  Future<bool> scanLicensePlate(BuildContext context) async {
    try {
      // Navigate to custom camera screen
      final String? imagePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const LicensePlateCameraScreen(),
        ),
      );

      if (imagePath == null || imagePath.isEmpty) {
        // User cancelled
        return false;
      }

      // Crop image to focus on license plate area (center crop based on frame)
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,

        aspectRatio: const CropAspectRatio(
          ratioX: 3.0,
          ratioY: 1.0,
        ), // License plate aspect ratio (wider)
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop License Plate',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop License Plate',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) {
        // User cancelled cropping
        return false;
      }

      // Process cropped image with ML Kit
      try {
        final inputImage = InputImage.fromFilePath(croppedFile.path);
        final RecognizedText recognizedText = await _textRecognizer
            .processImage(inputImage);

        // Extract text
        String extractedText = recognizedText.text.trim();

        if (extractedText.isEmpty) {
          _showErrorSnackbar(
            'No Text Found',
            'Could not detect any text in the image. Please try again.',
          );
          return false;
        }

        // Clean and format license plate text
        extractedText = _cleanLicensePlateText(extractedText);

        // Update controller
        plateController.text = extractedText;

        // Show success message
        _showSuccessSnackbar('License plate scanned: $extractedText');

        return true;
      } catch (e) {
        _showErrorSnackbar('Error', 'Failed to process image: ${e.toString()}');
        return false;
      }
    } catch (e) {
      _showErrorSnackbar(
        'Error',
        'Failed to scan license plate: ${e.toString()}',
      );
      return false;
    }
  }

  /// Cleans and formats license plate text
  /// Removes extra spaces, newlines, and formats it properly
  String _cleanLicensePlateText(String text) {
    // Remove newlines and extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove special characters that might interfere (keep alphanumeric and spaces)
    text = text.replaceAll(RegExp(r'[^\w\s]'), '');

    // Convert to uppercase for consistency
    text = text.toUpperCase();

    return text;
  }

  /// Shows error snackbar
  void _showErrorSnackbar(String title, String message) {
    // Use Future.microtask to ensure overlay is available
    MessageHelper.showError(message, title: title);
  }

  /// Shows success snackbar
  void _showSuccessSnackbar(String message) {
    // Use Future.microtask to ensure overlay is available
    MessageHelper.showSuccess(message);
  }

  //step 2 - pickup media (before car is parked)
  RxList<XFile> pickupImages = <XFile>[].obs;
  final RxMap<VehicleVideoSlot, XFile?> pickupVideos =
      <VehicleVideoSlot, XFile?>{}.obs;
  final ImagePicker picker = ImagePicker();

  // Vehicle condition flags for pickup media
  final RxBool isDamaged = false.obs;
  final RxBool isScratched = false.obs;
  final RxBool isDirty = false.obs;
  final TextEditingController conditionNotesController =
      TextEditingController();

  //step 33
  final valuablesController = TextEditingController();
  final signatureController = TextEditingController();
  final signaturePadController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue.shade800,
  );
  // Save signature as image file if signature pad has content
  String? signatureImagePath;

  var hasSignature = false.obs;

  @override
  void onInit() {
    super.onInit();
    for (final slot in VehicleVideoSlot.values) {
      pickupVideos[slot] = null;
    }
  }

  List<VehicleVideoSlot> missingRequiredPickupSlots() {
    return VehicleVideoSlot.values
        .where((s) => s.isRequired && pickupVideos[s] == null)
        .toList(growable: false);
  }

  List<String> pickupVideoPathsInOrder() {
    return VehicleVideoSlot.values
        .map((s) => pickupVideos[s]?.path)
        .whereType<String>()
        .toList(growable: false);
  }

  String? primaryPickupVideoPath() {
    final paths = pickupVideoPathsInOrder();
    return paths.isEmpty ? null : paths.first;
  }

  Future<void> startJob() async {
    try {
      isSubmitting.value = true;
      consentEndTime ??= DateTime.now();

      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';

      if (driverId.isEmpty) {
        MessageHelper.showError('Driver ID not found. Please login again.');
        return;
      }

      // If job was started from incoming jobs, update existing job
      if (currentJob != null) {
        // Ensure consentEndTime is set
        consentEndTime ??= DateTime.now();

        if (signaturePadController.isNotEmpty) {
          signatureImagePath = await saveSignatureAsImage();
        }
        var locationController = Get.find<LocationController>();
        var startLat = locationController.currentLocation.value?.latitude;
        var startLng = locationController.currentLocation.value?.longitude;

        // Update existing job with all form data (including all timestamps)
        final updatedJob = currentJob!.copyWith(
          pickupImages: pickupImages.map((e) => e.path).toList(),
          pickupVideo: primaryPickupVideoPath(),
          valuables: valuablesController.text,
          signature: signatureController.text,
          vehicleInfoStartTime: vehicleInfoStartTime,
          vehicleInfoEndTime: vehicleInfoEndTime,
          imagesInfoStartTime: imagesInfoStartTime,
          imagesInfoEndTime: imagesInfoEndTime,
          consentStartTime: consentStartTime,
          consentEndTime: consentEndTime,
          vehicle: VehicleInfo(
            regNo: plateController.text,
            make: makeController.text,
            colour: colorController.text,
            model: modelController.text,
          ),
          jobStatus: 'started', // Change status to started
          jobStartedTime: DateTime.now(),
          startLat: startLat,
          startLng: startLng,
        );

        //uploading media in background isolate
        try {
          MediaUploadIsolateService().uploadMediaInBackground(
            driverId: driverId,
            jobId: currentJob!.jobId,
            eventType: 'start',
            imagePaths: pickupImages.map((e) => e.path).toList(),
            videoPath: primaryPickupVideoPath() ?? '',
            videoPaths: pickupVideoPathsInOrder(),
            signatureImage: signatureImagePath,
          );
        } catch (e) {
          log("failed to upload media $e");
        }

        // Update Firebase with all fields including all timestamps (single update)
        await _firebaseService.updateJob(
          currentJob!.jobId,
          fullJob: updatedJob,
        );

        //update job parameters to api
        try {
          JobModel updatedJobModel = JobModel(
            jobId: updatedJob.jobId,
            driverId: driverId,
            jobStartedTime: DateTime.now(),
            jobStatus: 'started',
            vehicleInfoStartTime: vehicleInfoStartTime,
            vehicleInfoEndTime: vehicleInfoEndTime,
            imagesInfoStartTime: imagesInfoStartTime,
            imagesInfoEndTime: imagesInfoEndTime,
            consentStartTime: consentStartTime,
            consentEndTime: consentEndTime,
            vehicle: VehicleInfo(
              regNo: plateController.text,
              make: makeController.text,
              colour: colorController.text,
              model: modelController.text,
            ),
            valuables: valuablesController.text,
            startLat: startLat,
            startLng: startLng,
          );
          await _updateJobParametersRepo.updateJobParameters(
            job: updatedJobModel,
            isDamaged: isDamaged.value,
            isScratched: isScratched.value,
            isDirty: isDirty.value,
            vConditionFlag: 'start', // Pickup media = "start"
            vConditionNotes: conditionNotesController.text.trim().isEmpty
                ? null
                : conditionNotesController.text.trim(),
          );
        } catch (e) {
          log("failed to update job parameters to api $e");
        }

        // Update dashboard controller locally (no Firebase call)
        final dashboardController = Get.find<DashBoardController>();
        dashboardController.updateOngoingJobLocally(updatedJob);

        MessageHelper.showSuccess('Job started successfully!');

        // Navigate to track screen with updated job (no Firebase call)
        Get.off(() => JobTrackScreen(initialJob: updatedJob));
      } else {
        // New job creation (manual)
        // final job = buildJobModel();
        // await JobDatabase.instance.insertJob(job);
        // MessageHelper.showSuccess('Job created successfully!');
      }
    } catch (e) {
      MessageHelper.showError(
        'Failed to submit job: ${e.toString().replaceAll('Exception: ', '')}',
        title: 'Error',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearSignature() {
    signaturePadController.clear();
    hasSignature.value = false;
  }

  Future<void> saveSignature(BuildContext context) async {
    if (signaturePadController.isNotEmpty) {
      signatureController.text = 'Digitally Signed';
      hasSignature.value = true;
      Navigator.pop(context);
    } else {
      MessageHelper.showError('Please provide a signature first');
    }
  }

  /// Converts signature pad to PNG image file and saves it
  /// Returns the file path if successful, null otherwise
  Future<String?> saveSignatureAsImage() async {
    try {
      if (signaturePadController.isEmpty) {
        return null;
      }

      // Convert signature to PNG bytes
      final Uint8List? signatureBytes = await signaturePadController
          .toPngBytes();
      if (signatureBytes == null) {
        log('Failed to convert signature to PNG bytes');
        return null;
      }

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/signature_$timestamp.png';

      // Write bytes to file
      final File signatureFile = File(filePath);
      await signatureFile.writeAsBytes(signatureBytes);

      log('Signature saved to: $filePath');
      return filePath;
    } catch (e) {
      log('Error saving signature as image: $e');
      return null;
    }
  }

  Future<void> captureImages() async {
    final List<XFile> capturedImages = await picker.pickMultiImage(
      maxWidth: 1080,
      imageQuality: 90,
    );
    if (capturedImages.isNotEmpty) {
      pickupImages.addAll(capturedImages);
    }
  }

  Future<void> captureImageFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      imageQuality: 90,
    );
    if (image != null) {
      pickupImages.add(image);
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

    pickupVideos[slot] = capturedVideo;
  }

  void removeImage(int index) {
    pickupImages.removeAt(index);
  }

  Future<void> retakeVideo(VehicleVideoSlot slot) async {
    pickupVideos[slot] = null;
    await captureVideo(slot);
  }

  void clearVideo(VehicleVideoSlot slot) {
    pickupVideos[slot] = null;
  }

  void clearAll() {
    pickupImages.clear();
    for (final slot in VehicleVideoSlot.values) {
      pickupVideos[slot] = null;
    }
  }

  Future<Duration> _getVideoDuration(String videoPath) async {
    final player = VideoPlayerController.file(File(videoPath));
    await player.initialize();
    final duration = player.value.duration;
    await player.dispose();
    return duration;
  }

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  void onClose() {
    // Dispose text recognizer
    _textRecognizer.close();

    // Dispose controllers
    plateController.dispose();
    makeController.dispose();
    modelController.dispose();
    colorController.dispose();
    valuablesController.dispose();
    signatureController.dispose();
    signaturePadController.dispose();
    conditionNotesController.dispose();
    super.onClose();
  }
}
