import 'dart:io';

import 'package:driver_tracking_airport/models/vehicle_video_slot.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// A 5-slot vehicle video capture UI:
/// - Front/Left/Back/Right: required, max 1 minute
/// - Other: optional, no limit
class VehicleVideoSlotsSection extends StatelessWidget {
  final RxMap<VehicleVideoSlot, XFile?> videos;
  final Future<void> Function(VehicleVideoSlot slot) onCapture;
  final Future<void> Function(VehicleVideoSlot slot) onRetake;
  final void Function(VehicleVideoSlot slot) onDelete;
  final String title;

  const VehicleVideoSlotsSection({
    super.key,
    required this.videos,
    required this.onCapture,
    required this.onRetake,
    required this.onDelete,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(() {
          // Ensure deterministic order
          final slots = VehicleVideoSlot.values;
          // IMPORTANT (GetX):
          // We must read reactive values inside this Obx builder. `GridView.builder`
          // lazily executes `itemBuilder`, which can run outside the reactive scope,
          // triggering "improper use of a GetX". So we build children eagerly.
          final current = Map<VehicleVideoSlot, XFile?>.from(videos);

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final slot in slots)
                _VideoSlotCard(
                  slot: slot,
                  file: current[slot],
                  onTap: () async {
                    final file = current[slot];
                    if (file == null) {
                      await onCapture(slot);
                    } else {
                      Get.to(
                        () => _VideoPlayerScreen(videoFile: File(file.path)),
                        transition: Transition.cupertino,
                      );
                    }
                  },
                  onRetake: () => onRetake(slot),
                  onDelete: () => onDelete(slot),
                ),
            ],
          );

          /* Previous implementation (lazy builder) caused GetX improper use:
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final file = videos[slot];
              return _VideoSlotCard(
                slot: slot,
                file: file,
                onTap: () async {
                  if (file == null) {
                    await onCapture(slot);
                  } else {
                    Get.to(
                      () => _VideoPlayerScreen(videoFile: File(file.path)),
                      transition: Transition.cupertino,
                    );
                  }
                },
                onRetake: () => onRetake(slot),
                onDelete: () => onDelete(slot),
              );
            },
          );
          */
        }),
      ],
    );
  }
}

class _VideoSlotCard extends StatelessWidget {
  final VehicleVideoSlot slot;
  final XFile? file;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRetake;

  const _VideoSlotCard({
    required this.slot,
    required this.file,
    required this.onTap,
    required this.onDelete,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = file != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasVideo ? Colors.blue.shade300 : Colors.grey.shade300,
              width: hasVideo ? 2 : 1.2,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: hasVideo
                    ? FutureBuilder<File>(
                        future: _getVideoThumbnail(file!.path),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(snapshot.data!, fit: BoxFit.cover),
                                Container(
                                  color: Colors.black.withOpacity(0.25),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : _emptyState(context),
              ),

              // Top-left: label + limit
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: _pill(
                        text: slot.title,
                        background: Colors.black.withOpacity(0.55),
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // _pill(
                    //   text: slot.limitLabel,
                    //   background: slot.isRequired
                    //       ? Colors.black.withOpacity(0.55)
                    //       : Colors.black.withOpacity(0.35),
                    // ),
                  ],
                ),
              ),

              // Top-right: delete (only if exists)
              if (hasVideo)
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              // Bottom row: subtitle / duration + retake
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: hasVideo ? onRetake : onTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: hasVideo
                                ? Colors.white.withOpacity(0.9)
                                : Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasVideo
                                    ? Icons.replay
                                    : Icons.videocam_rounded,
                                size: 18,
                                color: hasVideo
                                    ? Colors.blue.shade800
                                    : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasVideo ? 'Retake' : 'Record',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: hasVideo
                                      ? Colors.blue.shade800
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade700.withOpacity(0.25),
            Colors.blue.shade500.withOpacity(0.10),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_rounded, size: 42, color: Colors.blue.shade700),
            const SizedBox(height: 8),
            Text(
              'Tap to record',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color background,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<File> _getVideoThumbnail(String videoPath) async {
  final thumbnail = await VideoThumbnail.thumbnailFile(
    video: videoPath,
    thumbnailPath: (await getTemporaryDirectory()).path,
    imageFormat: ImageFormat.JPEG,
    quality: 70,
  );
  return File(thumbnail!);
}

class _VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  const _VideoPlayerScreen({required this.videoFile});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPlaying ? _controller.pause() : _controller.play();
                          _isPlaying = !_isPlaying;
                        });
                      },
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
