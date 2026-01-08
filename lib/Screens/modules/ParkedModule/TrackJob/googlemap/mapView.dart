import 'package:driver_tracking_airport/COntrollers/location_controller.dart';
import 'package:driver_tracking_airport/Screens/modules/ParkedModule/TrackJob/googlemap/googlrmap_controller.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:driver_tracking_airport/utils/message_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class JobMapWidget extends StatefulWidget {
  final JobModel job;

  const JobMapWidget({super.key, required this.job});

  @override
  State<JobMapWidget> createState() => _JobMapWidgetState();
}

class _JobMapWidgetState extends State<JobMapWidget> {
  var locationController = Get.find<LocationController>();
  var mapController = Get.put(MapController());

  /// Get target location based on job status
  /// Returns start_lat/lng for 'ontheway', end_lat/lng for 'started'
  LatLng? _getTargetLocation() {
    final status = widget.job.jobStatus?.toLowerCase();

    if (status == 'ontheway') {
      // For pickup - use start_lat/lng
      if (widget.job.startLat != null && widget.job.startLng != null) {
        return LatLng(widget.job.startLat!, widget.job.startLng!);
      }
    } else if (status == 'started') {
      // For parking/delivery - use end_lat/lng
      if (widget.job.endLat != null && widget.job.endLng != null) {
        return LatLng(widget.job.endLat!, widget.job.endLng!);
      }
    }

    return null;
  }

  /// Get marker title based on job type and status
  String _getMarkerTitle() {
    final status = widget.job.jobStatus?.toLowerCase();
    final isDeliveryJob = widget.job.isDeliveryJob;

    if (status == 'ontheway') {
      return 'Pickup Location';
    } else if (status == 'started') {
      return isDeliveryJob ? 'Delivery Location' : 'Parking Location';
    }
    return 'Destination';
  }

  Future<void> _launchGoogleMapsNavigation() async {
    final targetLocation = _getTargetLocation();
    if (targetLocation == null) {
      MessageHelper.showError('Destination location not available');
      return;
    }

    final currentLocation = locationController.currentLocation.value;
    if (currentLocation == null) {
      MessageHelper.showError('Current location not available');
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${currentLocation.latitude},${currentLocation.longitude}'
      '&destination=${targetLocation.latitude},${targetLocation.longitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      MessageHelper.showError('Failed to launch Google Maps');
    }
  }

  @override
  void initState() {
    super.initState();
    mapController.loadCarMarker();
    // Don't call drawRouteToTerminal or adjustCameraToBounds here
    // ever(
    //   locationController.currentLocation,
    //   (_) => mapController.adjustCameraToBounds(),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          if (locationController.currentLocation.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  locationController.currentLocation.value ??
                  const LatLng(0, 0),
              zoom: mapController.optimalZoom.value,
            ),
            // In your GoogleMap widget:
            onMapCreated: (googleMapController) async {
              if (!mapController.mapController.isCompleted) {
                mapController.mapController.complete(googleMapController);
              }

              // Get target location based on job status
              final targetLocation = _getTargetLocation();
              if (targetLocation != null) {
                // Draw route to target location (start_lat/lng or end_lat/lng)
                await mapController.drawRouteToTerminal(
                  targetLocation.latitude,
                  targetLocation.longitude,
                );
                await mapController.adjustCameraToBounds();
              }
            },
            markers: {
              if (locationController.currentLocation.value != null)
                mapController.currentLocationMarker(
                  locationController.currentLocation.value!,
                ),
              // Show target marker (pickup, parking, or delivery location)
              if (_getTargetLocation() != null) ...[
                mapController.terminalMarker(
                  _getTargetLocation()!,
                  title: _getMarkerTitle(),
                ),
              ],
            },
            polylines: {
              if (mapController.routePoints.isNotEmpty)
                mapController.routePolyline(),
            },
          );
        }),
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton.extended(
            onPressed: _launchGoogleMapsNavigation,
            backgroundColor: Colors.blue,
            label: Row(
              spacing: 5,
              children: [
                const Icon(Icons.directions, color: Colors.white),
                Text("Navigate", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
