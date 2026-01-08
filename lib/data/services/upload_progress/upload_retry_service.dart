import 'dart:async';

import 'package:get/get.dart';

import '../media_upload_isolate_service.dart';
import '../networkConnectivity/network_checker.dart';
import 'pending_upload_record.dart';
import 'upload_manager_controller.dart';
import 'upload_task.dart';

/// Orchestrates persistence + retry of uploads across app restarts/network drops.
///
/// - Loads pending records on startup and shows them in UI as queued/failed.
/// - When online, retries pending uploads (max attempts).
class UploadRetryService extends GetxService {
  static const int maxAttempts = 5;

  final UploadManagerController _manager = Get.find<UploadManagerController>();
  final MediaUploadIsolateService _uploader = MediaUploadIsolateService();

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();

    // Boot: load any pending uploads and show them on dashboard.
    Future.microtask(() async {
      await loadIntoUi();
      if (isInternetConnected.value) {
        retryNow();
      }
    });

    // Retry when we come back online (debounced to avoid rapid reconnect churn).
    ever(isInternetConnected, (bool online) {
      if (!online) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), retryNow);
    });
  }

  Future<void> loadIntoUi() async {
    final records = await _manager.loadPendingRecords();
    for (final r in records) {
      // If task already exists in UI, skip.
      if (_manager.tasks.any((t) => t.id == r.id)) continue;

      final task = _manager.createTask(
        id: r.id,
        jobId: r.jobId,
        eventType: r.eventType,
        imagesCount: r.imagePaths.length,
        videosCount: r.videoPaths.length,
      );

      if (r.lastError != null && r.lastError!.trim().isNotEmpty) {
        task.status.value = UploadStatus.failed;
        task.message.value = r.lastError!;
      } else {
        task.status.value = UploadStatus.queued;
        task.message.value = 'Pending';
      }
    }
  }

  Future<void> retryNow() async {
    final records = await _manager.loadPendingRecords();
    for (final r in records) {
      if (_manager.isActive(r.id)) continue;
      if (r.attempts >= maxAttempts) {
        _manager.markFailed(r.id, 'Max retry attempts reached');
        continue;
      }
      await _retryOne(r);
      // Allow multiple concurrent uploads: do not await serially too strictly.
      // But also avoid launching unlimited isolates. Here: small stagger.
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _retryOne(PendingUploadRecord r) async {
    _manager.markActive(r.id);
    _manager.updateProgress(r.id, 0.0, message: 'Retrying...');

    try {
      await _uploader.uploadMediaInBackground(
        taskId: r.id,
        driverId: r.driverId,
        jobId: r.jobId,
        eventType: r.eventType,
        imagePaths: r.imagePaths,
        videoPaths: r.videoPaths,
        signatureImage: r.signatureImagePath,
        persistToQueue: false, // already persisted
      );
    } finally {
      // markInactive is handled in uploader when done; keep a safeguard:
      Timer(const Duration(minutes: 12), () => _manager.markInactive(r.id));
    }
  }
}
