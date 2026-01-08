import 'package:driver_tracking_airport/Screens/EnableLocation/enable_location.dart';
import 'package:driver_tracking_airport/Screens/Homepge/homePage.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../consts/app_consts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LoginController loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add a small delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check location permission
    final status = await Permission.location.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      Get.offAll(() => const EnableLocationScreen());
      return;
    }

    // Check login state
    await loginController.loadSavedLogin();

    if (loginController.isLoggedIn.value) {
      // User is logged in, go to dashboard
      Get.offAll(() => DashboardScreen());
    } else {
      // User is not logged in, go to login
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
