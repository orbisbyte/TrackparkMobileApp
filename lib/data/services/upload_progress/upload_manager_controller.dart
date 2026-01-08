import 'dart:async';

import 'package:get/get.dart';

import 'pending_upload_record.dart';
import 'pending_upload_store.dart';
import 'upload_task.dart';

class UploadManagerController extends GetxService {
  final RxList<UploadTask> tasks = <UploadTask>[].obs;
  final PendingUploadStore _store = PendingUploadStore();

  // Prevent duplicate retries for the same record id.
  final Set<String> _active = <String>{};

  UploadTask createTask({
    required String jobId,
    required String eventType,
    required int imagesCount,
    required int videosCount,
    String? id,
  }) {
    final task = UploadTask(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      jobId: jobId,
      eventType: eventType,
      imagesCount: imagesCount,
      videosCount: videosCount,
    );
    tasks.insert(0, task);
    return task;
  }

  UploadTask? _find(String id) => tasks.firstWhereOrNull((t) => t.id == id);

  void setUploading(String id) {
    final t = _find(id);
    if (t == null) return;
    t.status.value = UploadStatus.uploading;
  }

  void updateProgress(String id, double progress, {String? message}) {
    final t = _find(id);
    if (t == null) return;
    t.status.value = UploadStatus.uploading;
    t.progress.value = progress.clamp(0.0, 1.0);
    if (message != null) t.message.value = message;
  }

  void markSuccess(String id) {
    final t = _find(id);
    if (t == null) return;
    t.status.value = UploadStatus.success;
    t.progress.value = 1.0;
    t.message.value = 'Uploaded';
    _autoRemoveLater(id);
  }

  void markFailed(String id, String message) {
    final t = _find(id);
    if (t == null) return;
    t.status.value = UploadStatus.failed;
    t.message.value = message;
    _autoRemoveLater(id);
  }

  void markCancelled(String id, {String message = 'Cancelled'}) {
    final t = _find(id);
    if (t == null) return;
    t.status.value = UploadStatus.cancelled;
    t.message.value = message;
    _autoRemoveLater(id);
  }

  void removeTask(String id) {
    tasks.removeWhere((t) => t.id == id);
  }

  void clearCompleted() {
    tasks.removeWhere(
      (t) =>
          t.status.value == UploadStatus.success ||
          t.status.value == UploadStatus.failed ||
          t.status.value == UploadStatus.cancelled,
    );
  }

  void _autoRemoveLater(String id) {
    // Keep completed results visible briefly so driver can see outcome.
    Timer(const Duration(seconds: 8), () => removeTask(id));
  }

  /// Called on app start / network regain to re-attempt uploads saved locally.
  ///
  /// The actual upload execution is done by MediaUploadIsolateService.
  /// This manager only loads and returns pending records and keeps task UI.
  Future<List<PendingUploadRecord>> loadPendingRecords() async {
    return await _store.loadAll();
  }

  bool isActive(String id) => _active.contains(id);

  void markActive(String id) => _active.add(id);
  void markInactive(String id) => _active.remove(id);

  PendingUploadStore get store => _store;

  // Retry orchestration is handled by UploadRetryService to avoid circular deps.
}
