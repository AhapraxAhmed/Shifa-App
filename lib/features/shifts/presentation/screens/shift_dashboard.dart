import 'package:flutter/material.dart';

class ShiftDashboard extends StatelessWidget {
  const ShiftDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift Dashboard')),
      body: const Center(child: Text('Shift Dashboard Content')),
    );
  }
}