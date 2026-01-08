import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/DeliveryModule/delivery_track_screen.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/TrackJob/trackJobScreen.dart';
import 'package:driver_tracking_airport/Screens/modules/ShiftModule/shift_track_screen.dart';
import 'package:driver_tracking_airport/data/services/company_labels_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResumeOngoingJobBanner extends StatelessWidget {
  const ResumeOngoingJobBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<DashBoardController>();
      final job = controller.ongoingJob.value;

      if (job == null) {
        return const SizedBox.shrink();
      }
      final labelsService = Get.find<CompanyLabelsService>();
      final jobTypeLabel = labelsService.getLabelForJobType(job.jobType);
      final jobTypeIcon = job.isParkingJob
          ? Icons.local_parking
          : job.isDeliveryJob
          ? Icons.delivery_dining
          : job.isShiftJob
          ? Icons.directions_run
          : Icons.work_outline;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade500, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(jobTypeIcon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume Ongoing Job',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$jobTypeLabel • ${job.jobId}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _open(job),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Resume',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _open(JobModel job) {
    if (job.isDeliveryJob) {
      Get.to(() => DeliveryTrackScreen(initialJob: job));
      return;
    }
    if (job.isParkingJob) {
      Get.to(() => JobTrackScreen(initialJob: job));
      return;
    }
    if (job.isShiftJob) {
      Get.to(() => ShiftTrackScreen(initialJob: job));
      return;
    }
  }
}
