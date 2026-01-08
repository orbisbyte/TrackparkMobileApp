import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/data/remote/client/api_endpoints.dart';
import 'package:driver_tracking_airport/models/driver_model.dart';

import '../../../consts/app_tokens.dart';
import '../../services/networkConnectivity/network_checker.dart';
import '../client/api_client.dart';

class DriverLoginRepository {
  final ApiClient _client = ApiClient();

  /// Driver login API call
  /// Returns DriverModel on success
  Future<DriverModel> driverLogin({
    required String username,
    required String password,
    required String fcmToken,
    required String latitude,
    required String longitude,
  }) async {
    if (isInternetConnected.value == false) {
      throw Exception("No internet connection");
    }

    final body = {
      "CompToken": Apptokens.companyToken,
      "user": username,
      "pass": password,
      "fcm": fcmToken,
      "lat": latitude,
      "lng": longitude,
    };

    try {
      final response = await _client.post(
        path: ApiEndpoints.driverLogin,
        body: body,
      );

      // Parse response data - it comes as a string
      Map<String, dynamic> data;
      if (response.data is String) {
        // If response is a string, parse it first
        data = jsonDecode(response.data as String) as Map<String, dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        // If already parsed, use it directly
        data = response.data as Map<String, dynamic>;
      } else {
        throw Exception("Invalid response format");
      }

      if (response.statusCode == 200) {
        // Check if API response is successful
        if (data['Code'] == '200' &&
            data['data'] != null &&
            data['data'] != '') {
          // Parse and return DriverModel
          final dataMap = data['data'];
          if (dataMap is Map<String, dynamic>) {
            return DriverModel.fromJson(dataMap);
          } else if (dataMap is String && dataMap.isNotEmpty) {
            // If data is also a string, parse it
            final parsedData = jsonDecode(dataMap) as Map<String, dynamic>;
            return DriverModel.fromJson(parsedData);
          } else {
            throw Exception("Invalid data format in response");
          }
        } else {
          // API returned error
          final errorMessage = data['message'] ?? 'Login failed';
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
