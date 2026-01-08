import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/data/remote/client/api_endpoints.dart';
import 'package:driver_tracking_airport/models/job_model.dart';

import '../../../consts/app_tokens.dart';
import '../../services/networkConnectivity/network_checker.dart';
import '../client/api_client.dart';

class IncomingJobsRepository {
  final ApiClient _client = ApiClient();

  /// Fetch incoming jobs assigned to driver
  /// Returns List<JobModel> on success
  Future<List<JobModel>> getIncomingJobs({required String driverId}) async {
    if (isInternetConnected.value == false) {
      throw Exception("No internet connection");
    }

    final body = {"CompToken": Apptokens.companyToken, "DriverID": driverId};

    try {
      final response = await _client.post(
        path: ApiEndpoints.incomingJobs,
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
        if ((data['Code'] == '200' || data['Code'] == 200) &&
            data['data'] != null) {
          final dataList = data['data'];

          // Handle different data formats
          List<dynamic> jobsList;
          if (dataList is List) {
            jobsList = dataList;
          } else if (dataList is String && dataList.isNotEmpty) {
            // If data is a string, parse it
            jobsList = jsonDecode(dataList) as List<dynamic>;
          } else {
            return [];
          }

          // Convert each job to JobModel
          return jobsList
              .map(
                (jobJson) =>
                    JobModel.fromApiJson(jobJson as Map<String, dynamic>),
              )
              .toList();
        } else {
          // API returned error or no data
          final errorMessage = data['message'] ?? 'No jobs found';
          if (data['Code'] == '406' || errorMessage.contains('No Data')) {
            // No jobs available - return empty list instead of throwing
            return [];
          }
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
