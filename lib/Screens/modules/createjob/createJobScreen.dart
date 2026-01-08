import 'package:driver_tracking_airport/Screens/modules/createjob/controller/createJob_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateJobScreen extends StatelessWidget {
  const CreateJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CreateJobController controller = Get.put(CreateJobController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Create New Job'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter Vehicle Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan or enter the vehicle number',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // License Plate Field
            _buildSectionHeader('Vehicle Number*'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.plateController,
              decoration: InputDecoration(
                hintText: 'ABC-123',
                prefixIcon: const Icon(
                  Icons.confirmation_number,
                  color: Colors.green,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => controller.scanLicensePlate(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                hintStyle: const TextStyle(color: Colors.grey),
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 16),

              textCapitalization: TextCapitalization.characters,
            ),

            const SizedBox(height: 40),

            // Submit Button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.submitVehicleSearch(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue.shade600,
                    elevation: 2,
                    shadowColor: Colors.blue.shade200,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Search Vehicle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}
