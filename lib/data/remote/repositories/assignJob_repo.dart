import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../consts/app_tokens.dart';
import '../../services/networkConnectivity/network_checker.dart';
import '../client/api_client.dart';
import '../client/api_endpoints.dart';

class AssignJobRepository {
  final ApiClient _client = ApiClient();

  /// Assign job API call (for Shift/Return operations)
  /// Returns response with status code and message
  Future<Map<String, dynamic>> assignJob({
    required String driverId,
    required String jobId,
    required String operationType, // "Shift" or "Return"
    required String vehicleNo,
  }) async {
    if (isInternetConnected.value == false) {
      throw Exception("No internet connection");
    }

    final body = {
      "CompToken": Apptokens.companyToken,
      "DriverID": driverId,
      "JobID": jobId,
      "OperationType": operationType,
      "vehicleno": vehicleNo,
    };

    try {
      log("Assign job request body: $body");
      final response = await _client.post(
        path: ApiEndpoints.assignJob,
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
        log("Assign job response: $data");
        return data;
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

