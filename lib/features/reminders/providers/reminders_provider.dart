import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../domain/models/reminder.dart';

class RemindersNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  final Ref _ref;

  RemindersNotifier(this._ref) : super(const AsyncLoading()) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      state = const AsyncLoading();
      final client = _ref.read(supabaseProvider);
      final user = _ref.read(supabaseProvider).auth.currentUser;
      if (user == null) {
        state = const AsyncData([]);
        return;
      }
      final response = await client
          .from('reminders')
          .select('*, meetings(title)')
          .eq('user_id', user.id)
          .order('remind_at', ascending: true);
      final items = (response as List)
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> dismiss(String reminderId) async {
    final currentItems = state.valueOrNull;
    if (currentItems == null) return;

    // Optimistic update
    final updatedItems = currentItems.map((r) {
      return r.id == reminderId ? r.copyWith(status: 'dismissed') : r;
    }).toList();
    state = AsyncData(updatedItems);

    try {
      final client = _ref.read(supabaseProvider);
      await client
          .from('reminders')
          .update({'status': 'dismissed'}).eq('id', reminderId);
    } catch (e) {
      // Revert on error
      state = AsyncData(currentItems);
    }
  }

  Future<void> refresh() async {
    await _loadReminders();
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, AsyncValue<List<Reminder>>>(
        (ref) {
  return RemindersNotifier(ref);
});
