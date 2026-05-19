import 'package:flutter/material.dart';

class AddVitalsScreen extends StatelessWidget {
  const AddVitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vitals')),
      body: const Center(child: Text('Add Vitals Content')),
    );
  }
}