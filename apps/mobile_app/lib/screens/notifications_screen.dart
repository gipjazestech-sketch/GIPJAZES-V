import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final alerts = await ApiService().getNotifications();
    setState(() {
      _notifications = alerts;
      _isLoading = false;
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'gift':
        return Icons.card_giftcard;
      case 'like':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'follow':
        return Colors.greenAccent;
      case 'gift':
        return Colors.amberAccent;
      case 'like':
        return Colors.pinkAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Notifications',
            style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE2C55)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final alert = _notifications[index];
                    final date = DateTime.parse(alert['created_at']);
                    final timeStr = DateFormat.jm().format(date.toLocal());

                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _getColorForType(alert['type']).withOpacity(0.1),
                        ),
                        child: Icon(
                          _getIconForType(alert['type']),
                          color: _getColorForType(alert['type']),
                        ),
                      ),
                      title: Text(
                        alert['title'] ?? 'New Alert',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(alert['body'] ?? '',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 5),
                          Text(timeStr,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text(
            "All caught up!",
            style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "You have no new notifications.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


