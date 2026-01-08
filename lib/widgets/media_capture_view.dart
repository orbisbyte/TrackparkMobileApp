import 'dart:io';

import 'package:driver_tracking_airport/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Reusable media capture view that can be used for pickup, parking, delivery, etc.
class MediaCaptureView extends StatelessWidget {
  final RxList<XFile> images;
  final Rxn<XFile> video;
  final TextEditingController? parkingNotesController;

  /// Optional override for the entire video section UI.
  /// When provided, the default single-video UI is not shown.
  final Widget? customVideoSection;

  final VoidCallback? onCaptureFromGallery;
  final VoidCallback onCaptureFromCamera;
  final VoidCallback onCaptureVideo;
  final VoidCallback onRetakeVideo;
  final VoidCallback onClearAll;
  final void Function(int index) onRemoveImage;
  final VoidCallback onDeleteVideo;

  final String headerTitle;
  final String headerSubtitle;
  final String photosTitle;
  final String videoTitle;

  // Vehicle condition checkboxes (optional)
  final RxBool? isDamaged;
  final RxBool? isScratched;
  final RxBool? isDirty;
  final TextEditingController? conditionNotesController;

  const MediaCaptureView({
    super.key,
    required this.images,
    required this.video,
    this.customVideoSection,
    this.onCaptureFromGallery,
    this.parkingNotesController,
    required this.onCaptureFromCamera,
    required this.onCaptureVideo,
    required this.onRetakeVideo,
    required this.onClearAll,
    required this.onRemoveImage,
    required this.onDeleteVideo,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.photosTitle,
    required this.videoTitle,
    this.isDamaged,
    this.isScratched,
    this.isDirty,
    this.conditionNotesController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle condition checkboxes (if provided)
          if (isDamaged != null && isScratched != null && isDirty != null) ...[
            _buildVehicleConditionSection(context),
            const SizedBox(height: 24),
          ],
          _buildHeaderSection(context),
          const SizedBox(height: 24),
          _buildImageSection(context),
          const SizedBox(height: 24),
          customVideoSection ?? _buildVideoSection(context),
          const SizedBox(height: 24),
          if (parkingNotesController != null) ...[
            _buildParkingNotesSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleConditionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vehicle Condition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final hasAnyCondition =
                isDamaged!.value || isScratched!.value || isDirty!.value;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildConditionCheckbox(
                        label: 'Damaged',
                        value: isDamaged!.value,
                        onChanged: (value) => isDamaged!.value = value,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildConditionCheckbox(
                        label: 'Scratched',
                        value: isScratched!.value,
                        onChanged: (value) => isScratched!.value = value,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildConditionCheckbox(
                        label: 'Dirty',
                        value: isDirty!.value,
                        onChanged: (value) => isDirty!.value = value,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                // Show condition notes text field when any checkbox is selected
                if (hasAnyCondition && conditionNotesController != null) ...[
                  const SizedBox(height: 16),
                  _buildConditionNotesField(context),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConditionCheckbox({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? color : Colors.grey.shade300,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? color : Colors.grey.shade400,
                  width: 2,
                ),
                color: value ? color : Colors.transparent,
              ),
              child: value
                  ? Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                color: value ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionNotesField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition Notes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 1.5),
          ),
          child: TextField(
            controller: conditionNotesController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: 'Enter details about the condition...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.note_outlined,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParkingNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parking Slot Info',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.4,
            ),
          ),
          child: TextField(
            controller: parkingNotesController,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: 'Enter parking slot info (optional)',
              hintStyle: TextStyle(
                color: Colors.blueGrey.shade300,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: Colors.blue.shade200,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          headerSubtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              photosTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Obx(
              () => images.isEmpty
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: onClearAll,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () => images.isEmpty
              ? _buildEmptyState(
                  icon: Icons.photo_camera,
                  text: 'No photos added yet',
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return _buildImageItem(index);
                  },
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (onCaptureFromGallery != null) ...[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: onCaptureFromGallery,
                    icon: Icon(
                      Icons.photo_library,
                      color: Colors.blue.shade800,
                    ),
                    label: Text(
                      'From Gallery',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide.none,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onCaptureFromCamera,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(images[index].path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemoveImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          videoTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => video.value == null
              ? _buildEmptyState(
                  icon: Icons.videocam,
                  text: 'No video recorded yet',
                )
              : _buildVideoPreview(),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => video.value == null ? onCaptureVideo() : onRetakeVideo(),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  video.value == null ? Icons.videocam : Icons.replay,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  video.value == null ? 'Record Video' : 'Retake Video',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return GestureDetector(
      onTap: () {
        if (video.value != null) {
          Get.to(
            () => VideoPlayerScreen(videoFile: File(video.value!.path)),
            transition: Transition.cupertino,
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video thumbnail container
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: video.value != null
                  ? FutureBuilder<File>(
                      future: _getVideoThumbnail(video.value!.path),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Stack(
                            children: [
                              Image.file(
                                snapshot.data!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.shade800.withOpacity(0.7),
                            Colors.blue.shade600.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.videocam_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Record 360° Video',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Video duration badge (only when video exists)
          if (video.value != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FutureBuilder<Duration?>(
                  future: _getVideoDuration(video.value!.path),
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return Text(
                      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Delete button (only when video exists)
          if (video.value != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: InkWell(
                onTap: onDeleteVideo,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade200.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<File> _getVideoThumbnail(String videoPath) async {
    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    return File(thumbnail!);
  }

  Future<Duration> _getVideoDuration(String videoPath) async {
    final player = VideoPlayerController.file(File(videoPath));
    await player.initialize();
    final duration = player.value.duration;
    await player.dispose();
    return duration;
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// Full-screen video player used by [MediaCaptureView].
class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
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
