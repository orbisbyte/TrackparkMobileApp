import 'package:driver_tracking_airport/COntrollers/location_controller.dart';
import 'package:driver_tracking_airport/Screens/Homepge/widgets/incoming_jobs_section.dart';
import 'package:driver_tracking_airport/Screens/Homepge/widgets/ongoing_job_section.dart';
import 'package:driver_tracking_airport/Screens/Homepge/widgets/uploads_progress_section.dart';
import 'package:driver_tracking_airport/Screens/modules/createjob/createJobScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../consts/app_consts.dart';
import '../EnableLocation/enable_location.dart';
import 'controller/dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var dashBoardController = Get.put(DashBoardController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dashBoardController.loadIncomingJobs();
      listenLocation();

      dashBoardController.loadOngoingJob();
      // dashBoardController.listenToOngoingJob();
      PermissionStatus status = await Permission.location.status;

      if (status.isDenied || status.isPermanentlyDenied) {
        Get.offAll(() => const EnableLocationScreen());
        return;
      }
    });
  }

  listenLocation() async {
    var locationController = Get.find<LocationController>();

    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      locationController.startLocationStream((lat, lng) {
        // log("updated lat long $lat $lng");
      });
    } else {
      locationController.showPermissionDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(appName),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // // Header Card
            // AvalibilityWidget(
            //   loginController: _loginController,
            //   dashBoardController: dashBoardController,
            // ),

            // const SizedBox(height: 24),
            // Create New Job Button
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.add_circle_outline,
              color: Colors.blue,
              title: 'Create New Job',
              onTap: () => Get.to(() => const CreateJobScreen()),
            ),
            const SizedBox(height: 12),

            // Upload progress section (shows one row per active isolate upload)
            const UploadsProgressSection(),
            const SizedBox(height: 12),

            // Ongoing Job Section (at top)
            // const OngoingJobSection(),
            // if (dashBoardController.ongoingJob.value != null)
            //   const SizedBox(height: 24),
            ResumeOngoingJobBanner(),

            // Incoming Jobs Section
            const IncomingJobsSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
