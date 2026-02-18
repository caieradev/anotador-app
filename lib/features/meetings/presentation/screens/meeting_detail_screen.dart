import 'package:flutter/material.dart';

class MeetingDetailScreen extends StatelessWidget {
  final String meetingId;
  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reuniao')),
      body: Center(child: Text('Meeting: $meetingId')),
    );
  }
}
