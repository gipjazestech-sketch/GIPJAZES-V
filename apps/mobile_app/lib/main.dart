import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'controllers/feed_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/g_button_navigation.dart';
import 'services/api_service.dart';
import 'widgets/comment_sheet.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'screens/profile_screen.dart';

void main() {
  runApp(const GipjazesApp());
}

class GipjazesApp extends StatelessWidget {
  const GipjazesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIPJAZES V',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness:
            Brightness.light, // Switched to light mode for dark text on gold
        scaffoldBackgroundColor: const Color(0xFFD4AF37), // Premium Real Gold
        primaryColor: const Color(0xFF000000), // Solid Black Action
        textTheme:
            GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.light,
          primary: const Color(0xFF000000),
          secondary: const Color(0xFF111111),
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/feed': (context) => const FeedScreen(),
      },
      onGenerateRoute: (settings) {
        // Fallback or custom logic if needed
        return null;
      },
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final VideoFeedController _feedController = VideoFeedController();
  List<dynamic> _feedData = [];
  bool _isLoading = true;
  String? _nextCursor;
  bool _isFetchingMore = false;

  List<String> _categories = ["For You"];
  String _selectedCategory = "For You";

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFeed();
  }

  Future<void> _loadCategories() async {
    final cats = await ApiService().getCategories();
    setState(() => _categories = cats);
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _feedData = [];
        _nextCursor = null;
      });
    }
    try {
      if (_selectedCategory == "For You") {
        final trending = await ApiService().getTrendingVideos();
        setState(() {
          _feedData = trending;
          _nextCursor = null; // Trending is currently a single set
          _isLoading = false;
        });
      } else {
        final response =
            await ApiService().getFeed(category: _selectedCategory);
        setState(() {
          _feedData = response['videos'] ?? [];
          _nextCursor = response['next_cursor'];
          _isLoading = false;
        });
      }

      if (_feedData.isNotEmpty) {
        _feedController.onPageChanged(
            0, _feedData.map((e) => e['video_url'] as String).toList());
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || _nextCursor == null || _nextCursor == "") return;

    setState(() => _isFetchingMore = true);
    try {
      final response = await ApiService().getFeed(
        cursor: _nextCursor,
        category: _selectedCategory,
      );
      final newVideos = response['videos'] as List<dynamic>;

      setState(() {
        _feedData.addAll(newVideos);
        _nextCursor = response['next_cursor'];
        _isFetchingMore = false;
      });

      // Update global URLs in controller so prefetching works for the new items
      _feedController
          .updateUrls(_feedData.map((e) => e['video_url'] as String).toList());
    } catch (e) {
      setState(() => _isFetchingMore = false);
    }
  }

  @override
  void dispose() {
    _feedController.dispose(); // CRITICAL: Dispose all controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      );
    }

    if (_feedData.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No videos found. Be the first to upload!")),
      );
    }

    List<String> videoUrls =
        _feedData.map((e) => e['video_url'] as String).toList();

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _feedData.length,
            onPageChanged: (index) {
              _feedController.onPageChanged(index, videoUrls);
              // Trigger load more when 2 items from the end
              if (index >= _feedData.length - 2) {
                _loadMore();
              }
            },
            itemBuilder: (context, index) {
              return VideoPost(
                controller: _feedController.getController(index),
                index: index,
                videoData: _feedData[index],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = cat);
                                  _loadFeed(refresh: true);
                                }
                              },
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              selectedColor: const Color(0xFFFE2C55),
                              backgroundColor: Colors.black.withOpacity(0.35),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.search, size: 28, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          GButtonNavigation(),
        ],
      ),
    );
  }
}

class VideoPost extends StatefulWidget {
  final VideoPlayerController? controller;
  final int index;
  final dynamic videoData;

  const VideoPost(
      {super.key,
      this.controller,
      required this.index,
      required this.videoData});

