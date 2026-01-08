import 'package:driver_tracking_airport/COntrollers/location_controller.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/login_screen.dart';
import 'package:driver_tracking_airport/main.dart';
import 'package:driver_tracking_airport/utils/toast_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Homepge/homePage.dart';

class EnableLocationScreen extends StatelessWidget {
  const EnableLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Get.find<LocationController>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Image.asset(
              "assets/enable_location.png",
              alignment: Alignment.center,
            ),
            SizedBox(height: mq.height * 0.05),
            Text(
              "Enable Your Location",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: mq.height * 0.04),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                "We need your location so we can track parkings.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ),
            SizedBox(height: mq.height * 0.05),
            ElevatedButton(
              onPressed: () async {
                await locationProvider.getCurrentLocation();

                if (locationProvider.isPermissionGranted.value) {
                  final loginController = Get.find<LoginController>();
                  await loginController.loadSavedLogin();
                  if (loginController.isLoggedIn.value) {
                    Get.offAll(() => DashboardScreen());
                  } else {
                    Get.offAll(() => LoginScreen());
                  }
                } else {
                  showToastMessage("Please enable location permission");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(mq.width * 0.7, 48),
                textStyle: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Obx(
                () => locationProvider.isLoading.value
                    ? CircularProgressIndicator()
                    : Text(
                        "USE MY LOCATION",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
