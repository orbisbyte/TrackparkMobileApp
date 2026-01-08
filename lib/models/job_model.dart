import 'package:cloud_firestore/cloud_firestore.dart';

/// Vehicle information nested model
class VehicleInfo {
  final String? make;
  final String? model;
  final String? colour;
  final String? regNo;

  VehicleInfo({this.make, this.model, this.colour, this.regNo});

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      make: json['Make'] ?? json['make'],
      model: json['Model'] ?? json['model'],
      colour:
          json['Colour'] ?? json['Colour'] ?? json['color'] ?? json['colour'],
      regNo: json['RegNo'] ?? json['regNo'] ?? json['plate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'Make': make, 'Model': model, 'Colour': colour, 'RegNo': regNo};
  }

  VehicleInfo copyWith({
    String? make,
    String? model,
    String? colour,
    String? regNo,
  }) {
    return VehicleInfo(
      make: make ?? this.make,
      model: model ?? this.model,
      colour: colour ?? this.colour,
      regNo: regNo ?? this.regNo,
    );
  }
}

/// Unified Job Model - Combines API and Local DB models
class JobModel {
  // ============ API Fields ============
  final String jobId; // JobID from API
  final String? jobType; // "PARK" or "DELIVERY"
  final String? jobStatus; // "pending", "ontheway", "started", "parked"
  final String? bookingRef; // BookingRef from API
  final String? customerName; // CustomerName from API
  final String? airportId; // AirportID from API
  final String? terminalId; // TerminalID from API
  final String? terminalName; // ShiftID from API
  final String? flightNo; // FlightNo from API
  final DateTime? dateTime; // DateTime from API
  final VehicleInfo? vehicle; // Vehicle object from API
  final String? fromYardId; // FromYardID from API
  final String? fromYardName; // FromYardName from API
  final String? toYardId; // ParkingYardID from API
  final String? toYardName; // YardName from API
  final String? notes; // Notes from API

  // ============ Driver/App Fields ============
  final String? driverId; // Driver who is handling the job

  // ============ Job Timestamps ============
  final DateTime? jobCreatedTime; // When job was created
  final DateTime? jobAcceptedTime; // When driver accepted the job
  final DateTime? jobStartedTime; // When driver started the job
  final DateTime? jobCompletedTime; // When job was parked

  // ============ Form Step Timestamps ============
  final DateTime? vehicleInfoStartTime;
  final DateTime? vehicleInfoEndTime;
  final DateTime? imagesInfoStartTime;
  final DateTime? imagesInfoEndTime;
  final DateTime? consentStartTime;
  final DateTime? consentEndTime;

  // ============ Additional Data (Parking jobs) ============
  // Media captured at pickup (when driver receives the car)
  final List<String> pickupImages; // Image paths or URLs (pickup time)
  final String? pickupVideo; // Video path or URL (pickup time)

  // Media captured at parking completion (for security)
  final List<String> yardParkImages; // Image paths or URLs (parking time)
  final String? yardParkVideo; // Video path or URL (parking time)

  final String? valuables; // Valuables description
  final String? signature; // Digital signatu re

  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? yardParkSlotInfo;

  // Driver behavior tracking - list of behavior events
  final List<Map<String, dynamic>> driverBehaviour;

  JobModel({
    required this.jobId,
    this.jobType,
    this.jobStatus,
    this.bookingRef,
    this.customerName,
    this.airportId,
    this.terminalId,
    this.flightNo,
    this.dateTime,
    this.vehicle,
    this.fromYardId,
    this.fromYardName,
    this.toYardId,
    this.toYardName,
    this.notes,
    this.driverId,
    this.terminalName,
    this.jobCreatedTime,
    this.jobAcceptedTime,
    this.jobStartedTime,
    this.jobCompletedTime,
    this.vehicleInfoStartTime,
    this.vehicleInfoEndTime,
    this.imagesInfoStartTime,
    this.imagesInfoEndTime,
    this.consentStartTime,
    this.consentEndTime,

    List<String>? pickupImages,
    this.pickupVideo,
    List<String>? yardParkImages,
    this.yardParkVideo,
    this.valuables,
    this.signature,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.yardParkSlotInfo,
    List<Map<String, dynamic>>? driverBehaviour,
  }) : pickupImages = pickupImages ?? [],
       yardParkImages = yardParkImages ?? [],
       driverBehaviour = driverBehaviour ?? [];

