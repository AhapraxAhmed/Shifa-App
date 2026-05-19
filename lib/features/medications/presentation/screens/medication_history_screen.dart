import 'package:flutter/material.dart';

class MedicationHistoryScreen extends StatelessWidget {
  const MedicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication History')),
      body: const Center(child: Text('Medication History Content')),
    );
  }
}