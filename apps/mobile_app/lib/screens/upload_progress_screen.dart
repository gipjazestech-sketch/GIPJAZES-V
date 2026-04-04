import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';

class UploadProgressScreen extends StatefulWidget {
  final XFile videoFile;
  const UploadProgressScreen({super.key, required this.videoFile});

  @override
  State<UploadProgressScreen> createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  final UploadService _uploadService = UploadService();
  double _progress = 0.0;
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  void _startUpload() {
    _uploadService.uploadVideo(
      file: widget.videoFile,
      fileName: widget.videoFile.name,
      onProgress: (p) => setState(() => _progress = p),
      onComplete: () => setState(() => _isComplete = true),
      onError: (e) => setState(() => _error = e),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Uploading to GIPJAZES V",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFE2C55)),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: const Color(0xFFFE2C55),
                    ),
                  ),
                  Text(
                    "${(_progress * 100).toInt()}%",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (_isComplete) ...[
                const Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 48),
                const SizedBox(height: 10),
                const Text("Success! Processing video...",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Done"),
                )
              ] else if (_error != null) ...[
                Text("Error: $_error",
                    style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _startUpload, child: const Text("Retry")),
              ] else ...[
                const Text("Optimizing for HLS streaming...",
                    style: TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