  // ============ Helper Methods for Conversion ============
  /// Convert string to double, handles null and invalid values
  static double? _parseStringToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  // ============ From API JSON ============
  factory JobModel.fromApiJson(Map<String, dynamic> json) {
    return JobModel(
      jobId: json['JobID']?.toString() ?? '',
      jobType: json['JobType'] ?? '',
      jobStatus: json['JobStatus'] ?? '',
      bookingRef: json['BookingRef'],
      customerName: json['CustomerName'],
      airportId: json['AirportID']?.toString(),
      terminalId: json['TerminalID']?.toString(),
      flightNo: json['FlightNo'],
      dateTime: json['DateTime'] != null
          ? DateTime.tryParse(json['DateTime'])
          : null,
      vehicle: json['Vehicle'] != null
          ? VehicleInfo.fromJson(json['Vehicle'] as Map<String, dynamic>)
          : null,
      fromYardId: json['FromYardId']?.toString(),
      fromYardName: json['FromYardName'],
      toYardId: json['ToYardId']?.toString(),
      toYardName: json['ToYardName'],
      notes: json['Notes'],

      terminalName: json['TerminalName'],

      startLat: JobModel._parseStringToDouble(json['start_lat']),
      startLng: JobModel._parseStringToDouble(json['start_lng']),
      endLat: JobModel._parseStringToDouble(json['end_lat']),
      endLng: JobModel._parseStringToDouble(json['end_lng']),
      driverBehaviour: json['driverBehaviour'] != null
          ? List<Map<String, dynamic>>.from(json['driverBehaviour'])
          : [],
    );
  }

  // ============ To API JSON ============
  Map<String, dynamic> toApiJson() {
    return {
      'JobID': jobId,
      'JobType': jobType,
      'JobStatus': jobStatus,
      'BookingRef': bookingRef,
      'CustomerName': customerName,
      'AirportID': airportId,
      'TerminalID': terminalId,
      'FlightNo': flightNo,
      'DateTime': dateTime?.toIso8601String(),
      'Vehicle': vehicle?.toJson(),
      'FromYardId': fromYardId,
      'FromYardName': fromYardName,
      'ToYardId': toYardId,
      'Notes': notes,
      // Additional fields that might be needed
      'DriverID': driverId,
      'TerminalName': terminalName,
      'ToYardName': toYardName,
      'JobStartedTime': jobStartedTime?.toIso8601String(),
      'JobCompletedTime': jobCompletedTime?.toIso8601String(),
      'JobAcceptedTime': jobAcceptedTime?.toIso8601String(),
      'VehicleInfoStartTime': vehicleInfoStartTime?.toIso8601String(),
      'VehicleInfoEndTime': vehicleInfoEndTime?.toIso8601String(),
      'ImagesInfoStartTime': imagesInfoStartTime?.toIso8601String(),
      'ImagesInfoEndTime': imagesInfoEndTime?.toIso8601String(),
      'ConsentStartTime': consentStartTime?.toIso8601String(),
      'ConsentEndTime': consentEndTime?.toIso8601String(),
      'Signature': signature,
      'Valuables': valuables,
      // For API we continue to map pickup media to legacy keys
      'PickupImages': pickupImages,
      'PickupVideo': pickupVideo,
      'YardParkImages': yardParkImages,
      'YardParkVideo': yardParkVideo,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'YardParkSlotInfo': yardParkSlotInfo,
      'driverBehaviour': driverBehaviour,
    };
  }

