import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

import '../../loginScreen/controller/login_controller.dart';
import '../controller/dashboard_controller.dart';

class AvalibilityWidget extends StatelessWidget {
  const AvalibilityWidget({
    super.key,
    required LoginController loginController,
    required this.dashBoardController,
  }) : _loginController = loginController;

  final LoginController _loginController;
  final DashBoardController dashBoardController;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        color: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_loginController.currentDriver?.fullName ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to park some cars?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: dashBoardController.isAvailable.value
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dashBoardController.isAvailable.value
                            ? Colors.green
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: dashBoardController.isAvailable.value
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dashBoardController.isAvailable.value
                              ? 'Available'
                              : 'Busy',
                          style: TextStyle(
                            color: dashBoardController.isAvailable.value
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Sharing
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: dashBoardController.isAvailable.value
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'My Availability Status',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: dashBoardController.isAvailable.value,
                      activeThumbColor: Colors.green,
                      onChanged: (value) {
                        dashBoardController.setAvailabilityStatus(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
