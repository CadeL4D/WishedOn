import 'package:flutter/material.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Group Settings'),
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Group Settings Page\n(Only visible to Owners)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
