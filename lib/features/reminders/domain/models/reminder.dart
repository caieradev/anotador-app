class Reminder {
  final String id;
  final String meetingId;
  final String? actionItemId;
  final String message;
  final DateTime remindAt;
  final String status; // 'pending', 'sent', 'dismissed'
  final DateTime createdAt;
  final String? meetingTitle;

  Reminder({
    required this.id,
    required this.meetingId,
    this.actionItemId,
    required this.message,
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
      actionItemId: json['action_item_id'] as String?,
      message: json['message'] as String,
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
      actionItemId: actionItemId,
      message: message,
      remindAt: remindAt,
      status: status ?? this.status,
      createdAt: createdAt,
      meetingTitle: meetingTitle,
    );
  }
}
