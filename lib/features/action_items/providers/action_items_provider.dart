import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../domain/models/action_item.dart';

class ActionItemsNotifier extends StateNotifier<AsyncValue<List<ActionItem>>> {
  final Ref _ref;

  ActionItemsNotifier(this._ref) : super(const AsyncLoading()) {
    _loadActionItems();
  }

  Future<void> _loadActionItems() async {
    try {
      state = const AsyncLoading();
      final client = _ref.read(supabaseProvider);
      final response = await client
          .from('action_items')
          .select('*, meetings(title)')
          .order('created_at', ascending: false);
      final items = (response as List)
          .map((json) => ActionItem.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleStatus(String itemId) async {
    final currentItems = state.valueOrNull;
    if (currentItems == null) return;

    final item = currentItems.firstWhere((i) => i.id == itemId);
    final newStatus = item.status == 'pending' ? 'done' : 'pending';

    // Optimistic update
    final updatedItems = currentItems.map((i) {
      return i.id == itemId ? i.copyWith(status: newStatus) : i;
    }).toList();
    state = AsyncData(updatedItems);

    try {
      final client = _ref.read(supabaseProvider);
      await client
          .from('action_items')
          .update({'status': newStatus}).eq('id', itemId);
    } catch (e) {
      // Revert on error
      state = AsyncData(currentItems);
    }
  }

  Future<void> refresh() async {
    await _loadActionItems();
  }
}

final actionItemsProvider =
    StateNotifierProvider<ActionItemsNotifier, AsyncValue<List<ActionItem>>>(
        (ref) {
  return ActionItemsNotifier(ref);
});

/// Filtered action items by status
final filteredActionItemsProvider =
    Provider.family<AsyncValue<List<ActionItem>>, String?>((ref, filter) {
  final items = ref.watch(actionItemsProvider);
  return items.whenData((list) {
    if (filter == null || filter == 'all') return list;
    return list.where((item) => item.status == filter).toList();
  });
});

/// Action items for a specific meeting
final meetingActionItemsProvider =
    Provider.family<AsyncValue<List<ActionItem>>, String>((ref, meetingId) {
  final items = ref.watch(actionItemsProvider);
  return items.whenData((list) {
    return list.where((item) => item.meetingId == meetingId).toList();
  });
});
