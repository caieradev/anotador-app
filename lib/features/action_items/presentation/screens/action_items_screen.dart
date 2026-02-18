import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/action_item.dart';
import '../../providers/action_items_provider.dart';

class ActionItemsScreen extends ConsumerStatefulWidget {
  const ActionItemsScreen({super.key});

  @override
  ConsumerState<ActionItemsScreen> createState() => _ActionItemsScreenState();
}

class _ActionItemsScreenState extends ConsumerState<ActionItemsScreen> {
  String _filter = 'all'; // 'all', 'pending', 'done'

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredActionItemsProvider(
      _filter == 'all' ? null : _filter,
    ));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acoes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _filter == 'all',
                  onSelected: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pendentes',
                  selected: _filter == 'pending',
                  onSelected: () => setState(() => _filter = 'pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Concluidos',
                  selected: _filter == 'done',
                  onSelected: () => setState(() => _filter = 'done'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48,
                        color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar acoes'),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.read(actionItemsProvider.notifier).refresh(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(filter: _filter);
                }

                // Group by meeting
                final grouped = <String, List<ActionItem>>{};
                for (final item in items) {
                  final key = item.meetingTitle ?? 'Sem titulo';
                  grouped.putIfAbsent(key, () => []).add(item);
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(actionItemsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return _MeetingActionGroup(
                        meetingTitle: entry.key,
                        items: entry.value,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _MeetingActionGroup extends ConsumerWidget {
  final String meetingTitle;
  final List<ActionItem> items;

  const _MeetingActionGroup({
    required this.meetingTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            meetingTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) {
          final isDone = item.status == 'done';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: CheckboxListTile(
              value: isDone,
              onChanged: (_) {
                ref.read(actionItemsProvider.notifier).toggleStatus(item.id);
              },
              title: Text(
                item.description,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              subtitle: _buildSubtitle(item, theme, dateFormat),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }),
      ],
    );
  }

  Widget? _buildSubtitle(
      ActionItem item, ThemeData theme, DateFormat dateFormat) {
    final parts = <String>[];
    if (item.assignee != null) parts.add(item.assignee!);
    if (item.dueDate != null) {
      parts.add('Vence: ${dateFormat.format(item.dueDate!)}');
    }
    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final message = switch (filter) {
      'pending' => 'Nenhuma acao pendente',
      'done' => 'Nenhuma acao concluida',
      _ => 'Nenhuma acao encontrada',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As acoes serao extraidas automaticamente das suas reunioes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
