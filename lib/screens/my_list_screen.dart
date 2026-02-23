import 'package:flutter/material.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('My List'),
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'My Personal Saved Items',
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
