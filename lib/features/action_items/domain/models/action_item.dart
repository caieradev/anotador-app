class ActionItem {
  final String id;
  final String meetingId;
  final String description;
  final String? assignee;
  final DateTime? dueDate;
  final String status; // 'pending' or 'done'
  final DateTime createdAt;
  final String? meetingTitle; // joined from meetings table

  ActionItem({
    required this.id,
    required this.meetingId,
    required this.description,
    this.assignee,
    this.dueDate,
    required this.status,
    required this.createdAt,
    this.meetingTitle,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    // Handle joined meeting data
    final meetingData = json['meetings'] as Map<String, dynamic>?;

    return ActionItem(
      id: json['id'] as String,
      meetingId: json['meeting_id'] as String,
      description: json['description'] as String,
      assignee: json['assignee'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      meetingTitle: meetingData?['title'] as String?,
    );
  }

  ActionItem copyWith({
    String? status,
    String? meetingTitle,
  }) {
    return ActionItem(
      id: id,
      meetingId: meetingId,
      description: description,
      assignee: assignee,
      dueDate: dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
      meetingTitle: meetingTitle ?? this.meetingTitle,
    );
  }
}
