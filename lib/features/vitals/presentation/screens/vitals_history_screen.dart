import 'package:flutter/material.dart';

class VitalsHistoryScreen extends StatelessWidget {
  const VitalsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitals History')),
      body: const Center(child: Text('Vitals History Content')),
    );
  }
}