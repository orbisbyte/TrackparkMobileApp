import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:driver_tracking_airport/utils/snackBar.dart';
import 'package:get/get.dart';

final RxBool isInternetConnected = true.obs;

class NetworkService extends GetxService {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  /// Call this to fully initialize the service.
  Future<NetworkService> init() async {
    await _checkInitialConnection();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
    return this;
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isInternetConnected.value = result != ConnectivityResult.none;
    if (result == ConnectivityResult.none) {
      // Get.snackbar("No Internet", "You're offline");
      if (Get.context != null) {
        showCustomSnackBar(
          message: "You're offline",
          title: "No Internet",
          isError: true,
        );
      }
    }
    log(
      "Network status changed: ${isInternetConnected.value ? 'Online' : 'Offline'}",
    );
  }

  Future<bool> checkConnectionNow() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
