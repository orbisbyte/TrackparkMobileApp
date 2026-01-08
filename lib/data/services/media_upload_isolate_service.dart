import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/consts/app_tokens.dart';
import 'package:driver_tracking_airport/data/remote/client/api_endpoints.dart';
import 'package:driver_tracking_airport/data/services/upload_progress/pending_upload_record.dart';
import 'package:driver_tracking_airport/data/services/upload_progress/upload_manager_controller.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:path/path.dart' as p;

/// Data class for passing upload parameters to isolate
class MediaUploadParams {
  final String driverId;
  final String jobId;
  final String eventType;
  final List<String>? imagePaths;
  final String? videoPath;
  final List<String>? videoPaths;
  final String? signatureImage;

  MediaUploadParams({
    required this.driverId,
    required this.jobId,
    required this.eventType,
    this.imagePaths,
    this.videoPath,
    this.videoPaths,
    this.signatureImage,
  });

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'jobId': jobId,
    'eventType': eventType,
    'imagePaths': imagePaths,
    'videoPath': videoPath,
    'videoPaths': videoPaths,
    'signatureImage': signatureImage,
  };

  factory MediaUploadParams.fromJson(Map<String, dynamic> json) =>
      MediaUploadParams(
        driverId: json['driverId'] as String,
        jobId: json['jobId'] as String,
        eventType: json['eventType'] as String,
        imagePaths: json['imagePaths'] as List<String>?,
        videoPath: json['videoPath'] as String?,
        videoPaths: (json['videoPaths'] as List?)?.cast<String>(),
        signatureImage: json['signatureImage'] as String?,
      );
}

/// Result class for upload operation
class MediaUploadResult {
  final bool success;
  final String? errorMessage;

  MediaUploadResult({required this.success, this.errorMessage});
}

/// Top-level function that runs in isolate
/// This function must be top-level (not a class method) to be spawnable in isolate.
///
/// Messages sent back to main isolate:
/// - {type:'progress', progress: double(0..1)}
/// - {type:'done', success: bool, errorMessage?: String}
void _uploadMediaIsolateEntry(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final paramsJson = args[1] as Map<String, dynamic>;
  final params = MediaUploadParams.fromJson(paramsJson);

  final result = await _performUpload(params, sendPort);
  sendPort.send({
    'type': 'done',
    'success': result.success,
    'errorMessage': result.errorMessage,
  });
}

