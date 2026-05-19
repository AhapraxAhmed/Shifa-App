import 'package:flutter/material.dart';

class NotesHistoryScreen extends StatelessWidget {
  const NotesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes History')),
      body: const Center(child: Text('Notes History Content')),
    );
  }
}