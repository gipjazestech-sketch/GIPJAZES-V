import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoFeedController extends ChangeNotifier {
  // Sliding Window Cache: Only keep 3 controllers active
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void onPageChanged(int index, List<String> urls) {
    _currentIndex = index;
    _manageControllers(index, urls);
    notifyListeners();
  }

  /// Keep URLs updated as list grows
  void updateUrls(List<String> urls) {
    _manageControllers(_currentIndex, urls);
  }

  void _manageControllers(int index, List<String> urls) {
    // 1. Initialize Current, Previous, and Next
    _initController(index, urls[index]);
    if (index > 0) _initController(index - 1, urls[index - 1]);
    if (index < urls.length - 1) _initController(index + 1, urls[index + 1]);

    // 2. Dispose controllers outside the sliding window (index +/- 1)
    final keysToRemove =
        _controllers.keys.where((i) => (i - index).abs() > 1).toList();
    for (var key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      if (kDebugMode) print("Disposed Controller at index: $key");
    }

    // 3. Play current, pause others
    _controllers.forEach((i, controller) {
      if (i == index) {
        controller.play();
        controller.setLooping(true);
      } else {
        controller.pause();
      }
    });
  }

  Future<void> _initController(int index, String url) async {
    if (_controllers.containsKey(index)) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;

    try {
      await controller.initialize();
      if (index == _currentIndex) {
        controller.play();
        controller.setLooping(true);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error initializing video at $index: $e");
    }
  }

  VideoPlayerController? getController(int index) => _controllers[index];

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}


