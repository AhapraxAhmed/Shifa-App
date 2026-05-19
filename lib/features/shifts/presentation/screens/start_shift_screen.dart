import 'package:flutter/material.dart';

class StartShiftScreen extends StatelessWidget {
  const StartShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Shift')),
      body: const Center(child: Text('Start Shift Content')),
    );
  }
}