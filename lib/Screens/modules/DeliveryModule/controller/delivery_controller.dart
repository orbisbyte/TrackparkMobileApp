import 'dart:async';
import 'dart:developer';

import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/data/services/firebase/job_firebase_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:driver_tracking_airport/utils/distance_monitor_util.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:get/get.dart';

import '../../../../COntrollers/location_controller.dart';
import '../../../../data/remote/repositories/updateJobParameters_repo.dart';
import '../../../../data/services/media_upload_isolate_service.dart';

class DeliveryController extends GetxController {
  final JobFirebaseService _firebaseService = JobFirebaseService();

  // Use ongoingJob instead of activeJob
  final Rx<JobModel?> ongoingJob = Rx<JobModel?>(null);
  var isUpdating = false.obs;

  // Timer and distance monitoring
  Timer? _distanceCheckTimer;
  Timer? _countdownTimer;
  final RxBool isWithinRadius = false.obs;
  final RxInt remainingSeconds = 300.obs; // 5 minutes = 300 seconds
  final RxBool isTimerActive = false.obs;
  final RxBool isTimerExpired = false.obs;

  @override
  void onClose() {
    _distanceCheckTimer?.cancel();
    _countdownTimer?.cancel();
    super.onClose();
  }

  Future<void> setOngoingJob(JobModel job) async {
    ongoingJob.value = job;
    // Start distance monitoring
    _startDistanceMonitoring();
  }