Future<MediaUploadResult> _performUpload(
  MediaUploadParams params,
  SendPort sendPort,
) async {
  // Hard limits to ensure we never "hang forever" in the isolate.
  // - sendTimeout is critical for large uploads (otherwise Dio can wait indefinitely while sending).
  const connectTimeout = Duration(minutes: 2);
  const sendTimeout = Duration(minutes: 8);
  const receiveTimeout = Duration(minutes: 2);
  const overallTimeout = Duration(minutes: 10);

  final cancelToken = CancelToken();
  Timer? timeoutTimer;
  try {
    // Create Dio instance in isolate
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    // Validate required parameters
    if (params.driverId.trim().isEmpty) {
      return MediaUploadResult(
        success: false,
        errorMessage: "DriverID is required",
      );
    }
    if (params.jobId.trim().isEmpty) {
      return MediaUploadResult(
        success: false,
        errorMessage: "JobID is required",
      );
    }
    if (params.eventType.trim().isEmpty) {
      return MediaUploadResult(
        success: false,
        errorMessage: "EventType is required",
      );
    }

    // Build FormData with required fields
    final formData = FormData.fromMap({
      'CompToken': Apptokens.companyToken,
      'DriverID': params.driverId,
      'JobID': params.jobId,
      'EventType': params.eventType,
    });

    // Add images if provided
    if (params.imagePaths != null && params.imagePaths!.isNotEmpty) {
      for (var imagePath in params.imagePaths!) {
        if (imagePath.trim().isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists()) {
            formData.files.add(
              MapEntry(
                // IMPORTANT: use `images[]` so PHP/Yii2 builds an array of files
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
      ...?params.videoPaths?.where((e) => e.trim().isNotEmpty),
      if (params.videoPaths == null || params.videoPaths!.isEmpty)
        if (params.videoPath != null && params.videoPath!.trim().isNotEmpty)
          params.videoPath!,
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
    if (params.signatureImage != null &&
        params.signatureImage!.trim().isNotEmpty) {
      final file = File(params.signatureImage!);
      if (await file.exists()) {
        formData.files.add(
          MapEntry(
            'signature_image',
            await MultipartFile.fromFile(
              params.signatureImage!,
              filename: p.basename(file.path),
            ),
          ),
        );
      }
    }

    log(
      'Uploading media in isolate: JobID=${params.jobId}, EventType=${params.eventType}',
    );
    log(
      'Upload payload: images=${params.imagePaths?.length ?? 0}, videos=${normalizedVideoPaths.length}, signature=${params.signatureImage != null}',
    );

    // Ensure we always finish: if the upload exceeds [overallTimeout], cancel it.
    timeoutTimer = Timer(overallTimeout, () {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Upload timed out after $overallTimeout');
      }
    });

    // Make the upload request
    final response = await dio.post(
      ApiEndpoints.uploadMedia,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        if (total <= 0) return;
        final progress = sent / total;
        sendPort.send({'type': 'progress', 'progress': progress});
      },
    );

    // Parse response data
    Map<String, dynamic> data;
    if (response.data is String) {
      data = jsonDecode(response.data as String) as Map<String, dynamic>;
    } else if (response.data is Map<String, dynamic>) {
      data = response.data as Map<String, dynamic>;
    } else {
      return MediaUploadResult(
        success: false,
        errorMessage: "Invalid response format",
      );
    }

    if (response.statusCode == 200) {
      // Check if API response is successful
      if ((data['Code'] == '200' || data['Code'] == 200)) {
        log(
          'Media upload successful in isolate: ${data['message']?.toString() ?? 'Success'}',
        );
        return MediaUploadResult(success: true);
      } else {
        // API returned error
        final errorMessage = data['message'] ?? 'Failed to upload media';
        return MediaUploadResult(
          success: false,
          errorMessage: errorMessage.toString(),
        );
      }
    } else {
      return MediaUploadResult(
        success: false,
        errorMessage: "Server error: ${response.statusCode}",
      );
    }
  } on DioException catch (e) {
    String errorMessage = 'Network error occurred';
    if (CancelToken.isCancel(e)) {
      errorMessage = 'Upload cancelled: ${e.message ?? 'timeout or cancelled'}';
      log('Media upload cancelled in isolate: $errorMessage');
      return MediaUploadResult(success: false, errorMessage: errorMessage);
    }
    if (e.response != null) {
      try {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          errorMessage =
              errorData['message'] ??
              errorData['Message'] ??
              'Failed to upload media';
        }
      } catch (_) {
        errorMessage = e.message ?? 'Network error occurred';
      }
    } else {
      errorMessage = e.message ?? 'Network error occurred';
    }
    log('Media upload error in isolate: $errorMessage');
    return MediaUploadResult(success: false, errorMessage: errorMessage);
  } catch (e) {
    log('Media upload exception in isolate: $e');
    return MediaUploadResult(success: false, errorMessage: e.toString());
  } finally {
    timeoutTimer?.cancel();
  }
}

/// Service class for uploading media in background isolate
/// This provides a clean interface for all upload operations
class MediaUploadIsolateService {
  /// Upload media files in a separate isolate (non-blocking)
  ///
  /// This method runs the upload in a background isolate, preventing
  /// blocking of the main UI thread during large file uploads.
  ///
  /// Parameters:
  /// - [driverId]: Driver ID
  /// - [jobId]: Job ID
  /// - [eventType]: Event type ("start" or "end")
  /// - [imagePaths]: Optional list of image file paths
  /// - [videoPath]: Optional video file path (legacy)
  /// - [videoPaths]: Optional list of video file paths (preferred for multi-clip)
  /// - [signatureImage]: Optional signature image file path
  ///
  /// Returns a Future that completes when upload finishes (success or failure)
  /// The upload runs in background, so this won't block the UI.
  /// Network errors are handled gracefully in the isolate.
  Future<void> uploadMediaInBackground({
    String? taskId,
    required String driverId,
    required String jobId,
    required String eventType,
    List<String>? imagePaths,
    String? videoPath,
    List<String>? videoPaths,
    String? signatureImage,
    bool persistToQueue = true,
  }) async {
    try {
      final uploadManager = Get.find<UploadManagerController>();

      final normalizedVideos = <String>[
        ...?videoPaths?.where((e) => e.trim().isNotEmpty),
        if (videoPaths == null || videoPaths.isEmpty)
          if (videoPath != null && videoPath.trim().isNotEmpty) videoPath,
      ];

      final task = uploadManager.createTask(
        id: taskId,
        jobId: jobId,
        eventType: eventType,
        imagesCount: imagePaths?.length ?? 0,
        videosCount: normalizedVideos.length,
      );

      final params = MediaUploadParams(
        driverId: driverId,
        jobId: jobId,
        eventType: eventType,
        imagePaths: imagePaths,
        videoPath: videoPath,
        videoPaths: videoPaths,
        signatureImage: signatureImage,
      );

      uploadManager.setUploading(task.id);
      uploadManager.markActive(task.id);

      // Persist to queue so we can retry after app restart/offline.
      final record = PendingUploadRecord(
        id: task.id,
        driverId: driverId,
        jobId: jobId,
        eventType: eventType,
        imagePaths: imagePaths ?? const [],
        videoPaths: normalizedVideos,
        signatureImagePath: signatureImage,
        attempts: 0,
        lastError: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (persistToQueue) {
        final persisted = await uploadManager.store.persistFiles(record);
        await uploadManager.store.upsert(persisted);
      } else {
        // Retry path already persisted; keep metadata in sync.
        await uploadManager.store.upsert(record);
      }

      final receivePort = ReceivePort();
      Isolate? isolate;
      Timer? watchdog;

      // Safety net: if isolate doesn't finish, mark failed (and kill isolate).
      watchdog = Timer(const Duration(minutes: 11), () {
        isolate?.kill(priority: Isolate.immediate);
        uploadManager.markFailed(task.id, 'Upload timed out');
        receivePort.close();
      });

      isolate = await Isolate.spawn(_uploadMediaIsolateEntry, [
        receivePort.sendPort,
        params.toJson(),
      ], debugName: 'media_upload_${task.id}');

      StreamSubscription? sub;
      sub = receivePort.listen((message) async {
        if (message is Map) {
          final type = message['type'];
          if (type == 'progress') {
            final progress = (message['progress'] as num?)?.toDouble() ?? 0.0;
            uploadManager.updateProgress(
              task.id,
              progress,
              message: 'Uploading ${(progress * 100).floor()}%',
            );
          } else if (type == 'done') {
            watchdog?.cancel();
            final success = message['success'] == true;
            final err = message['errorMessage']?.toString();
            if (success) {
              uploadManager.markSuccess(task.id);
              log('Media upload completed successfully in background isolate');
              await uploadManager.store.remove(task.id);
              await uploadManager.store.deletePersistedFiles(task.id);
            } else {
              uploadManager.markFailed(task.id, err ?? 'Upload failed');
              log('Media upload failed in background: $err');
              // Update retry metadata (increment attempts + keep error)
              final records = await uploadManager.store.loadAll();
              final rec = records.firstWhereOrNull((r) => r.id == task.id);
              if (rec != null) {
                await uploadManager.store.upsert(
                  rec.copyWith(
                    attempts: rec.attempts + 1,
                    lastError: err ?? 'Network error occurred',
                    updatedAt: DateTime.now(),
                  ),
                );
              }
            }
            await sub?.cancel();
            receivePort.close();
            isolate?.kill(priority: Isolate.immediate);
            uploadManager.markInactive(task.id);
          }
        }
      });
    } catch (e) {
      log('Error spawning media upload isolate: $e');
      // Don't throw - this is a background operation
      // Isolate spawning errors are logged but don't block the main thread
    }
  }
}
