import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'video_detail_screen.dart';
import 'follow_list_screen.dart';
import 'chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  int _followersCount = 0;
  int _followingCount = 0;
  int _balance = 0;
  List<dynamic> _videos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await (widget.userId == null
          ? ApiService().getProfile()
          : ApiService().getExternalProfile(widget.userId!));
      setState(() {
        _user = data['user'];
        _followersCount = data['followers'] ?? 0;
        _followingCount = data['following'] ?? 0;
        _videos = data['videos'] ?? [];
        _isLoading = false;
      });
      _loadBalance();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBalance() async {
    if (widget.userId == null) {
      final balance = await ApiService().getWalletBalance();
      if (mounted) {
        setState(() => _balance = balance);
      }
    }
  }

  int _calculateTotalLikes() {
    if (_videos.isEmpty) return 0;
    int total = 0;
    for (var video in _videos) {
      final likes = video['like_count'];
      if (likes != null) {
        if (likes is int) {
          total += likes;
        } else if (likes is String) total += int.tryParse(likes) ?? 0;
      }
    }
    return total;
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  Future<void> _startChat() async {
    if (_user == null) return;

    // For direct chat, we fetch and create if needed on the backend
    try {
      final convs = await ApiService().getConversations();
      final existing = convs.firstWhere(
        (c) => c['is_group'] == false && c['partner_id'] == _user!['id'],
        orElse: () => null,
      );

      if (existing != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: existing['id'],
              title: _user!['username'],
              avatarUrl: _user!['avatar_url'],
            ),
          ),
        );
      } else {
        // This is a bit of a hack since we don't have a direct "findOrCreate" API exposing ID yet
        // but we can send an empty message or just wait for the user to type something.
        // For now, let's just show the inbox or handle it by sending a "Hi" placeholder.
        final success =
            await ApiService().sendMessageToUser(_user!['id'], "Hi!");
        if (success) {
          _startChat(); // Retry once to get the ID
        }
      }
    } catch (e) {
      debugPrint("Chat error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 60),
              const SizedBox(height: 20),
              Text("Error: $_error",
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child:
                Text("User not found.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.black.withOpacity(0.8),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('@${_user!['username']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2)),
                    if (_user!['is_verified'] == true)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.verified,
                            color: Colors.blueAccent, size: 18),
                      ),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                      icon: const Icon(Icons.share_outlined), onPressed: () {}),
                  IconButton(
                      icon: const Icon(Icons.more_vert), onPressed: () {}),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [Color(0xFFFE2C55), Color(0xFF25F4EE)]),
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.black,
                            child: Icon(Icons.person_outline,
                                size: 50, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFFE2C55), shape: BoxShape.circle),
                          child: const Icon(Icons.add,
                              size: 20, color: Colors.black),
                        ),
                      ],
                    ),
                    if (widget.userId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _startChat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFE2C55),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                              ),
                              child: const Text('Chat',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 25),
                    if (widget.userId == null) _buildWalletCard(),
                    if (widget.userId == null) const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userId: _user!['id'],
                                title: 'Following',
                                isFollowers: false,
                              ),
                            ),
                          ),
                          child: _buildStatColumn(
                              'Following', _formatNumber(_followingCount)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userId: _user!['id'],
                                title: 'Followers',
                                isFollowers: true,
                              ),
                            ),
                          ),
                          child: _buildStatColumn(
                              'Followers', _formatNumber(_followersCount)),
                        ),
                        _buildStatColumn(
                            'Likes', _formatNumber(_calculateTotalLikes())),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.1))),
                                elevation: 0,
                              ),
                              child: const Text('Edit Profile',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border,
                                  color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text("No bio yet. Tap to add one! ✨",
                          style:
                              TextStyle(color: Colors.white30, fontSize: 13)),
                    ),
                    const TabBar(
                      indicatorColor: Color(0xFFFE2C55),
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      tabs: [
                        Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                        Tab(icon: Icon(Icons.favorite_rounded, size: 22)),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildVideoGrid(),
              _buildVideoGrid(), // Placeholder for liked videos
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white38,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildVideoGrid() {
    if (_videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_collection_outlined,
                color: Colors.white10, size: 80),
            SizedBox(height: 15),
            Text("Your videos will appear here",
                style: TextStyle(color: Colors.white24)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(videoData: video)),
            );
          },
          child: Container(
            color: Colors.white.withOpacity(0.05),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (video['thumbnail_url'] != null &&
                    video['thumbnail_url'].isNotEmpty)
                  Image.network(video['thumbnail_url'], fit: BoxFit.cover)
                else
                  const Center(
                      child: Icon(Icons.play_arrow_rounded,
                          color: Colors.white24, size: 40)),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatNumber(video['like_count'] is int
                            ? video['like_count']
                            : int.tryParse(
                                    video['like_count']?.toString() ?? '0') ??
                                0),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2004),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE2C55).withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Balance",
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("$_balance",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55).withOpacity(0.1),
              foregroundColor: const Color(0xFFFE2C55),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text("Refill",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