  /// Start the delivery job - Capture pickup media first
  /// Updates Firebase with status = "started" and pickup media
  Future<void> startJob({
    required List<String> pickupImagePaths,
    required List<String> pickupVideoPaths,
    bool? isDamaged,
    bool? isScratched,
    bool? isDirty,
    String? conditionNotes,
  }) async {
    if (ongoingJob.value == null) return;

    if (pickupImagePaths.isEmpty || pickupVideoPaths.isEmpty) {
      MessageHelper.showError(
        'Please capture photos and required videos before starting the job.',
      );
      return;
    }

    try {
      isUpdating.value = true;
      final job = ongoingJob.value!;
      var locationController = Get.find<LocationController>();
      var startLat = locationController.currentLocation.value?.latitude;
      var startLng = locationController.currentLocation.value?.longitude;

      // Build updated job with pickup media and start timestamp
      final updatedJob = job.copyWith(
        jobStatus: 'started',
        jobStartedTime: DateTime.now(),
        pickupImages: pickupImagePaths,
        // Legacy single-video field: store first clip for backward compatibility
        pickupVideo: pickupVideoPaths.first,
        startLat: startLat,
        startLng: startLng,
      );

      // Single Firestore write with full updated job
      await _firebaseService.updateJob(job.jobId, fullJob: updatedJob);

      // Uploading media in background isolate
      try {
        log(pickupImagePaths.toString());
        log(pickupVideoPaths.toString());
        MediaUploadIsolateService().uploadMediaInBackground(
          driverId: job.driverId ?? '',
          jobId: job.jobId,
          eventType: 'start',
          imagePaths: pickupImagePaths,
          videoPath: pickupVideoPaths.first,
          videoPaths: pickupVideoPaths,
        );
      } catch (e) {
        log("failed to upload media $e");
      }

      // Update job parameters to API
      try {
        UpdateJobParametersRepository updateJobParametersRepo =
            UpdateJobParametersRepository();

        JobModel updatedJobModel = JobModel(
          jobId: job.jobId,
          driverId: job.driverId,
          jobStatus: 'started',
          jobStartedTime: DateTime.now(),
          startLat: startLat,
          startLng: startLng,
        );
        await updateJobParametersRepo.updateJobParameters(
          job: updatedJobModel,
          isDamaged: isDamaged,
          isScratched: isScratched,
          isDirty: isDirty,
          vConditionFlag: 'start', // Pickup media = "start"
          vConditionNotes: conditionNotes,
        );
      } catch (e) {
        log("failed to update job parameters to api $e");
      }

      // Update local reactive variable
      ongoingJob.value = updatedJob;

      // Update dashboard controller locally (no extra Firebase call)
      try {
        final dashboardController = Get.find<DashBoardController>();
        dashboardController.updateOngoingJobLocally(updatedJob);
      } catch (e) {
        log('Dashboard controller not available: $e');
      }

      MessageHelper.showSuccess('Job started successfully!');
    } catch (e) {
      MessageHelper.showError(
        'Failed to start job: ${e.toString().replaceAll('Exception: ', '')}',
        title: 'Error',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Complete the delivery job - Capture completion media first
  /// Updates Firebase with final status, timestamps, and completion media
  Future<void> completeJob({
    required List<String> parkImagePaths,
    required List<String> parkVideoPaths,
    bool? isDamaged,
    bool? isScratched,
    bool? isDirty,
    String? conditionNotes,
  }) async {
    if (ongoingJob.value == null) return;

    if (parkImagePaths.isEmpty || parkVideoPaths.isEmpty) {
      MessageHelper.showError(
        'Please capture photos and required videos before completing the job.',
      );
      return;
    }

    try {
      var locationController = Get.find<LocationController>();
      var lat = locationController.currentLocation.value?.latitude;
      var lng = locationController.currentLocation.value?.longitude;
      isUpdating.value = true;
      final job = ongoingJob.value!;

      // Build updated job with completion media and completion timestamp
      final updatedJob = job.copyWith(
        jobStatus: 'delivered',
        jobCompletedTime: DateTime.now(),
        yardParkImages: parkImagePaths,
        // Legacy single-video field: store first clip for backward compatibility
        yardParkVideo: parkVideoPaths.first,
        endLat: lat,
        endLng: lng,
      );

      // Single Firestore write with full updated job
      await _firebaseService.updateJob(job.jobId, fullJob: updatedJob);

      // Uploading media in background isolate
      try {
        MediaUploadIsolateService().uploadMediaInBackground(
          driverId: job.driverId ?? '',
          jobId: job.jobId,
          eventType: 'end',
          imagePaths: parkImagePaths,
          videoPath: parkVideoPaths.first,
          videoPaths: parkVideoPaths,
        );
      } catch (e) {
        log("failed to upload media $e");
      }

      // Update job parameters to API
      try {
        UpdateJobParametersRepository updateJobParametersRepo =
            UpdateJobParametersRepository();

        JobModel updatedJobModel = JobModel(
          jobId: job.jobId,
          driverId: job.driverId,
          jobStatus: 'delivered',
          jobCompletedTime: DateTime.now(),
          endLat: lat,
          endLng: lng,
        );
        await updateJobParametersRepo.updateJobParameters(
          job: updatedJobModel,
          isDamaged: isDamaged,
          isScratched: isScratched,
          isDirty: isDirty,
          vConditionFlag: 'end', // Completion media = "end"
          vConditionNotes: conditionNotes,
        );
      } catch (e) {
        log("failed to update job parameters to api $e");
      }

      // Update local reactive variable
      ongoingJob.value = updatedJob;

      // Update dashboard controller locally (no extra Firebase call)
      try {
        final dashboardController = Get.find<DashBoardController>();
        dashboardController.updateOngoingJobLocally(updatedJob);
      } catch (e) {
        log('Dashboard controller not available: $e');
      }

      MessageHelper.showSuccess('Job completed successfully!');
    } catch (e) {
      log("failed to complete job $e");
      MessageHelper.showError(
        'Failed to complete job: ${e.toString().replaceAll('Exception: ', '')}',
        title: 'Error',
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Start monitoring distance to target location
  void _startDistanceMonitoring() {
    _distanceCheckTimer?.cancel();

    _distanceCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkDistance();
    });
  }

  /// Check distance to target location
  void _checkDistance() {
    final job = ongoingJob.value;
    if (job == null) return;

    final locationController = Get.find<LocationController>();
    final currentLocation = locationController.currentLocation.value;
    if (currentLocation == null) return;

    // Get target location based on job status
    double? targetLat;
    double? targetLng;
    final status = job.jobStatus?.toLowerCase();

    if (status == 'ontheway') {
      targetLat = job.startLat;
      targetLng = job.startLng;
    } else if (status == 'started') {
      targetLat = job.endLat;
      targetLng = job.endLng;
    }

    if (targetLat == null || targetLng == null) return;

    // Check if within 500m radius
    final withinRadius = DistanceMonitorUtil.isWithinRadius(
      currentLat: currentLocation.latitude,
      currentLng: currentLocation.longitude,
      targetLat: targetLat,
      targetLng: targetLng,
      radiusInMeters: 500,
    );

    if (withinRadius == true && !isWithinRadius.value) {
      // Just entered the radius - start timer
      isWithinRadius.value = true;
      _startCountdownTimer();
    } else if (withinRadius == false && isWithinRadius.value) {
      // Left the radius - stop timer
      isWithinRadius.value = false;
      _stopCountdownTimer();
    }
  }

  /// Start 5-minute countdown timer
  void _startCountdownTimer() {
    if (isTimerActive.value) return; // Already running

    isTimerActive.value = true;
    isTimerExpired.value = false;
    remainingSeconds.value = 300; // 5 minutes = 300 seconds

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        // Timer expired
        _onTimerExpired();
        timer.cancel();
      }
    });
  }

  /// Stop countdown timer
  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    isTimerActive.value = false;
    remainingSeconds.value = 300;
  }

