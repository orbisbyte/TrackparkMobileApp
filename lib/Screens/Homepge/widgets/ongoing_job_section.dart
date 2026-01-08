import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/DeliveryModule/delivery_track_screen.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/TrackJob/controller/trackJob_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/TrackJob/trackJobScreen.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/formScreen.dart';
import 'package:driver_tracking_airport/Screens/modules/ShiftModule/shift_track_screen.dart';
import 'package:driver_tracking_airport/data/services/company_labels_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Ongoing Job Section Widget
class OngoingJobSection extends StatelessWidget {
  const OngoingJobSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<DashBoardController>();
      final ongoingJob = controller.ongoingJob.value;

      if (ongoingJob == null) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _handleJobTap(ongoingJob),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(ongoingJob),
                const SizedBox(height: 16),
                _buildJobDetails(ongoingJob),
                const SizedBox(height: 12),
                _buildTapToContinue(),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Handle job tap based on status and current step
  void _handleJobTap(JobModel job) {
    final status = job.jobStatus?.toLowerCase();
    // Navigate based on job type
    if (job.isDeliveryJob) {
      // For delivery jobs, navigate to delivery track screen
      Get.to(() => DeliveryTrackScreen(initialJob: job));
    } else if (job.isParkingJob) {
      if (status == 'started') {
        Get.to(() => JobTrackScreen(initialJob: job));
      } else if (status == 'ontheway') {
        // Check if we have a track controller and what step we're on
        try {
          final trackController = Get.find<JobTrackController>();
          final currentStep = trackController.currentStep.value;

          // If we're on form step, navigate directly to form
          if (currentStep == JobStep.form) {
            Get.to(() => ReceiveJobForm(job: job));
            return;
          }
        } catch (e) {
          // Controller not found, proceed with normal navigation
        }

        // For parking jobs, navigate to track screen first (showing pickup location)
        Get.to(() => JobTrackScreen(initialJob: job));
      }
    } else if (job.isShiftJob) {
      // For shift jobs, navigate to shift track screen
      Get.to(() => ShiftTrackScreen(initialJob: job));
    }
  }

  /// Build header section
  Widget _buildHeader(JobModel job) {
    // Get label from company labels service
    final labelsService = Get.find<CompanyLabelsService>();
    final jobTypeLabel = labelsService.getLabelForJobType(job.jobType);
    final jobTypeIcon = job.isParkingJob
        ? Icons.local_parking
        : job.isDeliveryJob
        ? Icons.delivery_dining
        : job.isShiftJob
        ? Icons.directions_run
        : Icons.help;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(jobTypeIcon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '$jobTypeLabel • ${job.jobId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (job.dateTime != null)
          Text(
            _formatDateTimeShort(job.dateTime!),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  /// Build job details section
  Widget _buildJobDetails(JobModel job) {
    // Determine FROM and TO based on job type
    String? fromId;
    String? fromName;
    IconData fromIcon;
    String? toId;
    String? toName;
    IconData toIcon;

    if (job.isParkingJob) {
      // RECEIVE: FROM = Terminal, TO = Yard
      fromId = job.terminalId;
      fromName = job.terminalName;
      fromIcon = Icons.location_on;
      toId = job.toYardId;
      toName = job.toYardName;
      toIcon = Icons.local_parking;
    } else if (job.isDeliveryJob) {
      // RETURN: FROM = Yard, TO = Terminal
      fromId = job.toYardId;
      fromName = job.toYardName;
      fromIcon = Icons.local_parking;
      toId = job.terminalId;
      toName = job.terminalName;
      toIcon = Icons.location_on;
    } else if (job.isShiftJob) {
      // SHIFT: FROM = Yard, TO = Empty (no second yard info)
      fromId = job.toYardId;
      fromName = job.toYardName;
      fromIcon = Icons.local_parking;
      toId = null;
      toName = null;
      toIcon = Icons.local_parking;
    } else {
      // Unknown job type - show nothing
      return const SizedBox.shrink();
    }

    // Only show if we have at least FROM information
    if (fromId == null && fromName == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FROM/TO Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // FROM Label - Left Aligned
            if (fromId != null || fromName != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'FROM',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            // TO Label - Right Aligned
            if (toId != null || toName != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TO',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // FROM/TO IDs Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // FROM Section - Left Aligned (Icon + Text)
            if (fromId != null || fromName != null)
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      fromIcon,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fromId ?? fromName ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // TO Section - Right Aligned (Text + Icon)
            if (toId != null || toName != null)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        toId ?? toName ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      toIcon,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
          ],
        ),
        // FROM/TO Names Row (if available and different from IDs)
        if ((fromName != null && fromName != fromId) ||
            (toName != null && toName != toId)) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // FROM Name - Left Aligned (Icon + Text)
              if (fromName != null && fromName != fromId)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fromName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // TO Name - Right Aligned (Text + Icon)
              if (toName != null && toName != toId)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          toName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        // Vehicle Details
        if (job.vehicle != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${job.vehicle!.make ?? ''} ${job.vehicle!.model ?? ''} • ${job.vehicle!.regNo ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Format date time for short display
  String _formatDateTimeShort(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Build tap to continue section
  Widget _buildTapToContinue() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Tap to continue job',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      ],
    );
  }
}
