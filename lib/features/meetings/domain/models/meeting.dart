class Meeting {
  final String id;
  final String userId;
  final String? title;
  final String type; // 'presential' or 'online'
  final String status; // 'recording', 'processing', 'completed', 'failed'
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? language;
  final String? audioUrl;
  final String? rawTranscript;
  final String? refinedTranscript;
  final String? summary;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Meeting({
    required this.id,
    required this.userId,
    this.title,
    required this.type,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.language,
    this.audioUrl,
    this.rawTranscript,
    this.refinedTranscript,
    this.summary,
    required this.createdAt,
    this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      type: (json['type'] as String?) ?? 'presential',
      status: (json['status'] as String?) ?? 'recording',
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      language: json['language'] as String?,
      audioUrl: json['audio_url'] as String?,
      rawTranscript: json['raw_transcript'] as String?,
      refinedTranscript: json['refined_transcript'] as String?,
      summary: json['summary'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'type': type,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'language': language,
        'audio_url': audioUrl,
        'raw_transcript': rawTranscript,
        'refined_transcript': refinedTranscript,
        'summary': summary,
      };

  Meeting copyWith({
    String? id,
    String? userId,
    String? title,
    String? type,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? language,
    String? audioUrl,
    String? rawTranscript,
    String? refinedTranscript,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      language: language ?? this.language,
      audioUrl: audioUrl ?? this.audioUrl,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      refinedTranscript: refinedTranscript ?? this.refinedTranscript,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
