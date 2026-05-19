import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Admin & Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Enterprise Configuration', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
