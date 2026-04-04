import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../screens/capture_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/inbox_screen.dart';

class GButtonNavigation extends StatefulWidget {
  const GButtonNavigation({super.key});

  @override
  _GButtonNavigationState createState() => _GButtonNavigationState();
}

class _GButtonNavigationState extends State<GButtonNavigation>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );
  }

  void toggleMenu() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _onFeatureNotReady(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon to GIPJAZES V 🔥'),
        backgroundColor: Colors.cyanAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Darkened Background when expanded
        if (isExpanded)
          GestureDetector(
            onTap: toggleMenu,
            child: Container(
              color: Colors.black.withOpacity(0.4),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // The Floating Action Items (Expandable)
        Positioned(
          bottom: 110,
          child: ScaleTransition(
            scale: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2004).withOpacity(0.95),
                borderRadius: BorderRadius.circular(35),
                border:
                    Border.all(color: const Color(0xFFFE2C55).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navItem(Icons.people_outline, "Friends",
                      onTap: () => _onFeatureNotReady("Friends Feed")),
                  const SizedBox(width: 25),
                  _navItem(Icons.explore_outlined, "Explore",
                      onTap: () => _onFeatureNotReady("Explorer")),
                  const SizedBox(width: 25),
                  _navItem(
                    Icons.add_box,
                    "Post",
                    color: const Color(0xFFFE2C55),
                    onTap: () {
                      toggleMenu();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CaptureScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 25),
                  _navItem(Icons.mail_outline, "Inbox", onTap: () {
                    toggleMenu();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InboxScreen()),
                    );
                  }),
                  const SizedBox(width: 25),
                  _navItem(
                    Icons.person_outline,
                    "Me",
                    onTap: () {
                      toggleMenu();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // The Core "G" Button (Square)
        Positioned(
          bottom: 30,
          child: GestureDetector(
            onTap: toggleMenu,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * math.pi / 4,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color:
                          isExpanded ? const Color(0xFFFE2C55) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isExpanded
                              ? const Color(0xFFFE2C55).withOpacity(0.6)
                              : Colors.white70.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: isExpanded ? 4 : 2,
                        )
                      ],
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -_controller.value * math.pi / 4,
                        child: Text(
                          "G",
                          style: TextStyle(
                            fontSize: 34,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w900,
                            color: isExpanded ? Colors.black : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label,
      {Color color = Colors.white, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


