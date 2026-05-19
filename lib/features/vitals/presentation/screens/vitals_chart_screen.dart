import 'package:flutter/material.dart';

class VitalsChartScreen extends StatelessWidget {
  const VitalsChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitals Chart')),
      body: const Center(child: Text('Vitals Chart Content')),
    );
  }
}