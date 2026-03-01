import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.isGroup = false,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await ApiService().getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await ApiService().sendMessage(widget.conversationId, text);
    if (success) {
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1302),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                      ? NetworkImage(widget.avatarUrl!)
                      : null,
              backgroundColor: const Color(0xFFFE2C55).withOpacity(0.2),
              child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                  ? Icon(widget.isGroup ? Icons.group : Icons.person,
                      size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE2C55)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // For simplicity, we assume if we sent it, it's 'me'
                      // In a real app we'd compare with our own userId from session
                      final isMe =
                          msg['sender_id'] != null; // Placeholder logic
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    // Note: Since we don't have our own userID here easily,
    // we'll use a hack or just style them all centered for now
    // but I'll maintain the isMe structure.

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFE2C55) : const Color(0xFF2C2F36),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            if (isMe)
              BoxShadow(
                color: const Color(0xFFFE2C55).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 15,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              msg['created_at'] != null
                  ? DateFormat.jm()
                      .format(DateTime.parse(msg['created_at']).toLocal())
                  : '',
              style: TextStyle(
                color: isMe ? Colors.black.withOpacity(0.5) : Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 15,
        right: 15,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2004),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFE2C55),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}


