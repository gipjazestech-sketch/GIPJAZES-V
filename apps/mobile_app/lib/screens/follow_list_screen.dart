import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String title;
  final bool isFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final data = widget.isFollowers
          ? await ApiService().getFollowers(widget.userId)
          : await ApiService().getFollowing(widget.userId);
      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE2C55)))
          : _users.isEmpty
              ? Center(
                  child: Text(
                    "No ${widget.title.toLowerCase()} yet.",
                    style: const TextStyle(color: Colors.white30),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFFFE2C55).withOpacity(0.1),
                        backgroundImage: (user['avatar_url'] != null &&
                                user['avatar_url'].isNotEmpty)
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child: (user['avatar_url'] == null ||
                                user['avatar_url'].isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFFFE2C55))
                            : null,
                      ),
                      title: Text(
                        user['username'] ?? 'user',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        user['display_name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      trailing: user['is_verified'] == true
                          ? const Icon(Icons.verified,
                              color: Colors.blue, size: 16)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(userId: user['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}


