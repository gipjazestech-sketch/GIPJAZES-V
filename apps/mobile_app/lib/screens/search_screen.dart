import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'video_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isSearching = false;

  // Voice Search State
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => debugPrint('Voice Error: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
            });
            if (val.finalResult) {
              _performSearch(val.recognizedWords);
            }
          },
        );
      } else {
        // Request microphone permission if not available
        await Permission.microphone.request();
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final data = await ApiService().searchVideos(query);
      setState(() {
        _results = data;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color:
                  _isListening ? const Color(0xFFFE2C55) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFFE2C55), size: 20),
              const SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: _isListening ? "Listening..." : "Search...",
                    hintStyle: TextStyle(
                      color: _isListening
                          ? const Color(0xFFFE2C55).withOpacity(0.5)
                          : Colors.white30,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _listen,
                child: ScaleTransition(
                  scale: _isListening
                      ? Tween<double>(begin: 1.0, end: 1.2)
                          .animate(_pulseController)
                      : const AlwaysStoppedAnimation(1.0),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color:
                        _isListening ? const Color(0xFFFE2C55) : Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE2C55)))
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: const Color(0xFFFE2C55).withOpacity(0.2),
                          size: 100),
                      const SizedBox(height: 20),
                      const Text("Discover something new on GIPJAZES V",
                          style:
                              TextStyle(color: Colors.white30, fontSize: 16)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final video = _results[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  VideoDetailScreen(videoData: video)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          image: video['thumbnail_url'] != null &&
                                  video['thumbnail_url'].isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(video['thumbnail_url']),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (video['thumbnail_url'] == null ||
                                video['thumbnail_url'].isEmpty)
                              const Center(
                                  child: Icon(Icons.play_circle_outline,
                                      color: Colors.white24, size: 50)),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8)
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.person,
                                            color: Color(0xFFFE2C55), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          video['creator'] != null
                                              ? '@${video['creator']['username']}'
                                              : 'user',
                                          style: const TextStyle(
                                              color: Color(0xFFFE2C55),
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

