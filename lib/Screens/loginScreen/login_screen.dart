import 'package:driver_tracking_airport/Screens/Homepge/homePage.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/utils/colors.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();
    final RxBool isPasswordVisible = false.obs;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image (Airport theme)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  // Login Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          TextField(
                            controller: controller.emailController,
                            decoration: InputDecoration(
                              labelText: 'Email / Username',
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.blue.shade300,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Obx(
                            () => TextField(
                              controller: controller.passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.blue.shade300,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible.value
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () {
                                    isPasswordVisible.value =
                                        !isPasswordVisible.value;
                                  },
                                ),
                              ),
                              obscureText: !isPasswordVisible.value,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(
                                () => Row(
                                  children: [
                                    Checkbox(
                                      value: controller.rememberMe.value,
                                      onChanged: (value) {
                                        controller.rememberMe.value =
                                            value ?? false;
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.blue.shade400),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign In Button
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () => _handleLogin(controller, context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 3,
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Spacer(),

                          // Footer
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'designed & developed by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Orbis',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(
    LoginController controller,
    BuildContext context,
  ) async {
    // Validate inputs
    if (controller.emailController.text.trim().isEmpty) {
      MessageHelper.showWarning(
        'Please enter your email/username',
        title: 'Validation Error',
      );
      return;
    }

    if (controller.passwordController.text.trim().isEmpty) {
      MessageHelper.showWarning(
        'Please enter your password',
        title: 'Validation Error',
      );
      return;
    }

    try {
      // Get FCM token (optional - can be empty if not available)
      String fcmToken = '';
      // TODO: Get FCM token when firebase_messaging is properly configured
      // try {
      //   fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      // } catch (e) {
      //   // FCM token not available, continue with empty string
      // }

      // Get current location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
        );
      } catch (e) {
        // If location not available, use default values
        position = Position(
          longitude: 0.0,
          latitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }

      // Perform login
      final success = await controller.login(
        username: controller.emailController.text.trim(),
        password: controller.passwordController.text.trim(),
        fcmToken: fcmToken,
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );

      if (success) {
        // Navigate to dashboard
        Get.offAll(() => DashboardScreen());
      }
    } catch (e) {
      MessageHelper.showError(
        'An error occurred: ${e.toString()}',
        title: 'Error',
      );
    }
  }
}
