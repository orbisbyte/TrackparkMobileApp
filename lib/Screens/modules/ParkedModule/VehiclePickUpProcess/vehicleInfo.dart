import 'package:driver_tracking_airport/Screens/modules/ParkedModule/VehiclePickUpProcess/controller/form_Controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleInfoScreen extends StatelessWidget {
  final FormController controller = Get.find<FormController>();

  VehicleInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    'Fill in the required information',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // License Plate Field
            _buildSectionHeader('License Plate*'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.plateController,
              decoration: InputDecoration(
                hintText: 'ABC 1234',
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
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildSectionHeader('Make'),
                      ),
                      TextFormField(
                        controller: controller.makeController,
                        decoration: InputDecoration(
                          hintText: 'Make (e.g., Toyota)',
                          prefixIcon: const Icon(
                            Icons.branding_watermark,
                            color: Colors.orangeAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildSectionHeader('Model'),
                      ),
                      TextFormField(
                        controller: controller.modelController,
                        decoration: InputDecoration(
                          hintText: 'Model',
                          prefixIcon: const Icon(
                            Icons.timelapse_outlined,
                            color: Colors.blue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color
            _buildSectionHeader('Colour (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.colorController,
              decoration: InputDecoration(
                hintText: 'e.g., Red, Blue',
                prefixIcon: const Icon(
                  Icons.color_lens,
                  color: Color.fromARGB(255, 255, 82, 13),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 40),

            if (controller.currentJob?.vehicle?.passengers != null &&
                int.tryParse(
                      controller.currentJob?.vehicle?.passengers ?? '',
                    ) !=
                    null &&
                int.parse(controller.currentJob?.vehicle?.passengers ?? '0') >
                    0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      "No of Passengers: ${controller.currentJob?.vehicle?.passengers?.toString() ?? ''}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Continue Button
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
