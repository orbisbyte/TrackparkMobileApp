import 'package:get/get.dart';

enum UploadStatus { queued, uploading, success, failed, cancelled }

class UploadTask {
  final String id;
  final String jobId;
  final String eventType; // start/end
  final int imagesCount;
  final int videosCount;

  /// 0.0 -> 1.0
  final RxDouble progress = 0.0.obs;
  final Rx<UploadStatus> status = UploadStatus.queued.obs;
  final RxString message = ''.obs;

  UploadTask({
    required this.id,
    required this.jobId,
    required this.eventType,
    required this.imagesCount,
    required this.videosCount,
  });
}


