import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      body: const Center(child: Text('Reminders')),
    );
  }
}
