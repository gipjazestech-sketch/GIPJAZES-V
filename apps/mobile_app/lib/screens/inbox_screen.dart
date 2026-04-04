import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await ApiService().getConversations();
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Inbox',
            style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.group_add_outlined, color: Color(0xFFFE2C55)),
            onPressed: () {
              // Future: Create Group
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group creation coming soon!')));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE2C55)))
          : _chats.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _chats.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.white10,
                    indent: 80,
                  ),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return _buildChatItem(chat);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined,
              size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text(
            "Your inbox is empty",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 10),
          const Text(
            "Start chatting with creators!",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(dynamic chat) {
    // Parsing date from backend last_message_at
    final DateTime lastMsgAt = chat['last_message_at'] != null
        ? DateTime.parse(chat['last_message_at'])
        : DateTime.now();
    final timeStr = DateFormat.jm().format(lastMsgAt.toLocal());
    final bool isGroup = chat['is_group'] == true;
    final String title = chat['name'] ?? 'Chat';
    final String? avatarUrl = chat['avatar_url'];

    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: chat['id'],
              title: title,
              isGroup: isGroup,
              avatarUrl: avatarUrl,
            ),
          ),
        );
        _loadChats(); // Refresh on return
      },
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isGroup
                ? [const Color(0xFF00E5FF), const Color(0xFF00EE8B)]
                : [const Color(0xFFFE2C55), const Color(0xFF6200EE)],
          ),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : null,
          backgroundColor: Colors.grey[900],
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Icon(isGroup ? Icons.group : Icons.person, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat['last_message'] ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
        ),
      ),
      trailing: Text(timeStr,
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}


