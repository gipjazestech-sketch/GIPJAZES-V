import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../main.dart'; // To reuse VideoPost if possible, or we define a simple one

class VideoDetailScreen extends StatefulWidget {
  final dynamic videoData;
  const VideoDetailScreen({super.key, required this.videoData});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoData['video_url']))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: VideoPost(
        controller: _controller,
        index: 0,
        videoData: widget.videoData,
      ),
    );
  }
}


