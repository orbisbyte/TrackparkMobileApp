import 'package:driver_tracking_airport/data/services/upload_progress/upload_manager_controller.dart';
import 'package:driver_tracking_airport/data/services/upload_progress/upload_task.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadsProgressSection extends StatelessWidget {
  const UploadsProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final uploadManager = Get.find<UploadManagerController>();

    return Obx(() {
      final tasks = uploadManager.tasks;
      if (tasks.isEmpty) return const SizedBox.shrink();

      return Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_upload, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Uploads',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // TextButton(
                  //   onPressed: uploadManager.clearCompleted,
                  //   child: const Text('Clear'),
                  // ),
                  Text(
                    "Don't Close the app while uploading.",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...tasks.take(6).map((t) => _UploadRow(task: t)),
              if (tasks.length > 6) ...[
                const SizedBox(height: 8),
                Text(
                  '+${tasks.length - 6} more uploads',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _UploadRow extends StatelessWidget {
  final UploadTask task;
  const _UploadRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = task.status.value;
      final progress = task.progress.value;
      final msg = task.message.value;

      Color color;
      IconData icon;
      switch (status) {
        case UploadStatus.queued:
          color = Colors.blueGrey;
          icon = Icons.schedule;
          break;
        case UploadStatus.uploading:
          color = Colors.blue;
          icon = Icons.cloud_upload;
          break;
        case UploadStatus.success:
          color = Colors.green;
          icon = Icons.check_circle;
          break;
        case UploadStatus.failed:
          color = Colors.red;
          icon = Icons.error;
          break;
        case UploadStatus.cancelled:
          color = Colors.orange;
          icon = Icons.cancel;
          break;
      }

      final title =
          'Job ${task.jobId} • ${task.eventType.toUpperCase()} • ${task.imagesCount} img, ${task.videosCount} vid';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status == UploadStatus.uploading
                      ? '${(progress * 100).floor()}%'
                      : status.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: status == UploadStatus.uploading ? progress : null,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            ),
            if (msg.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                msg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const Divider(height: 16),
          ],
        ),
      );
    });
  }
}