  @override
  State<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  bool showHeart = false;
  bool showPlayPause = false;
  IconData playPauseIcon = Icons.play_arrow;
  int likeCount = 0;
  int commentCount = 0;
  int shareCount = 0;
  bool isFollowing = false;

  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    likeCount = widget.videoData['like_count'] is int
        ? widget.videoData['like_count']
        : int.tryParse(widget.videoData['like_count']?.toString() ?? '0') ?? 0;
    commentCount = widget.videoData['comment_count'] is int
        ? widget.videoData['comment_count']
        : int.tryParse(widget.videoData['comment_count']?.toString() ?? '0') ??
            0;
    shareCount = widget.videoData['share_count'] is int
        ? widget.videoData['share_count']
        : int.tryParse(widget.videoData['share_count']?.toString() ?? '0') ?? 0;

    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _heartScale = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    HapticFeedback.mediumImpact(); // 4DX Feel
    try {
      final videoId = widget.videoData['id'];
      if (videoId == null) return;

      final realIsLiked = await ApiService().toggleLike(videoId);
      setState(() {
        isLiked = realIsLiked;
        if (isLiked) {
          likeCount++;
        } else {
          likeCount--;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error liking: $e')));
    }
  }

  void _toggleFollow() async {
    HapticFeedback.lightImpact(); // 4DX Feel
    final creatorId = widget.videoData['creator_id'];
    if (creatorId == null) return;

    try {
      if (isFollowing) {
        await ApiService().unfollowUser(creatorId);
      } else {
        await ApiService().followUser(creatorId);
      }
      setState(() {
        isFollowing = !isFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isFollowing ? 'Followed!' : 'Unfollowed!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showGiftOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Send a Gift",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _giftOption(Icons.favorite, "Heart", 10),
                _giftOption(Icons.star, "Star", 50),
                _giftOption(Icons.local_fire_department, "Fire", 100),
                _giftOption(Icons.rocket_launch, "Rocket", 500),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _giftOption(IconData icon, String label, int amount) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final success =
            await ApiService().sendGift(widget.videoData['creator_id'], amount);
        if (success) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Sent $label gift ($amount)! ✨'),
              backgroundColor: const Color(0xFFFE2C55)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Insufficient balance or error.'),
              backgroundColor: Colors.redAccent));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.amberAccent),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(amount.toString(),
              style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2004),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              title: const Text('Report Video',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Help us keep GIPJAZES community safe',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showReportReasons();
              },
            ),
            ListTile(
              leading: const Icon(Icons.not_interested, color: Colors.white70),
              title: const Text('Not Interested',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showReportReasons() {
    final reasons = [
      "Inappropriate Content",
      "Spam or Misleading",
      "Bullying or Harassment",
      "Sexual Content",
      "Intellectual Property",
      "Other"
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1302),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Select a Reason",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            ...reasons.map((r) => ListTile(
                  title: Text(r, style: const TextStyle(color: Colors.white70)),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await ApiService()
                        .reportVideo(widget.videoData['id'], r);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Report submitted. We\'ll review this shortly.'),
                        backgroundColor: Colors.indigoAccent,
                      ));
                    }
                  },
                )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    if (widget.controller == null) return;

    setState(() {
      if (widget.controller!.value.isPlaying) {
        widget.controller!.pause();
        playPauseIcon = Icons.pause_circle_filled;
      } else {
        widget.controller!.play();
        playPauseIcon = Icons.play_circle_filled;
      }
      showPlayPause = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => showPlayPause = false);
      }
    });
  }

  void _handleDoubleTap() {
    if (!isLiked) {
      _toggleLike();
    }
    setState(() => showHeart = true);
    _heartController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => showHeart = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFE2C55)));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _handleTap,
          onDoubleTap: _handleDoubleTap,
          child: AspectRatio(
            aspectRatio: widget.controller!.value.aspectRatio,
            child: VideoPlayer(widget.controller!),
          ),
        ),

        // Gradient Overlay for readability
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        if (showPlayPause)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Icon(playPauseIcon,
                      color: Colors.white.withOpacity(0.6), size: 100),
                );
              },
            ),
          ),

        if (showHeart)
          Center(
            child: ScaleTransition(
              scale: _heartScale,
              child: const Icon(Icons.favorite,
                  color: Colors.pinkAccent, size: 100),
            ),
          ),

        // Overlays (Like, Comment, Share)
        Positioned(
          left: 15,
          bottom: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  final creatorId = widget.videoData['creator_id'];
                  if (creatorId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: creatorId),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      widget.videoData['creator'] != null
                          ? '@${widget.videoData['creator']['username']}'
                          : '@user_${widget.videoData['creator_id'].substring(0, 5)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    if (widget.videoData['creator'] != null &&
                        widget.videoData['creator']['is_verified'] == true)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.verified,
                            color: Colors.blueAccent, size: 16),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 250,
                child: Text(
                  widget.videoData['description'] ?? 'No description',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
        Positioned(
          right: 15,
          bottom: 120,
          child: Column(
            children: [
              if (!isFollowing)
                _buildActionIcon(
                  Icons.person_add_alt_1,
                  "Follow",
                  color: const Color(0xFFFE2C55),
                  onTap: _toggleFollow,
                ),
              if (!isFollowing) const SizedBox(height: 20),
              if (isFollowing)
                _buildActionIcon(
                  Icons.how_to_reg,
                  "Following",
                  color: Colors.greenAccent,
                  onTap: _toggleFollow,
                ),
              if (isFollowing) const SizedBox(height: 20),
              _buildActionIcon(
                Icons.favorite,
                likeCount.toString(),
                color: isLiked ? Colors.pinkAccent : Colors.white,
                onTap: _toggleLike,
              ),
              const SizedBox(height: 20),
              _buildActionIcon(Icons.comment, commentCount.toString(),
                  onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      CommentSheet(videoId: widget.videoData['id']),
                );
              }),
              const SizedBox(height: 20),
              _buildActionIcon(Icons.card_giftcard, "Gift",
                  color: Colors.amberAccent, onTap: _showGiftOptions),
              const SizedBox(height: 20),
              _buildActionIcon(Icons.share, shareCount.toString(), onTap: () {
                setState(() => shareCount++);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock: Link copied!')));
              }),
              const SizedBox(height: 20),
              _buildActionIcon(Icons.more_horiz, "More",
                  onTap: _showMoreOptions),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label,
      {Color color = Colors.white, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
