import 'dart:async';
import 'dart:developer';

import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/DeliveryModule/delivery_track_screen.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/TrackJob/trackJobScreen.dart';
import 'package:driver_tracking_airport/Screens/modules/ShiftModule/shift_track_screen.dart';
import 'package:driver_tracking_airport/data/remote/repositories/incoming_jobs_repository.dart';
import 'package:driver_tracking_airport/data/services/firebase/job_firebase_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:get/get.dart';

import '../../../data/remote/repositories/updateJobParameters_repo.dart';

class DashBoardController extends GetxController {
  final IncomingJobsRepository _incomingJobsRepo = IncomingJobsRepository();
  final UpdateJobParametersRepository _updateJobParametersRepo =
      UpdateJobParametersRepository();

  final JobFirebaseService _firebaseService = JobFirebaseService();
  final LoginController _loginController = Get.find<LoginController>();

  var isAvailable = true.obs;

  void setAvailabilityStatus(bool value) {
    isAvailable.value = value;
  }

  // Incoming jobs (assigned from API)
  RxList<JobModel> incomingJobs = <JobModel>[].obs;
  RxBool isLoadingIncomingJobs = false.obs;

  // Auto-reload timer for incoming jobs (2 minutes)
  Timer? _incomingJobsAutoReloadTimer;

  // Ongoing job (currently active)
  final Rxn<JobModel> ongoingJob = Rxn<JobModel>();
  RxBool isLoadingOngoingJob = false.obs;
  // Track which specific job is being started (by jobId)
  var startingJobId = Rxn<String>();

  /// Load incoming jobs from API
  Future<void> loadIncomingJobs() async {
    isLoadingIncomingJobs.value = true;
    try {
      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';

      final apiJobs = await _incomingJobsRepo.getIncomingJobs(
        driverId: driverId,
      );

      // Update incoming jobs list
      incomingJobs.assignAll(apiJobs);

      // Start auto-reload timer if not already running
      _startIncomingJobsAutoReload();

      // // Also save to local DB for offline access
      // for (final job in apiJobs) {
      //   try {
      //     // Check if job already exists
      //     final existingJobs = await JobDatabase.instance.getAllJobs();
      //     final exists = existingJobs.any((j) => j.jobId == job.jobId);

      //     if (!exists) {
      //       // Set driver ID if not set
      //       final jobWithDriver = job.copyWith(
      //         driverId: driverId,
      //       );
      //       await JobDatabase.instance.insertJob(jobWithDriver);
      //     }
      //   } catch (e) {
      //     // Ignore duplicate or other errors
      //   }
      // }
    } catch (e) {
      incomingJobs.clear();
      log("failed to load incoming jobs $e");
    } finally {
      isLoadingIncomingJobs.value = false;
    }
  }

