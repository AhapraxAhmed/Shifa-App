import 'package:flutter/material.dart';

class ShiftHistoryScreen extends StatelessWidget {
  const ShiftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift History')),
      body: const Center(child: Text('Shift History Content')),
    );
  }
}