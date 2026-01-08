import 'dart:developer';

import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/license_plate_camera_screen.dart';
import 'package:driver_tracking_airport/data/remote/repositories/assignJob_repo.dart';
import 'package:driver_tracking_airport/data/remote/repositories/searchVehicle_repo.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';

class CreateJobController extends GetxController {
  final SearchVehicleRepository _repository = SearchVehicleRepository();
  final AssignJobRepository _assignJobRepository = AssignJobRepository();
  final LoginController _loginController = Get.find<LoginController>();

  // Text controllers
  final plateController = TextEditingController();

  // Loading state
  final isLoading = false.obs;
  final isAssigningJob = false.obs;

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
    MessageHelper.showError(message, title: title);
  }

  /// Shows success snackbar
  void _showSuccessSnackbar(String message) {
    MessageHelper.showSuccess(message);
  }

  /// Submit vehicle search
  Future<void> submitVehicleSearch() async {
    if (plateController.text.trim().isEmpty) {
      MessageHelper.showError('Please enter vehicle number');
      return;
    }

    try {
      isLoading.value = true;

      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';

      if (driverId.isEmpty) {
        MessageHelper.showError('Driver ID not found. Please login again.');
        return;
      }

      final response = await _repository.searchVehicle(
        driverId: driverId,
        vehicleNo: plateController.text.trim(),
      );

      isLoading.value = false;

      // Handle response based on actionCode
      final actionCode = response['actionCode'];
      final code = response['Code'];
      final message = response['message'] ?? '';

      log("Action Code: $actionCode, Code: $code, Message: $message");

      if (code == 200 || code == '200') {
        // Handle different action codes
        switch (actionCode) {
          case 0:
            // Job not found
            MessageHelper.showInfo('Job is not found', title: 'No Job Found');
            Get.back(); // Return to homepage
            break;

          case 1:
            // Job created successfully
            MessageHelper.showSuccess(
              'Job has been created successfully',
              title: 'Success',
            );
            // Refresh incoming jobs to show updated list
            await _refreshIncomingJobs();
            Get.back(); // Return to homepage
            break;

          case 2:
            // Job already in progress
            MessageHelper.showWarning(
              'Job is already in progress',
              title: 'Job In Progress',
            );
            break;

          case 3:
            // Job already completed
            MessageHelper.showInfo(
              'Job is already completed',
              title: 'Job Completed',
            );
            break;

          case 4:
            // User decision needed - show bottom sheet
            _showShiftReturnBottomSheet(response);
            break;

          default:
            MessageHelper.showInfo(
              message.isNotEmpty ? message : 'Unknown action code',
            );
        }
      } else {
        MessageHelper.showError(
          message.isNotEmpty ? message : 'Failed to search vehicle',
        );
      }
    } catch (e) {
      isLoading.value = false;
      MessageHelper.showError(
        e.toString().replaceAll('Exception: ', ''),
        title: 'Error',
      );
    }
  }

  /// Show bottom sheet for shift/return options (action code 4)
  void _showShiftReturnBottomSheet(Map<String, dynamic> response) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'User Decision Needed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              response['nextAction'] ?? 'Please choose an action',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            // Shift Job Option
            Obx(
              () => _buildOptionTile(
                icon: Icons.swap_horiz,
                title: 'Shift This Job',
                subtitle: 'Transfer this job to another driver',
                color: Colors.blue,
                onTap: isAssigningJob.value
                    ? null
                    : () {
                        _handleShiftJob(response);
                      },
                isLoading: isAssigningJob.value,
              ),
            ),
            const SizedBox(height: 12),
            // Return Job Option
            Obx(
              () => _buildOptionTile(
                icon: Icons.undo,
                title: 'Return This Job',
                subtitle: 'Return the vehicle to the customer',
                color: Colors.orange,
                onTap: isAssigningJob.value
                    ? null
                    : () {
                        _handleReturnJob(response);
                      },
                isLoading: isAssigningJob.value,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isLoading || onTap == null ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle shift job action
  Future<void> _handleShiftJob(Map<String, dynamic> response) async {
    try {
      isAssigningJob.value = true;

      // Extract data from search vehicle response
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response data');
      }

      // Extract BookingID as JobID
      final jobId = data['BookingID']?.toString() ?? '';
      if (jobId.isEmpty) {
        throw Exception('Job ID not found in response');
      }

      // Extract vehicle registration number
      final vehicle = data['Vehicle'] as Map<String, dynamic>?;
      final vehicleNo = vehicle?['RegNo']?.toString() ?? '';
      if (vehicleNo.isEmpty) {
        throw Exception('Vehicle number not found in response');
      }

      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';
      if (driverId.isEmpty) {
        throw Exception('Driver ID not found. Please login again.');
      }

      log(
        "Assigning job - JobID: $jobId, OperationType: Shift, VehicleNo: $vehicleNo",
      );

      // Call assign job API
      final assignResponse = await _assignJobRepository.assignJob(
        driverId: driverId,
        jobId: jobId,
        operationType: 'Shift',
        vehicleNo: vehicleNo,
      );

      // Print API response
      log("Assign job API response: $assignResponse");

      isAssigningJob.value = false;

      // Check if API call was successful
      final code = assignResponse['Code'];
      if (code == 200 || code == '200') {
        // Refresh incoming jobs to show updated list
        await _refreshIncomingJobs();

        // Close bottom sheet if still open
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }

        MessageHelper.showSuccess(
          'Job shifted successfully',
          title: 'Shift Job',
        );

        // Return to homepage
        Get.back();
      } else {
        final errorMessage = assignResponse['message'] ?? 'Failed to shift job';
        throw Exception(errorMessage);
      }
    } catch (e) {
      isAssigningJob.value = false;
      MessageHelper.showError(
        e.toString().replaceAll('Exception: ', ''),
        title: 'Error',
      );
    }
  }

  /// Handle return job action
  Future<void> _handleReturnJob(Map<String, dynamic> response) async {
    try {
      isAssigningJob.value = true;

      // Extract data from search vehicle response
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response data');
      }

      // Extract BookingID as JobID
      final jobId = data['BookingID']?.toString() ?? '';
      if (jobId.isEmpty) {
        throw Exception('Job ID not found in response');
      }

      // Extract vehicle registration number
      final vehicle = data['Vehicle'] as Map<String, dynamic>?;
      final vehicleNo = vehicle?['RegNo']?.toString() ?? '';
      if (vehicleNo.isEmpty) {
        throw Exception('Vehicle number not found in response');
      }

      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';
      if (driverId.isEmpty) {
        throw Exception('Driver ID not found. Please login again.');
      }

      log(
        "Assigning job - JobID: $jobId, OperationType: Return, VehicleNo: $vehicleNo",
      );

      // Call assign job API
      final assignResponse = await _assignJobRepository.assignJob(
        driverId: driverId,
        jobId: jobId,
        operationType: 'Return',
        vehicleNo: vehicleNo,
      );

      // Print API response
      log("Assign job API response: $assignResponse");

      isAssigningJob.value = false;

      // Check if API call was successful
      final code = assignResponse['Code'];
      if (code == 200 || code == '200') {
        // Refresh incoming jobs to show updated list
        await _refreshIncomingJobs();

        // Close bottom sheet if still open
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }

        MessageHelper.showSuccess(
          'Job returned successfully',
          title: 'Return Job',
        );

        // Return to homepage
        Get.back();
      } else {
        final errorMessage =
            assignResponse['message'] ?? 'Failed to return job';
        throw Exception(errorMessage);
      }
    } catch (e) {
      isAssigningJob.value = false;
      MessageHelper.showError(
        e.toString().replaceAll('Exception: ', ''),
        title: 'Error',
      );
    }
  }

  /// Refresh incoming jobs from dashboard controller
  Future<void> _refreshIncomingJobs() async {
    try {
      // Get dashboard controller and refresh incoming jobs
      if (Get.isRegistered<DashBoardController>()) {
        final dashboardController = Get.find<DashBoardController>();
        await dashboardController.loadIncomingJobs();
        log("Incoming jobs refreshed successfully");
      }
    } catch (e) {
      log("Failed to refresh incoming jobs: $e");
      // Don't show error to user, just log it
    }
  }

  @override
  void onClose() {
    // Dispose text recognizer
    _textRecognizer.close();

    // Dispose controllers
    plateController.dispose();
    super.onClose();
  }
}
