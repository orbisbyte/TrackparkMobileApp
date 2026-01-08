import 'package:driver_tracking_airport/Screens/Homepge/homePage.dart';
import 'package:driver_tracking_airport/Screens/modules/ShiftModule/controller/shift_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/ShiftModule/shift_media_screen.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ParkedModule/TrackJob/googlemap/mapView.dart';

class ShiftTrackScreen extends StatelessWidget {
  final JobModel initialJob;

  const ShiftTrackScreen({super.key, required this.initialJob});

  @override
  Widget build(BuildContext context) {
    final ShiftController shiftController = Get.put(ShiftController());
    shiftController.setOngoingJob(initialJob);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final job = shiftController.ongoingJob.value ?? initialJob;
          final status = job.jobStatus?.toLowerCase();
          if (status == 'ontheway') {
            return const Text('Navigate to Pickup');
          } else if (status == 'started') {
            return const Text('Navigate to Shift');
          }
          return const Text('Shift Tracking');
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Obx(() {
        final job = shiftController.ongoingJob.value ?? initialJob;
        return Column(
          children: [
            // Map Section
            Expanded(flex: 1, child: JobMapWidget(job: job)),

            // Timer Banner (if within radius)
            if (shiftController.isWithinRadius.value &&
                shiftController.isTimerActive.value)
              _buildTimerBanner(shiftController),

            // Job Info Section
            Expanded(
              flex: 1,
              child: ShiftJobInfoSection(controller: shiftController),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final job = shiftController.ongoingJob.value ?? initialJob;
        return _buildBottomActionBar(job, shiftController);
      }),
    );
  }

  /// Build timer banner widget
  Widget _buildTimerBanner(ShiftController controller) {
    return Obx(() {
      final isExpired = controller.isTimerExpired.value;
      final remainingTime = controller.getFormattedRemainingTime();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isExpired ? Colors.red : Colors.red.shade600,
          border: const Border(
            bottom: BorderSide(color: Colors.white, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpired ? Icons.warning : Icons.timer,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              isExpired
                  ? 'Time Exceeded! Proceeding to next step...'
                  : 'Start procedure within: $remainingTime',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build bottom action bar based on job status
  Widget _buildBottomActionBar(JobModel job, ShiftController controller) {
    final status = job.jobStatus?.toLowerCase();

    if (status == 'ontheway') {
      // Show "Start Job" button - navigate to terminal first
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(() {
            // If timer expired, auto-navigate to pickup media screen
            if (controller.isTimerExpired.value) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                controller.isTimerExpired.value = false; // Reset flag
                controller.stopTimers();

                final result = await Get.to<ShiftMediaResult?>(
                  () => ShiftMediaScreen(
                    headerTitle: 'Pickup Documentation',
                    headerSubtitle:
                        'Capture photos and video of the vehicle at pickup location.',
                    photosTitle: 'Pickup Photos',
                    videoTitle: 'Pickup Video Walkaround',
                    buttonText: 'Start Job',
                  ),
                );

                if (result == null) {
                  // User backed out, reset timer expired state
                  controller.isTimerExpired.value = false;
                  return;
                }

                await controller.startJob(
                  pickupImagePaths: result.imagePaths,
                  pickupVideoPaths: result.videoPathList,
                  isDamaged: result.isDamaged,
                  isScratched: result.isScratched,
                  isDirty: result.isDirty,
                  conditionNotes: result.conditionNotes,
                );
              });
            }

            return ShiftJobInfoSection._buildGradientButton(
              onPressed:
                  controller.isUpdating.value || controller.isTimerExpired.value
                  ? null
                  : () async {
                      // Stop timers when user manually proceeds
                      controller.stopTimers();

                      // Navigate to pickup media screen first
                      final result = await Get.to<ShiftMediaResult?>(
                        () => ShiftMediaScreen(
                          headerTitle: 'Pickup Documentation',
                          headerSubtitle:
                              'Capture photos and video of the vehicle at pickup location.',
                          photosTitle: 'Pickup Photos',
                          videoTitle: 'Pickup Video Walkaround',
                          buttonText: 'Start Job',
                        ),
                      );

                      // User backed out without attaching media
                      if (result == null) return;

                      await controller.startJob(
                        pickupImagePaths: result.imagePaths,
                        pickupVideoPaths: result.videoPathList,
                        isDamaged: result.isDamaged,
                        isScratched: result.isScratched,
                        isDirty: result.isDirty,
                      );

                      // Navigate back to track screen (now with started status)
                      // The screen will automatically update via Obx
                      // No need to navigate - Obx will update the UI
                    },
              text: controller.isUpdating.value
                  ? 'STARTING...'
                  : controller.isTimerExpired.value
                  ? 'PROCEEDING...'
                  : 'START JOB',
              icon: controller.isUpdating.value
                  ? Icons.hourglass_empty
                  : controller.isTimerExpired.value
                  ? Icons.hourglass_empty
                  : Icons.play_arrow,
              gradient: controller.isTimerExpired.value
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                    ),
            );
          }),
        ),
      );
    } else if (status == 'started') {
      // Show "Complete Job" button - navigate to user location
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(() {
            // If timer expired, auto-navigate to completion media screen
            if (controller.isTimerExpired.value) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                controller.isTimerExpired.value = false; // Reset flag
                controller.stopTimers();

                final result = await Get.to<ShiftMediaResult?>(
                  () => ShiftMediaScreen(
                    headerTitle: 'Completion Documentation',
                    headerSubtitle:
                        'Capture photos and video of the vehicle at shift location.',
                    photosTitle: 'Completion Photos',
                    videoTitle: 'Completion Video Walkaround',
                    buttonText: 'Complete Job',
                  ),
                );

                if (result == null) {
                  // User backed out, reset timer expired state
                  controller.isTimerExpired.value = false;
                  return;
                }

                await controller.completeJob(
                  parkImagePaths: result.imagePaths,
                  parkVideoPaths: result.videoPathList,
                  isDamaged: result.isDamaged,
                  isScratched: result.isScratched,
                  isDirty: result.isDirty,
                  conditionNotes: result.conditionNotes,
                );

                Get.offAll(() => DashboardScreen());
              });
            }

            return ShiftJobInfoSection._buildGradientButton(
              onPressed:
                  controller.isUpdating.value || controller.isTimerExpired.value
                  ? null
                  : () async {
                      // Stop timers when user manually proceeds
                      controller.stopTimers();

                      // Navigate to completion media screen first
                      final result = await Get.to<ShiftMediaResult?>(
                        () => ShiftMediaScreen(
                          headerTitle: 'Completion Documentation',
                          headerSubtitle:
                              'Capture photos and video of the vehicle at shift location.',
                          photosTitle: 'Completion Photos',
                          videoTitle: 'Completion Video Walkaround',
                          buttonText: 'Complete Job',
                        ),
                      );

                      // User backed out without attaching media
                      if (result == null) return;

                      await controller.completeJob(
                        parkImagePaths: result.imagePaths,
                        parkVideoPaths: result.videoPathList,
                        isDamaged: result.isDamaged,
                        isScratched: result.isScratched,
                        isDirty: result.isDirty,
                      );

                      Get.offAll(() => DashboardScreen());
                    },
              text: controller.isUpdating.value
                  ? 'COMPLETING...'
                  : controller.isTimerExpired.value
                  ? 'PROCEEDING...'
                  : 'COMPLETE JOB',
              icon: controller.isUpdating.value
                  ? Icons.hourglass_empty
                  : controller.isTimerExpired.value
                  ? Icons.hourglass_empty
                  : Icons.check,
              gradient: controller.isTimerExpired.value
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
            );
          }),
        ),
      );
    } else if (status == 'parked') {
      // Job completed
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
                SizedBox(width: 12),
                Text(
                  'Job Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class ShiftJobInfoSection extends StatelessWidget {
  final ShiftController controller;

  const ShiftJobInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final job = controller.ongoingJob.value;
      if (job == null) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildStatusCard(job.jobStatus ?? 'Pending'),
              const SizedBox(height: 16),
              _buildTerminalInfoCard(job),
              const SizedBox(height: 12),
              _buildJobDetailsCard(job),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'ontheway':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'On The Way';
        statusIcon = Icons.directions_car;
        break;
      case 'started':
        statusColor = const Color(0xFF6366F1);
        statusText = 'Job Started';
        statusIcon = Icons.play_circle_outline;
        break;
      case 'parked':
        statusColor = const Color(0xFF059669);
        statusText = 'Completed';
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = const Color(0xFF6366F1);
        statusText = status;
        statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(statusIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build terminal/destination information card
  Widget _buildTerminalInfoCard(JobModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Destination Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (job.terminalId != null) ...[
            _buildInfoRow(
              Icons.location_on,
              'Terminal ID',
              job.terminalId!,
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],
          if (job.airportId != null) ...[
            _buildInfoRow(
              Icons.flight_takeoff,
              'Airport ID',
              job.airportId!,
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],
          if (job.flightNo != null) ...[
            _buildInfoRow(
              Icons.flight,
              'Flight Number',
              job.flightNo!,
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// Build job details card
  Widget _buildJobDetailsCard(JobModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.purple.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Job Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (job.bookingRef != null) ...[
            _buildInfoRow(
              Icons.confirmation_number,
              'Booking Reference',
              job.bookingRef!,
              Colors.purple,
            ),
            const SizedBox(height: 12),
          ],
          if (job.customerName != null) ...[
            _buildInfoRow(
              Icons.person,
              'Customer',
              job.customerName!,
              Colors.purple,
            ),
            const SizedBox(height: 12),
          ],
          if (job.vehicle != null) ...[
            _buildInfoRow(
              Icons.directions_car,
              'Vehicle',
              '${job.vehicle!.make ?? ''} ${job.vehicle!.model ?? ''} - ${job.vehicle!.regNo ?? ''}',
              Colors.purple,
            ),
            const SizedBox(height: 12),
          ],
          if (job.dateTime != null) ...[
            _buildInfoRow(
              Icons.access_time,
              'Scheduled Time',
              _formatDateTime(job.dateTime!),
              Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  /// Build info row widget
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
