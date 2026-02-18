class Reminder {
  final String id;
  final String meetingId;
  final String description;
  final DateTime remindAt;
  final String status; // 'pending', 'sent', 'dismissed'
  final DateTime createdAt;
  final String? meetingTitle;

  Reminder({
    required this.id,
    required this.meetingId,
    required this.description,
    required this.remindAt,
    required this.status,
    required this.createdAt,
    this.meetingTitle,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final meetingData = json['meetings'] as Map<String, dynamic>?;

    return Reminder(
      id: json['id'] as String,
      meetingId: json['meeting_id'] as String,
      description: json['description'] as String,
      remindAt: DateTime.parse(json['remind_at'] as String),
      status: (json['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      meetingTitle: meetingData?['title'] as String?,
    );
  }

  Reminder copyWith({String? status}) {
    return Reminder(
      id: id,
      meetingId: meetingId,
      description: description,
      remindAt: remindAt,
      status: status ?? this.status,
      createdAt: createdAt,
      meetingTitle: meetingTitle,
    );
  }
}
