import 'dart:async';
import 'dart:developer';

import 'package:driver_tracking_airport/COntrollers/location_controller.dart';
import 'package:driver_tracking_airport/consts/app_Consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapController extends GetxController {
  final LocationController locationController = Get.find();
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final Completer<GoogleMapController> mapController = Completer();
  final Rx<LatLngBounds?> routeBounds = Rx<LatLngBounds?>(null);
  final RxDouble optimalZoom = 15.0.obs;
  final PolylinePoints polylinePoints = PolylinePoints();
  Rxn<BitmapDescriptor> carIcon = Rxn<BitmapDescriptor>();

  Future<void> loadCarMarker() async {
    carIcon.value = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(45, 45)),
      "assets/carIcon.png",
    );
  }

  Future<void> drawRouteToTerminal(
    double? terminalLat,
    double? terminalLng,
  ) async {
    if (terminalLat == null || terminalLng == null) return;

    final currentLocation = locationController.currentLocation.value;
    if (currentLocation == null) return;

    final destination = LatLng(terminalLat, terminalLng);

    // ✅ Get real route from Google Directions API
    final points = await _getRouteDirections(currentLocation, destination);
    if (points.isNotEmpty) {
      routePoints.assignAll(points);

      // ✅ Set bounds based on real route
      _calculateRouteBoundsFromList(points);
      await adjustCameraToBounds();
    }
  }

  Future<List<LatLng>> _getRouteDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: mapKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isEmpty) throw Exception("No points returned");

      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } catch (e) {
      debugPrint('Error fetching route: $e');
      return [origin, destination]; // fallback
    }
  }

  void _calculateRouteBoundsFromList(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    routeBounds.value = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // filepath: d:\Flutter Projects\driver_tracking_airport\lib\Screens\trrackJob\googlemap\googlrmap_controller.dart
  Future<void> adjustCameraToBounds() async {
    final bounds = routeBounds.value;
    if (bounds == null) return;

    try {
      final controller = await mapController.future;
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (e) {
      log('Error adjusting camera: $e');
      // Retry after a short delay if the error is a channel error
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final controller = await mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } catch (e) {
        log('Retry failed: $e');
      }
    }
  }

  Polyline routePolyline() {
    return Polyline(
      polylineId: const PolylineId('route'),
      points: routePoints,
      color: Colors.blue.shade600,
      width: 5,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  Future<void> updateCameraIfNeeded() async {
    if (routePoints.isEmpty) return;

    final currentLocation = locationController.currentLocation.value;
    if (currentLocation == null) return;

    final controller = await mapController.future;
    await controller.animateCamera(CameraUpdate.newLatLng(currentLocation));
  }

  // Add marker for terminal/pickup/parking location
  Marker terminalMarker(LatLng position, {String? title}) {
    return Marker(
      markerId: const MarkerId('destination'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: title ?? 'Destination'),
    );
  }

  // Add marker for current location
  Marker currentLocationMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('current_location'),
      position: position,
      icon:
          carIcon.value ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Your Location'),
    );
  }
}
