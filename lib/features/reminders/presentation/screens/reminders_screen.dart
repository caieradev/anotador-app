import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/reminder.dart';
import '../../providers/reminders_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembretes'),
        centerTitle: true,
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: theme.colorScheme.error),
              const SizedBox(height: 16),
              const Text('Erro ao carregar lembretes'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(remindersProvider.notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum lembrete',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seus lembretes aparecerao aqui.',
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

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(remindersProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return _ReminderTile(reminder: reminders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat("dd/MM/yyyy 'as' HH:mm", 'pt_BR');
    final isDismissed = reminder.status == 'dismissed';
    final isSent = reminder.status == 'sent';
    final isPending = reminder.status == 'pending';

    final (statusIcon, statusColor) = switch (reminder.status) {
      'pending' => (Icons.schedule, Colors.orange),
      'sent' => (Icons.check_circle, Colors.green),
      'dismissed' => (Icons.cancel, Colors.grey),
      _ => (Icons.notifications, Colors.blue),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          reminder.message,
          style: TextStyle(
            decoration: isDismissed ? TextDecoration.lineThrough : null,
            color: isDismissed ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.meetingTitle != null)
              Text(
                reminder.meetingTitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            Text(
              dateFormat.format(reminder.remindAt.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: (isPending || isSent)
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Dispensar',
                onPressed: () {
                  ref
                      .read(remindersProvider.notifier)
                      .dismiss(reminder.id);
                },
              )
            : null,
        isThreeLine: reminder.meetingTitle != null,
      ),
    );
  }
}
