import 'dart:async';
import 'dart:developer' as developer;

import 'package:driver_tracking_airport/utils/toast_message.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationController extends GetxController {
  Rx<LatLng?> currentLocation = Rx<LatLng?>(null);

  RxBool isLoading = false.obs;
  RxBool isPermissionGranted = false.obs;
  StreamSubscription<Position>? _positionStream;

  @override
  void onClose() {
    _positionStream?.cancel();
    super.onClose();
  }

  /// ✅ Get permission & location once
  Future<void> getCurrentLocation() async {
    isLoading.value = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLoading.value = false;
        showToastMessage("Please enable location Service");
        return;
      }

      PermissionStatus status = await Permission.location.status;
      if (status.isGranted) {
        isPermissionGranted.value = true;
      }
      if (status.isDenied) {
        status = await Permission.location.request();
        if (status.isGranted) {
          isPermissionGranted.value = true;
        } else {
          isLoading.value = false;
          throw Exception('Location permission denied.');
        }
        if (status.isDenied) {
          isLoading.value = false;
          throw Exception('Location permission denied.');
        }
      }

      if (status.isPermanentlyDenied) {
        isLoading.value = false;
        showPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation.value = LatLng(position.latitude, position.longitude);
      developer.log(
        '📍 One-time location: ${currentLocation.value!.latitude}, ${currentLocation.value!.longitude}',
      );
    } catch (e) {
      debugPrint('Location error: $e');
    }

    isLoading.value = false;
  }

  /// ✅ Start location tracking stream
  void startLocationStream(Function(double, double) onLocationUpdate) {
    _positionStream?.cancel(); // Cancel previous stream if any

    try {
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            (Position position) {
              final lat = position.latitude;
              final lng = position.longitude;
              currentLocation.value = LatLng(lat, lng);
              onLocationUpdate(lat, lng); // Callback to update Firebase
            },
            onError: (error) {
              developer.log("❌ Stream error: $error");
              restartLocationStream(onLocationUpdate);
            },
            onDone: () {
              developer.log("⚠️ Stream closed. Restarting...");
              restartLocationStream(onLocationUpdate);
            },
          );
    } catch (e) {
      developer.log("Error starting location stream: $e");
      _positionStream?.cancel();
    }
  }

  void restartLocationStream(Function(double, double) onLocationUpdate) {
    _positionStream?.cancel();
    startLocationStream(onLocationUpdate);
  }

  /// ✅ Stop location tracking
  void stopLocationStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// ✅ One-time short method to get location
  Future<LatLng?> getCurrentLatLng(int driverID) async {
    isLoading.value = true;
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      currentLocation.value = LatLng(position.latitude, position.longitude);

      isLoading.value = false;
      isPermissionGranted.value = true;
      return currentLocation.value;
    } catch (e) {
      isLoading.value = false;
      debugPrint("Error getting current lat/lng: $e");
      return null;
    }
  }

  /// ✅ One-time short method to get location
  Future<void> fetchLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
      );
      currentLocation.value = LatLng(position.latitude, position.longitude);
    } catch (e) {
      developer.log("$e");
    }
  }

  void showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Location Permission"),
        content: const Text(
          "Permission permanently denied. Please open settings to allow location access.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Get.back();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}
