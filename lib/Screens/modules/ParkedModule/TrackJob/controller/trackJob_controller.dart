import 'dart:async';
import 'dart:developer';

import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/data/services/firebase/job_firebase_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:driver_tracking_airport/utils/distance_monitor_util.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:get/get.dart';

import '../../../../../COntrollers/location_controller.dart';
import '../../../../../data/remote/repositories/updateJobParameters_repo.dart';
import '../../../../../data/services/media_upload_isolate_service.dart';

/// Job step tracking enum
enum JobStep {
  track, // Tracking to location
  form, // Filling form
  complete, // Completing job
}

class JobTrackController extends GetxController {
  final JobFirebaseService _firebaseService = JobFirebaseService();

  // Use ongoingJob instead of activeJob
  final Rx<JobModel?> ongoingJob = Rx<JobModel?>(null);
  var isUpdating = false.obs;

  // Step tracking
  final Rx<JobStep> currentStep = JobStep.track.obs;

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

    // Initialize step from job status or stored step
    _initializeStep();

    // Start distance monitoring if on track step
    if (currentStep.value == JobStep.track ||
        currentStep.value == JobStep.complete) {
      _startDistanceMonitoring();
    }
  }

  /// Initialize current step based on job status
  void _initializeStep() {
    final job = ongoingJob.value;
    if (job == null) return;

    final status = job.jobStatus?.toLowerCase();

    // If job is ontheway and we haven't started form, stay on track
    if (status == 'ontheway') {
      currentStep.value = JobStep.track;
    }
    // If job is started, we're past form, so we're on complete step
    else if (status == 'started') {
      currentStep.value = JobStep.complete;
    }
    // For other statuses, default to track
    else {
      currentStep.value = JobStep.track;
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
    // remainingSeconds.value = 60; // 5 minutes = 300 seconds
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
    // Ensure we have a valid list (should never be null after model fix, but defensive check)
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

    // Mark time exceeded at start or end
    if (status == 'ontheway') {
      // Navigate to form screen
      _navigateToNextStep();
    } else if (status == 'started') {
      // Navigate to complete job (park media screen)
      _navigateToNextStep();
    }
  }

  /// Navigate to next step based on current status
  void _navigateToNextStep() {
    final job = ongoingJob.value;
    if (job == null) return;

    final status = job.jobStatus?.toLowerCase();

    if (status == 'ontheway') {
      // Navigate to form screen
      currentStep.value = JobStep.form;
      // Navigation will be handled by the screen
    } else if (status == 'started') {
      // Navigate to complete job
      currentStep.value = JobStep.complete;
      // Navigation will be handled by the screen
    }
  }

  /// Mark that user has moved to form step
  void markFormStepReached() {
    currentStep.value = JobStep.form;
    _stopCountdownTimer();
    _distanceCheckTimer?.cancel();
  }

  /// Format remaining time as MM:SS
  String getFormattedRemainingTime() {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Complete the job with parking-time media (photos + video)
  /// Updates Firebase with final status, timestamps, and parking media,
  /// then updates local state and dashboard controller.
  Future<void> completeJob({
    required List<String> parkImagePaths,
    required List<String> parkVideoPaths,
    required String? parkingNotes,
    bool? isDamaged,
    bool? isScratched,
    bool? isDirty,
    String? conditionNotes,
  }) async {
    if (ongoingJob.value == null) return;

    if (parkImagePaths.isEmpty || parkVideoPaths.isEmpty) {
      MessageHelper.showError(
        'Please attach parking photos and required videos before completing the job.',
      );
      return;
    }

    // Vehicle condition flags (isDamaged, isScratched) are available here
    // and can be added to JobModel/API when needed

    try {
      var locationController = Get.find<LocationController>();
      var lat = locationController.currentLocation.value?.latitude;
      var lng = locationController.currentLocation.value?.longitude;
      isUpdating.value = true;
      final job = ongoingJob.value!;

      // Build updated job with parking media and completion timestamp
      final updatedJob = job.copyWith(
        jobStatus: 'parked',
        jobCompletedTime: DateTime.now(),
        yardParkImages: parkImagePaths,
        // Legacy single-video field kept for backward compatibility.
        // For multi-clips, the first captured clip is stored here.
        yardParkVideo: parkVideoPaths.first,
        endLat: lat,
        endLng: lng,
        yardParkSlotInfo: parkingNotes,
      );

      // Single Firestore write with full updated job (status + timestamps + media)
      await _firebaseService.updateJob(job.jobId, fullJob: updatedJob);

      //uploading media in background isolate
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

      //update job parameters to api
      try {
        UpdateJobParametersRepository updateJobParametersRepo =
            UpdateJobParametersRepository();

        JobModel updatedJobModel = JobModel(
          jobId: job.jobId,
          driverId: job.driverId,
          jobStatus: 'parked',
          jobCompletedTime: DateTime.now(),
          yardParkSlotInfo: parkingNotes,
          endLat: lat,
          endLng: lng,
        );
        await updateJobParametersRepo.updateJobParameters(
          job: updatedJobModel,
          isDamaged: isDamaged,
          isScratched: isScratched,
          isDirty: isDirty,
          vConditionFlag: 'end', // Parking media = "end"
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
        // Dashboard controller might not be available, ignore
        print('Dashboard controller not available: $e');
      }

      MessageHelper.showSuccess('Job parked successfully!');
    } catch (e) {
      MessageHelper.showError(
        'Failed to complete job: ${e.toString().replaceAll('Exception: ', '')}',
        title: 'Error',
      );
    } finally {
      isUpdating.value = false;
    }
  }
}
