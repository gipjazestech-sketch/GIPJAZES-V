import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'upload_progress_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera(0);
  }

  Future<void> _initCamera(int index) async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _selectedCameraIndex = index;
      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;
    int nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _cameraController?.dispose();
    _initCamera(nextIndex);
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    await _cameraController!.startVideoRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }
    final file = await _cameraController!.stopVideoRecording();
    setState(() => _isRecording = false);
    _goToUpload(file);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _goToUpload(pickedFile);
    }
  }

  void _goToUpload(XFile videoFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadProgressScreen(videoFile: videoFile),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library,
                      color: Colors.white, size: 30),
                  onPressed: _pickFromGallery,
                ),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isRecording ? Colors.red : Colors.transparent,
                    ),
                    child: Center(
                      child: Container(
                        height: _isRecording ? 30 : 60,
                        width: _isRecording ? 30 : 60,
                        decoration: BoxDecoration(
                          shape: _isRecording
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          color: Colors.red,
                          borderRadius:
                              _isRecording ? BorderRadius.circular(5) : null,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios,
                      color: Colors.white, size: 30),
                  onPressed: _toggleCamera,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