  // ============ To Firestore Map ============
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'jobType': jobType,
      'jobStatus': jobStatus,
      'bookingRef': bookingRef,
      'customerName': customerName,
      'airportId': airportId,
      'terminalId': terminalId,
      'flightNo': flightNo,
      'dateTime': dateTime?.toIso8601String(),
      'vehicle': vehicle?.toJson(),
      'FromYardId': fromYardId,
      'FromYardName': fromYardName,
      'ToYardId': toYardId,
      'notes': notes,
      'driverId': driverId,
      'terminalName': terminalName,
      'ToYardName': toYardName,
      'jobCreatedTime': jobCreatedTime?.toIso8601String(),
      'jobStartedTime': jobStartedTime?.toIso8601String(),
      'jobAcceptedTime': jobAcceptedTime?.toIso8601String(),
      'jobCompletedTime': jobCompletedTime?.toIso8601String(),
      'vehicleInfoStartTime': vehicleInfoStartTime?.toIso8601String(),
      'vehicleInfoEndTime': vehicleInfoEndTime?.toIso8601String(),
      'imagesInfoStartTime': imagesInfoStartTime?.toIso8601String(),
      'imagesInfoEndTime': imagesInfoEndTime?.toIso8601String(),
      'consentStartTime': consentStartTime?.toIso8601String(),
      'consentEndTime': consentEndTime?.toIso8601String(),

      // Pickup media (existing fields)
      'PickupImages': pickupImages,
      'PickupVideo': pickupVideo,

