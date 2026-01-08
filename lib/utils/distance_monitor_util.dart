import 'dart:developer';

import 'package:geolocator/geolocator.dart';

/// Utility class for monitoring distance between two locations
class DistanceMonitorUtil {
  /// Calculate distance between two coordinates in meters
  /// Returns null if either location is null
  static double? calculateDistanceInMeters({
    required double? lat1,
    required double? lng1,
    required double? lat2,
    required double? lng2,
  }) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }

    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Check if current location is within specified radius (in meters) of target location
  /// Returns true if within radius, false otherwise, null if locations are invalid
  static bool? isWithinRadius({
    required double? currentLat,
    required double? currentLng,
    required double? targetLat,
    required double? targetLng,
    required double radiusInMeters,
  }) {
    final distance = calculateDistanceInMeters(
      lat1: currentLat,
      lng1: currentLng,
      lat2: targetLat,
      lng2: targetLng,
    );

    if (distance == null) return null;
    log("distance: $distance");
    return distance <= radiusInMeters;
  }

  /// Format distance in meters to readable string
  static String formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return 'Unknown';

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }
}
