import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LicensePlateCameraScreen extends StatefulWidget {
  const LicensePlateCameraScreen({super.key});

  @override
  State<LicensePlateCameraScreen> createState() =>
      _LicensePlateCameraScreenState();
}

class _LicensePlateCameraScreenState extends State<LicensePlateCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _startCamera(_selectedCameraIndex);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _startCamera(int cameraIndex) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start camera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _flashMode = _flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
    });

    await _controller!.setFlashMode(_flashMode);
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();

      // Don't dispose here - let dispose() handle it
      // Just navigate back with the result
      if (mounted && context.mounted) {
        Navigator.of(context).pop(image.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show error using ScaffoldMessenger to avoid GetX conflicts
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller
        ?.dispose()
        .then((_) {
          _controller = null;
        })
        .catchError((_) {
          _controller = null;
        });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized &&
                _controller != null &&
                _controller!.value.isInitialized)
              Positioned.fill(child: CameraPreview(_controller!))
            else
              const Center(
                child: Text(
                  'Initializing camera...',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // License Plate Scanning Frame
            _buildScanningFrame(),

            // Top Controls
            Positioned(top: 0, left: 0, right: 0, child: _buildTopControls()),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningFrame() {
    final screenSize = MediaQuery.of(context).size;
    final frameWidth = screenSize.width * 0.8; // 80% of screen width
    final frameHeight = frameWidth / 3; // 3:1 aspect ratio (license plate)
    final frameTop =
        (screenSize.height - frameHeight) / 2 - 50; // Centered vertically

    return Positioned(
      top: frameTop,
      left: (screenSize.width - frameWidth) / 2,
      child: Container(
        width: frameWidth,
        height: frameHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Corner indicators
            _buildCornerIndicator(Alignment.topLeft),
            _buildCornerIndicator(Alignment.topRight),
            _buildCornerIndicator(Alignment.bottomLeft),
            _buildCornerIndicator(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(color: Colors.green, width: 4),
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.green, width: 4)
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.green, width: 4)
                : BorderSide.none,
            bottom: BorderSide(color: Colors.green, width: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              _controller?.dispose();
              if (mounted && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          const Text(
            'Position License Plate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Balance for close button
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Control buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Switch Camera
              IconButton(
                icon: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _cameras != null && _cameras!.length > 1
                    ? _switchCamera
                    : null,
              ),
              // Capture Button
              GestureDetector(
                onTap: _isProcessing ? null : _captureImage,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isProcessing ? Colors.grey : Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 4),
                  ),
                  child: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              // Flash Toggle
              IconButton(
                icon: Icon(
                  _flashMode == FlashMode.torch
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _toggleFlash,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Instruction text
          const Text(
            'Align license plate within the frame',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