      // Parking completion media (new fields)
      'YardParkImages': yardParkImages,
      'YardParkVideo': yardParkVideo,
      'valuables': valuables,
      'signature': signature,
      'updatedAt': DateTime.now().toIso8601String(),
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'YardParkSlotInfo': yardParkSlotInfo,
      'driverBehaviour': driverBehaviour,
    };
  }

  // ============ From Firestore ============
  factory JobModel.fromFirestore(Map<String, dynamic> map) {
    // Helper function to convert Firestore Timestamp or String to DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return JobModel(
      jobId: map['jobId'] ?? '',
      jobType: map['jobType'] ?? '',
      jobStatus: map['jobStatus'] ?? '',
      bookingRef: map['bookingRef'],
      customerName: map['customerName'],
      airportId: map['airportId'],
      terminalId: map['terminalId'],
      flightNo: map['flightNo'],
      dateTime: parseDateTime(map['dateTime']),
      vehicle: map['vehicle'] != null
          ? VehicleInfo.fromJson(map['vehicle'] as Map<String, dynamic>)
          : null,
      fromYardId: map['FromYardId'],
      fromYardName: map['FromYardName'],
      toYardId: map['ToYardId'],
      notes: map['notes'],
      driverId: map['driverId'] ?? '',
      terminalName: map['terminalName'],
      toYardName: map['ToYardName'],
      jobCreatedTime: parseDateTime(map['jobCreatedTime']) ?? DateTime.now(),
      jobStartedTime: parseDateTime(map['jobStartedTime']),
      jobAcceptedTime: parseDateTime(map['jobAcceptedTime']),
      jobCompletedTime: parseDateTime(map['jobCompletedTime']),
      vehicleInfoStartTime: parseDateTime(map['vehicleInfoStartTime']),
      vehicleInfoEndTime: parseDateTime(map['vehicleInfoEndTime']),
      imagesInfoStartTime: parseDateTime(map['imagesInfoStartTime']),
      imagesInfoEndTime: parseDateTime(map['imagesInfoEndTime']),
      consentStartTime: parseDateTime(map['consentStartTime']),
      consentEndTime: parseDateTime(map['consentEndTime']),

      // Pickup media from legacy fields
      pickupImages: map['images'] != null
          ? List<String>.from(map['images'])
          : [],
      pickupVideo: map['video'],

      // Parking media from new fields (might be absent on older docs)
      yardParkImages: map['YardParkImages'] != null
          ? List<String>.from(map['YardParkImages'])
          : [],
      yardParkVideo: map['YardParkVideo'],
      valuables: map['valuables'],
      signature: map['signature'],
      startLat: JobModel._parseStringToDouble(map['start_lat']),
      startLng: JobModel._parseStringToDouble(map['start_lng']),
      endLat: JobModel._parseStringToDouble(map['end_lat']),
      endLng: JobModel._parseStringToDouble(map['end_lng']),
      yardParkSlotInfo: map['YardParkSlotInfo'],
      driverBehaviour: map['driverBehaviour'] != null
          ? List<Map<String, dynamic>>.from(map['driverBehaviour'])
          : [],
    );
  }

  // ============ Copy With ============
  JobModel copyWith({
    String? jobId,
    String? jobType,
    String? jobStatus,
    String? bookingRef,
    String? customerName,
    String? airportId,
    String? terminalId,
    String? flightNo,
    DateTime? dateTime,
    VehicleInfo? vehicle,
    String? fromYardId,
    String? fromYardName,
    String? toYardId,
    String? notes,
    String? driverId,
    String? terminalName,
    String? toYardName,
    DateTime? jobCreatedTime,
    DateTime? jobStartedTime,
    DateTime? jobAcceptedTime,
    DateTime? jobCompletedTime,
    DateTime? vehicleInfoStartTime,
    DateTime? vehicleInfoEndTime,
    DateTime? imagesInfoStartTime,
    DateTime? imagesInfoEndTime,
    DateTime? consentStartTime,
    DateTime? consentEndTime,

    List<String>? pickupImages,
    String? pickupVideo,
    List<String>? yardParkImages,
    String? yardParkVideo,
    String? valuables,
    String? signature,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    String? yardParkSlotInfo,
    List<Map<String, dynamic>>? driverBehaviour,
  }) {
    return JobModel(
      jobId: jobId ?? this.jobId,
      jobType: jobType ?? this.jobType,
      jobStatus: jobStatus ?? this.jobStatus,
      bookingRef: bookingRef ?? this.bookingRef,
      customerName: customerName ?? this.customerName,
      airportId: airportId ?? this.airportId,
      terminalId: terminalId ?? this.terminalId,
      flightNo: flightNo ?? this.flightNo,
      dateTime: dateTime ?? this.dateTime,
      vehicle: vehicle ?? this.vehicle,
      fromYardId: fromYardId ?? this.fromYardId,
      fromYardName: fromYardName ?? this.fromYardName,
      toYardId: toYardId ?? this.toYardId,
      notes: notes ?? this.notes,
      driverId: driverId ?? this.driverId,
      terminalName: terminalName ?? this.terminalName,
      toYardName: toYardName ?? this.toYardName,
      jobCreatedTime: jobCreatedTime ?? this.jobCreatedTime,
      jobStartedTime: jobStartedTime ?? this.jobStartedTime,
      jobAcceptedTime: jobAcceptedTime ?? this.jobAcceptedTime,
      jobCompletedTime: jobCompletedTime ?? this.jobCompletedTime,
      vehicleInfoStartTime: vehicleInfoStartTime ?? this.vehicleInfoStartTime,
      vehicleInfoEndTime: vehicleInfoEndTime ?? this.vehicleInfoEndTime,
      imagesInfoStartTime: imagesInfoStartTime ?? this.imagesInfoStartTime,
      imagesInfoEndTime: imagesInfoEndTime ?? this.imagesInfoEndTime,
      consentStartTime: consentStartTime ?? this.consentStartTime,
      consentEndTime: consentEndTime ?? this.consentEndTime,

      pickupImages: pickupImages ?? this.pickupImages,
      pickupVideo: pickupVideo ?? this.pickupVideo,
      yardParkImages: yardParkImages ?? this.yardParkImages,
      yardParkVideo: yardParkVideo ?? this.yardParkVideo,
      valuables: valuables ?? this.valuables,
      signature: signature ?? this.signature,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      yardParkSlotInfo: yardParkSlotInfo ?? this.yardParkSlotInfo,
      driverBehaviour: driverBehaviour ?? this.driverBehaviour,
    );
  }

  // ============ Helper Methods ============
  /// Check if job is parking type
  bool get isParkingJob => jobType?.toUpperCase() == 'RECEIVE';

  /// Check if job is delivery type
  bool get isDeliveryJob => jobType?.toUpperCase() == 'RETURN';

  /// Check if job is shift type
  bool get isShiftJob => jobType?.toUpperCase() == 'SHIFT';

  /// Get vehicle plate number (from vehicle object or direct field)
  String? get vehiclePlate => vehicle?.regNo;

  /// Get vehicle make (from vehicle object or direct field)
  String? get vehicleMake => vehicle?.make;

  /// Get vehicle color (from vehicle object or direct field)
  String? get vehicleColor => vehicle?.colour;
}
