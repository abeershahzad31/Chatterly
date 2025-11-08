import 'package:flutter/material.dart';

class UserRow extends StatelessWidget {
  const UserRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _buildUserAvatar("AI Chat", Colors.green, Icons.smart_toy),
          _buildUserAvatar("John", Colors.blue, Icons.person),
          _buildUserAvatar("Emma", Colors.orange, Icons.person),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String name, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 5),
          Text(name,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