  /// Handle timer expiration - add behavior details and navigate to next step
  Future<void> _onTimerExpired() async {
    isTimerExpired.value = true;
    isTimerActive.value = false;

    final job = ongoingJob.value;
    if (job == null) return;

    final status = job.jobStatus?.toLowerCase();

    // Create behavior entry for time limit exceeded
    final behaviorEntry = <String, dynamic>{
      'jobID': job.jobId,
      'jobType': job.jobType ?? '',
      'jobStatus': job.jobStatus ?? '',
      'timeLimitExceeded': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add to existing driverBehaviour list
    final updatedBehaviour = List<Map<String, dynamic>>.from(
      job.driverBehaviour,
    )..add(behaviorEntry);

    // Update job with new behavior entry
    final updatedJob = job.copyWith(driverBehaviour: updatedBehaviour);

    // Save to Firebase before navigating
    try {
      await _firebaseService.updateJob(
        job.jobId,
        updates: {'driverBehaviour': updatedBehaviour},
      );
      log('Driver behavior saved to Firebase: $behaviorEntry');

      // Update local job model
      ongoingJob.value = updatedJob;
    } catch (e) {
      log('Failed to save driver behavior to Firebase: $e');
      // Continue with navigation even if Firebase update fails
    }

    // Auto-navigate based on status
    if (status == 'ontheway') {
      // Navigate to pickup media screen
      _navigateToPickupMedia();
    } else if (status == 'started') {
      // Navigate to completion media screen
      _navigateToCompletionMedia();
    }
  }

  /// Navigate to pickup media screen (when timer expires on ontheway status)
  void _navigateToPickupMedia() {
    // This will be handled by the track screen observing isTimerExpired
    // The screen will auto-navigate when it detects timer expired
  }

  /// Navigate to completion media screen (when timer expires on started status)
  void _navigateToCompletionMedia() {
    // This will be handled by the track screen observing isTimerExpired
    // The screen will auto-navigate when it detects timer expired
  }

  /// Format remaining time as MM:SS
  String getFormattedRemainingTime() {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Stop timers when user manually proceeds
  void stopTimers() {
    _stopCountdownTimer();
    _distanceCheckTimer?.cancel();
  }
}
