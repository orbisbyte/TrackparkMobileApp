import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/consts/app_tokens.dart';
import 'package:driver_tracking_airport/data/remote/client/api_client.dart';
import 'package:driver_tracking_airport/data/remote/client/api_endpoints.dart';
import 'package:driver_tracking_airport/data/services/networkConnectivity/network_checker.dart';
import 'package:path/path.dart' as p;

class UploadMediaRepository {
  final ApiClient _client = ApiClient();

  /// Upload media files (images and/or video) to the server
  ///
  /// Required parameters:
  /// - [driverId]: Driver ID
  /// - [jobId]: Job ID
  /// - [eventType]: Event type (e.g., "start", "end")
  ///
  /// Optional parameters:
  /// - [imagePaths]: List of image file paths to upload (can be multiple)
  /// - [videoPath]: Single video file path to upload (legacy)
  /// - [videoPaths]: List of video file paths to upload (preferred for multi-clip)
  /// - [signatureImage]: Signature image file path to upload
  ///
  /// Returns void on success, throws Exception on failure
  Future<void> uploadMedia({
    required String driverId,
    required String jobId,
    required String eventType,
    List<String>? imagePaths,
    String? videoPath,
    List<String>? videoPaths,
    String? signatureImage,
  }) async {
    if (isInternetConnected.value == false) {
      throw Exception("No internet connection");
    }

    // Validate required parameters
    if (driverId.trim().isEmpty) {
      throw Exception("DriverID is required");
    }
    if (jobId.trim().isEmpty) {
      throw Exception("JobID is required");
    }
    if (eventType.trim().isEmpty) {
      throw Exception("EventType is required");
    }

    // Build FormData with required fields
    final formData = FormData.fromMap({
      'CompToken': Apptokens.companyToken,
      'DriverID': driverId,
      'JobID': jobId,
      'EventType': eventType,
    });

    // Add images if provided
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (var imagePath in imagePaths) {
        if (imagePath.trim().isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists()) {
            // IMPORTANT:
            // Send as `images[]` so PHP/Yii2 aggregates into an array in $_FILES / UploadedFile.
            // If you send repeated `images` keys (without []), PHP often keeps only the last file.
            formData.files.add(
              MapEntry(
                'images[]',
                await MultipartFile.fromFile(
                  imagePath,
                  filename: p.basename(file.path),
                ),
              ),
            );
          }
        }
      }
    }

    // Add videos (multi-clip supported)
    final normalizedVideoPaths = <String>[
      ...?videoPaths?.where((e) => e.trim().isNotEmpty),
      if (videoPaths == null || videoPaths.isEmpty)
        if (videoPath != null && videoPath.trim().isNotEmpty) videoPath,
    ];

    if (normalizedVideoPaths.isNotEmpty) {
      // Backward compatibility: also send the first clip as `video`
      final first = File(normalizedVideoPaths.first);
      if (await first.exists()) {
        formData.files.add(
          MapEntry(
            'video',
            await MultipartFile.fromFile(
              first.path,
              filename: p.basename(first.path),
            ),
          ),
        );
      }

      // Preferred: send all clips as array `video[]` (matches backend parsing)
      for (final vp in normalizedVideoPaths) {
        final vf = File(vp);
        if (await vf.exists()) {
          formData.files.add(
            MapEntry(
              'video[]',
              await MultipartFile.fromFile(
                vf.path,
                filename: p.basename(vf.path),
              ),
            ),
          );
        }
      }
    }

    // Add signature image if provided
    if (signatureImage != null && signatureImage.trim().isNotEmpty) {
      final file = File(signatureImage);
      if (await file.exists()) {
        formData.files.add(
          MapEntry(
            'signature_image',
            await MultipartFile.fromFile(
              signatureImage,
              filename: p.basename(file.path),
            ),
          ),
        );
      }
    }
    log('formData: ${formData.fields}');

    try {
      final response = await _client.postForm(
        path: ApiEndpoints.uploadMedia,
        data: formData,
      );

      // Parse response data - it comes as a string or Map
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
          log('success: ${response.data['message'].toString()}');
          return;
        } else {
          // API returned error
          final errorMessage = data['message'] ?? 'Failed to upload media';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Try to parse error response
        try {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            final errorMessage =
                errorData['message'] ??
                errorData['Message'] ??
                'Failed to upload media';
            throw Exception(errorMessage);
          }
        } catch (_) {}
      }
      throw Exception(e.message ?? 'Network error occurred');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
