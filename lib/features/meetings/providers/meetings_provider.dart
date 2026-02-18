import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/repositories/meeting_repository.dart';
import '../domain/models/meeting.dart';

class MeetingsNotifier extends StateNotifier<AsyncValue<List<Meeting>>> {
  final MeetingRepository _repository;
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  MeetingsNotifier(this._repository, this._client)
      : super(const AsyncLoading()) {
    _loadMeetings();
    _subscribeToRealtime();
  }

  Future<void> _loadMeetings() async {
    try {
      state = const AsyncLoading();
      final meetings = await _repository.getMeetings();
      state = AsyncData(meetings);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _subscribeToRealtime() {
    _channel = _client
        .channel('meetings_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meetings',
          callback: (payload) {
            _handleRealtimeEvent(payload);
          },
        )
        .subscribe();
  }

  void _handleRealtimeEvent(PostgresChangePayload payload) {
    final currentData = state.valueOrNull;
    if (currentData == null) return;

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final newMeeting =
            Meeting.fromJson(payload.newRecord);
        state = AsyncData([newMeeting, ...currentData]);
        break;
      case PostgresChangeEvent.update:
        final updated =
            Meeting.fromJson(payload.newRecord);
        final updatedList = currentData.map((m) {
          return m.id == updated.id ? updated : m;
        }).toList();
        state = AsyncData(updatedList);
        break;
      case PostgresChangeEvent.delete:
        final deletedId = payload.oldRecord['id'] as String?;
        if (deletedId != null) {
          final filtered =
              currentData.where((m) => m.id != deletedId).toList();
          state = AsyncData(filtered);
        }
        break;
      default:
        break;
    }
  }

  Future<void> refresh() async {
    await _loadMeetings();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final meetingsProvider =
    StateNotifierProvider<MeetingsNotifier, AsyncValue<List<Meeting>>>((ref) {
  final repository = ref.watch(meetingRepositoryProvider);
  final client = ref.watch(supabaseProvider);
  return MeetingsNotifier(repository, client);
});

/// Provider for a single meeting by ID
final meetingDetailProvider =
    FutureProvider.family<Meeting, String>((ref, id) async {
  final repository = ref.watch(meetingRepositoryProvider);
  return repository.getMeeting(id);
});
