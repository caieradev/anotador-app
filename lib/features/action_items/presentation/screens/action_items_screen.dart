import 'package:flutter/material.dart';

class ActionItemsScreen extends StatelessWidget {
  const ActionItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acoes')),
      body: const Center(child: Text('Action Items')),
    );
  }
}
