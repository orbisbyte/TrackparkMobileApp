import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:intl/intl.dart';

import '../../../consts/app_tokens.dart';
import '../../services/networkConnectivity/network_checker.dart';
import '../client/api_client.dart';
import '../client/api_endpoints.dart';

class UpdateJobParametersRepository {
  final ApiClient _client = ApiClient();
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Update job parameters on backend.
  ///
  /// - Always sends: CompToken, DriverID, JobID
  /// - All other fields are OPTIONAL and are only included when non-null / non-empty.
  ///
  /// The optional [yardParkLat], [yardParkLng] and [yardParkSlotInfo] are not
  /// currently part of [JobModel], so they can be passed explicitly when needed.
  ///
  /// [vConditionFlag] should be "start" for pickup media or "end" for parking media.
  Future<void> updateJobParameters({
    required JobModel job,
    bool? isDamaged,
    bool? isScratched,
    bool? isDirty,
    String? vConditionFlag, // "start" or "end"
    String? vConditionNotes,
  }) async {
    if (isInternetConnected.value == false) {
      throw Exception("No internet connection");
    }

    // ----- Helper builders -----
    String? formatDateTime(DateTime? dt) {
      if (dt == null) return null;
      return _apiDateFormat.format(dt);
    }

    void addIfNotNull(Map<String, dynamic> map, String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      map[key] = value;
    }

    // ----- Required base fields -----
    final driverId = job.driverId;
    if (driverId == null || driverId.isEmpty) {
      throw Exception('DriverID is required to update job parameters');
    }

    final body = <String, dynamic>{
      'CompToken': Apptokens.companyToken,
      'DriverID': driverId,
      'JobID': job.jobId,
    };

    // Build v_condition object if any vehicle condition flags are provided
    if (isDamaged != null ||
        isScratched != null ||
        isDirty != null ||
        vConditionFlag != null) {
      final vCondition = <String, dynamic>{};

      // Convert boolean to "Y" or "N"
      if (isDamaged != null) {
        vCondition['damaged'] = isDamaged ? 'Y' : 'N';
      }
      if (isScratched != null) {
        vCondition['scratched'] = isScratched ? 'Y' : 'N';
      }
      if (isDirty != null) {
        vCondition['dirty'] = isDirty ? 'Y' : 'N';
      }
      if (vConditionFlag != null) {
        vCondition['flag'] = vConditionFlag; // "start" or "end"
      }
      if (vConditionNotes != null) {
        vCondition['condition_notes'] = vConditionNotes;
      }

      // Only add v_condition if it has at least one field
      if (vCondition.isNotEmpty) {
        body['v_condition'] = vCondition;
      }
    }

    // ----- Optional fields from JobModel (only added when present) -----
    addIfNotNull(body, 'JobStatus', job.jobStatus);
    addIfNotNull(body, 'JobStartedTime', formatDateTime(job.jobStartedTime));
    addIfNotNull(
      body,
      'JobCompletedTime',
      formatDateTime(job.jobCompletedTime),
    );
    addIfNotNull(body, 'JobAcceptedTime', formatDateTime(job.jobAcceptedTime));

    // Note: API field name is "ImagesInfoStartTim" (without final 'e')
    addIfNotNull(
      body,
      'ImagesInfoStartTime',
      formatDateTime(job.imagesInfoStartTime),
    );
    addIfNotNull(
      body,
      'ImagesInfoEndTime',
      formatDateTime(job.imagesInfoEndTime),
    );

    addIfNotNull(body, 'Valuables', job.valuables);

    addIfNotNull(
      body,
      'VehicleInfoStartTime',
      formatDateTime(job.vehicleInfoStartTime),
    );
    addIfNotNull(
      body,
      'VehicleInfoEndTime',
      formatDateTime(job.vehicleInfoEndTime),
    );

    addIfNotNull(
      body,
      'ConsentStartTime',
      formatDateTime(job.consentStartTime),
    );
    addIfNotNull(body, 'ConsentEndTime', formatDateTime(job.consentEndTime));

    // Optional yard parking info (explicit parameters)
    addIfNotNull(body, 'end_lat', job.endLat?.toString());
    addIfNotNull(body, 'end_lng', job.endLng?.toString());
    addIfNotNull(body, 'start_lat', job.startLat?.toString());
    addIfNotNull(body, 'start_lng', job.startLng?.toString());
    addIfNotNull(body, 'YardParkSlotInfo', job.yardParkSlotInfo);
    // Add vehicle object if present as a JSON map
    if (job.vehicle != null) {
      body['Make'] = job.vehicle?.make;
      body['Model'] = job.vehicle?.model;
      body['Colour'] = job.vehicle?.colour;
      body['RegNo'] = job.vehicle?.regNo;
    }

    try {
      log("body to update job parameters: $body");
      final response = await _client.post(
        path: ApiEndpoints.updateJobParameters,
        body: body,
      );

      // Parse response data - it comes as a string
      Map<String, dynamic> data;
      if (response.data is String) {
        data = jsonDecode(response.data as String) as Map<String, dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else {
        throw Exception("Invalid response format");
      }

      if (response.statusCode == 200) {
        // Check if API response is successful
        if ((data['Code'] == '200' || data['Code'] == 200)) {
          log("job parameters updated successfully");
          return;
        } else {
          // API returned error or no data
          final errorMessage =
              data['message'] ?? 'Failed to update job parameters';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error occurred');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
