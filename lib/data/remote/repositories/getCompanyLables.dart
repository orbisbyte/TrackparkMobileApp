import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/data/remote/client/api_endpoints.dart';
import 'package:driver_tracking_airport/data/services/networkConnectivity/network_checker.dart';

import '../../../consts/app_tokens.dart';
import '../client/api_client.dart';

class GetCompanyLabelsRepository {
  final ApiClient _client = ApiClient();

  /// Fetch company labels from API
  /// Returns Map<String, String> with job type keys and their labels
  Future<Map<String, String>> getCompanyLabels() async {
    if (isInternetConnected.value == false) {
      throw Exception("No internet connection");
    }

    final body = {"CompToken": Apptokens.companyToken};

    try {
      final response = await _client.post(
        path: ApiEndpoints.companyLabels,
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
          final labelsData = data['data'] as Map<String, dynamic>;

          // Convert to Map<String, String>
          final labels = <String, String>{};
          labelsData.forEach((key, value) {
            labels[key] = value.toString();
          });

          return labels;
        } else {
          final errorMessage = data['message'] ?? 'Failed to fetch labels';
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
