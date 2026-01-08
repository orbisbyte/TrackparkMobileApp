import 'package:driver_tracking_airport/data/local/local_shared_pref.dart';
import 'package:driver_tracking_airport/data/remote/repositories/DriverLogin_repository.dart';
import 'package:driver_tracking_airport/models/driver_model.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final DriverLoginRepository _repository = DriverLoginRepository();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rememberMe = false.obs;

  // Loading state
  final isLoading = false.obs;

  // Driver model
  final Rxn<DriverModel> driverModel = Rxn<DriverModel>();

  // Login state
  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedLogin();
  }

  /// Load saved login state and driver model
  Future<void> loadSavedLogin() async {
    try {
      final loggedIn = await LocalSharedPref.isLoggedIn();
      isLoggedIn.value = loggedIn;

      if (loggedIn) {
        final savedDriver = await LocalSharedPref.getDriverModel();
        if (savedDriver != null) {
          driverModel.value = savedDriver;
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Perform login
  Future<bool> login({
    required String username,
    required String password,
    required String fcmToken,
    required String latitude,
    required String longitude,
  }) async {
    try {
      isLoading.value = true;

      // Call API
      final driver = await _repository.driverLogin(
        username: username,
        password: password,
        fcmToken: fcmToken,
        latitude: latitude,
        longitude: longitude,
      );

      // Save driver model
      driverModel.value = driver;

      // Save to local storage
      await LocalSharedPref.saveDriverModel(driver);
      await LocalSharedPref.saveAppToken(driver.appToken);
      await LocalSharedPref.setLoggedIn(true);

      // Update login state
      isLoggedIn.value = true;

      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      MessageHelper.showError(
        e.toString().replaceAll('Exception: ', ''),
        title: 'Login Failed',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Clear local storage
      await LocalSharedPref.logout();

      // Clear controller state
      driverModel.value = null;
      isLoggedIn.value = false;
      emailController.clear();
      passwordController.clear();
      rememberMe.value = false;
    } catch (e) {
      // Handle error
    }
  }

  /// Get current driver model
  DriverModel? get currentDriver => driverModel.value;

  /// Get app token
  Future<String?> getAppToken() async {
    return await LocalSharedPref.getAppToken();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
