import 'package:driver_tracking_airport/COntrollers/location_controller.dart';
import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/Screens/Splash/splashScreen.dart';
import 'package:driver_tracking_airport/Screens/loginScreen/controller/login_controller.dart';
import 'package:driver_tracking_airport/data/services/company_labels_service.dart';
import 'package:driver_tracking_airport/data/services/networkConnectivity/network_checker.dart';
import 'package:driver_tracking_airport/data/services/upload_progress/upload_manager_controller.dart';
import 'package:driver_tracking_airport/data/services/upload_progress/upload_retry_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late Size mq;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // This finds your config files automatically

  Get.putAsync(() => NetworkService().init());

  // Initialize company labels service
  Get.put(CompanyLabelsService());
  Get.find<CompanyLabelsService>().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        mq = MediaQuery.sizeOf(context);
        return GetMaterialApp(
          initialBinding: BindingsBuilder(() {
            Get.put(LoginController());
            Get.put(LocationController());
            Get.put(DashBoardController());
            // Upload progress manager (global, used by isolate uploads + dashboard UI)
            Get.put(UploadManagerController(), permanent: true);
            // Retry orchestrator (loads pending uploads + retries on reconnect/app start)
            Get.put(UploadRetryService(), permanent: true);
          }),
          navigatorKey: navigatorKey, // Assign the key here
          title: 'Airport Driver Tracking',

          home: SplashScreen(),
        );
      },
    );
  }
}
