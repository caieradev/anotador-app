import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/models/meeting.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.watch(supabaseProvider));
});

class MeetingRepository {
  final SupabaseClient _client;

  MeetingRepository(this._client);

  Future<List<Meeting>> getMeetings() async {
    final response = await _client
        .from('meetings')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((m) => Meeting.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Meeting> getMeeting(String id) async {
    final response =
        await _client.from('meetings').select().eq('id', id).single();
    return Meeting.fromJson(response);
  }

  Future<Meeting> createMeeting({
    required String userId,
    required String type,
    String? language,
  }) async {
    final response = await _client
        .from('meetings')
        .insert({
          'user_id': userId,
          'type': type,
          'status': 'recording',
          'language': language,
        })
        .select()
        .single();
    return Meeting.fromJson(response);
  }

  Future<void> updateMeeting(String id, Map<String, dynamic> data) async {
    await _client.from('meetings').update(data).eq('id', id);
  }

  Future<String> uploadAudio(
    String userId,
    String meetingId,
    Uint8List audioData,
    String extension,
  ) async {
    final path = '$userId/$meetingId.$extension';
    await _client.storage.from('meeting-audio').uploadBinary(path, audioData);
    return path;
  }
}