  /// Start auto-reload timer for incoming jobs (2 minutes)
  void _startIncomingJobsAutoReload() {
    // Cancel existing timer if any
    _incomingJobsAutoReloadTimer?.cancel();

    // Start new timer - reload every 2 minutes (120 seconds)
    _incomingJobsAutoReloadTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) {
      // Only reload if not already loading
      if (!isLoadingIncomingJobs.value) {
        log('Auto-reloading incoming jobs...');
        loadIncomingJobs();
      }
    });
  }

  /// Stop auto-reload timer for incoming jobs
  void _stopIncomingJobsAutoReload() {
    _incomingJobsAutoReloadTimer?.cancel();
    _incomingJobsAutoReloadTimer = null;
  }

  /// Refresh both local and incoming jobs
  Future<void> refreshJobs() async {
    await Future.wait([loadIncomingJobs()]);
  }

  /// Check if driver has an ongoing job
  bool get hasOngoingJob {
    final job = ongoingJob.value;
    if (job == null) return false;

    // Check if job status is active (ontheway or started)
    final status = job.jobStatus?.toLowerCase();
    return status == 'ontheway' || status == 'started';
  }

  /// Start a job - Check type and handle accordingly
  Future<void> acceptJob(JobModel job) async {
    try {
      // First check if driver already has an ongoing job
      if (hasOngoingJob) {
        MessageHelper.showWarning(
          'You already have an ongoing job. Please complete it before starting a new one.',
          title: 'Job in Progress',
        );
        return;
      }

      // Set loading state for this specific job
      startingJobId.value = job.jobId;
      isLoadingOngoingJob.value = true;

      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';

      if (driverId.isEmpty) {
        startingJobId.value = null;
        isLoadingOngoingJob.value = false;
        MessageHelper.showError('Driver ID not found. Please login again.');
        return;
      }

      // Double-check from Firebase if there's an ongoing job
      final existingOngoingJob = await _firebaseService.getOngoingJob(driverId);
      if (existingOngoingJob != null) {
        startingJobId.value = null;
        isLoadingOngoingJob.value = false;
        ongoingJob.value = existingOngoingJob;
        MessageHelper.showWarning(
          'You already have an ongoing job. Please complete it before starting a new one.',
          title: 'Job in Progress',
        );
        return;
      }

      // Update job with driver ID, status, and start time
      final updatedJob = job.copyWith(
        driverId: driverId,
        jobStatus: 'ontheway',
        jobAcceptedTime: DateTime.now(),
      );

      // Save to Firebase
      await _firebaseService.startJob(updatedJob, driverId: driverId);

      //send data to api for update job parameters
      try {
        JobModel updatedJobModel = JobModel(
          jobId: updatedJob.jobId,
          driverId: driverId,
          jobAcceptedTime: DateTime.now(),
          jobStatus: 'ontheway',
        );
        await _updateJobParametersRepo.updateJobParameters(
          job: updatedJobModel,
        );
      } catch (e) {
        // TODO
        log("failed	to update paramters to api $e");
      }

      // Update ongoing job locally (no Firebase call needed - already saved)
      updateOngoingJobLocally(updatedJob);

      MessageHelper.showSuccess('Job accepted successfully!');

      // Clear loading state
      startingJobId.value = null;
      isLoadingOngoingJob.value = false;

      // Navigate based on job type
      if (job.isDeliveryJob) {
        // For delivery jobs, navigate to delivery track screen
        Get.to(() => DeliveryTrackScreen(initialJob: updatedJob));
      } else if (job.isParkingJob) {
        // For parking jobs, navigate to track screen first (showing pickup location)
        Get.to(() => JobTrackScreen(initialJob: updatedJob));
      } else if (job.isShiftJob) {
        // For shift jobs, navigate to shift track screen
        Get.to(() => ShiftTrackScreen(initialJob: updatedJob));
      } else {
        MessageHelper.showError('Unknown job type');
      }
    } catch (e) {
      MessageHelper.showError(
        'Failed to start job: ${e.toString().replaceAll('Exception: ', '')}',
        title: 'Error',
      );
    } finally {
      startingJobId.value = null;
      isLoadingOngoingJob.value = false;
    }
  }

  /// Load ongoing job from Firebase
  /// Fetches job with status 'ontheway' or 'started'
  Future<void> loadOngoingJob() async {
    try {
      isLoadingOngoingJob.value = true;

      final driverId =
          _loginController.currentDriver?.driverID.toString() ?? '';

      if (driverId.isEmpty) {
        ongoingJob.value = null;
        return;
      }

      // Fetch from Firebase - only jobs with active status
      final job = await _firebaseService.getOngoingJob(driverId);

      if (job != null) {
        // Verify job status is active
        final status = job.jobStatus?.toLowerCase();
        if (status == 'ontheway' || status == 'started') {
          ongoingJob.value = job;

          // // Also save to local DB for offline access
          // try {
          //   final existingJobs = await JobDatabase.instance.getAllJobs();
          //   final exists = existingJobs.any((j) => j.jobId == job.jobId);

          //   if (!exists) {
          //     await JobDatabase.instance.insertJob(job);
          //   } else {
          //     await JobDatabase.instance.updateJobById(job);
          //   }
          // } catch (e) {
          //   print('Error saving ongoing job to local DB: $e');
          // }
        } else {
          // Job exists but status is not active
          ongoingJob.value = null;
        }
      } else {
        ongoingJob.value = null;
      }
    } catch (e) {
      print('Error loading ongoing job: $e');
      ongoingJob.value = null;
    } finally {
      isLoadingOngoingJob.value = false;
    }
  }

  /// Refresh ongoing job from Firebase
  Future<void> refreshOngoingJob() async {
    await loadOngoingJob();
  }

  /// Update ongoing job locally (without Firebase call)
  /// Use this when you already have the updated job data
  void updateOngoingJobLocally(JobModel updatedJob) {
    ongoingJob.value = updatedJob;

    // Also update in incoming jobs list if it exists there
    final index = incomingJobs.indexWhere((j) => j.jobId == updatedJob.jobId);
    if (index != -1) {
      incomingJobs[index] = updatedJob;
    }

    // Save to local DB in background (don't await to avoid blocking)
    // _saveJobToLocalDB(updatedJob);
  }

  /// Save job to local DB (background operation)
  // Future<void> _saveJobToLocalDB(JobModel job) async {
  //   try {
  //     final existingJobs = await JobDatabase.instance.getAllJobs();
  //     final exists = existingJobs.any((j) => j.jobId == job.jobId);

  //     if (!exists) {
  //       await JobDatabase.instance.insertJob(job);
  //     } else {
  //       await JobDatabase.instance.updateJobById(job);
  //     }
  //   } catch (e) {
  //     print('Error saving job to local DB: $e');
  //   }
  // }

  @override
  void onClose() {
    // Cancel auto-reload timer
    _stopIncomingJobsAutoReload();
    super.onClose();
  }
}
