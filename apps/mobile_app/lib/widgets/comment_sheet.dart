import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CommentSheet extends StatefulWidget {
  final String videoId;
  const CommentSheet({super.key, required this.videoId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final data = await ApiService().getComments(widget.videoId);
      setState(() {
        _comments = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading comments: $e')));
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear();

    try {
      await ApiService().postComment(widget.videoId, content);
      _loadComments(); // Refresh comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A2004),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 15),
          const Text("Comments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white10, height: 30),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE2C55)))
                : _comments.isEmpty
                    ? const Center(
                        child: Text("No comments yet. Start the conversation!",
                            style: TextStyle(color: Colors.white30)))
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFFFE2C55).withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Color(0xFFFE2C55), size: 20),
                            ),
                            title: Text(comment['username'] ?? 'User',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(comment['content'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.favorite_border,
                                size: 16, color: Colors.white24),
                          );
                        },
                      ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _submitComment,
                  icon:
                      const Icon(Icons.send_rounded, color: Color(0xFFFE2C55)),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}


