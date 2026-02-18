import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../../action_items/providers/action_items_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/models/meeting.dart';
import '../../providers/meetings_provider.dart';

class MeetingDetailScreen extends ConsumerStatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _notesController = TextEditingController();
  final _audioPlayer = AudioPlayer();
  bool _notesModified = false;
  bool _audioInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initAudio(Meeting meeting) async {
    if (_audioInitialized || meeting.audioUrl == null) return;
    _audioInitialized = true;

    try {
      final client = ref.read(supabaseProvider);
      final signedUrl = await client.storage
          .from('meeting-audio')
          .createSignedUrl(meeting.audioUrl!, 3600);
      await _audioPlayer.setUrl(signedUrl);
    } catch (e) {
      debugPrint('Erro ao carregar audio: $e');
    }
  }

  String? _noteId;
  bool _notesLoaded = false;

  Future<void> _loadNotes() async {
    if (_notesLoaded) return;
    _notesLoaded = true;

    try {
      final client = ref.read(supabaseProvider);
      final response = await client
          .from('notes')
          .select()
          .eq('meeting_id', widget.meetingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _noteId = response['id'] as String;
        _notesController.text = response['content'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Erro ao carregar notas: $e');
    }
  }

  Future<void> _saveNotes() async {
    if (!_notesModified) return;

    try {
      final client = ref.read(supabaseProvider);

      if (_noteId != null) {
        await client.from('notes').update({
          'content': _notesController.text,
        }).eq('id', _noteId!);
      } else {
        final response = await client.from('notes').insert({
          'meeting_id': widget.meetingId,
          'content': _notesController.text,
        }).select().single();
        _noteId = response['id'] as String;
      }

      _notesModified = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notas salvas'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar notas: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDetailProvider(widget.meetingId));
    final theme = Theme.of(context);

    return meetingAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Reuniao')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Reuniao')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar reuniao', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(meetingDetailProvider(widget.meetingId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (meeting) {
        _initAudio(meeting);
        _loadNotes();

        return Scaffold(
          appBar: AppBar(
            title: Text(meeting.title ?? 'Sem titulo'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Resumo'),
                Tab(text: 'Transcricao'),
                Tab(text: 'Acoes'),
                Tab(text: 'Notas'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Processing indicator
              if (meeting.status == 'processing')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Processando reuniao...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SummaryTab(meeting: meeting),
                    _TranscriptTab(meeting: meeting),
                    _ActionsTab(meetingId: widget.meetingId),
                    _NotesTab(
                      meeting: meeting,
                      controller: _notesController,
                      onChanged: () => _notesModified = true,
                      onSave: _saveNotes,
                    ),
                  ],
                ),
              ),

              // Audio player
              if (meeting.audioUrl != null)
                _AudioPlayerBar(player: _audioPlayer),
            ],
          ),
        );
      },
    );
  }
}

// --- Summary Tab ---

class _SummaryTab extends StatelessWidget {
  final Meeting meeting;

  const _SummaryTab({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat("d 'de' MMMM 'de' yyyy, HH:mm", 'pt_BR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary text
          if (meeting.summary != null && meeting.summary!.isNotEmpty) ...[
            Text(
              'Resumo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meeting.summary!,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.summarize_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meeting.status == 'processing'
                        ? 'O resumo esta sendo gerado...'
                        : 'Resumo nao disponivel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Meeting info
          Text(
            'Informacoes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.calendar_today,
            label: 'Data',
            value: dateFormat.format(meeting.startedAt.toLocal()),
          ),
          if (meeting.durationSeconds != null)
            _InfoTile(
              icon: Icons.timer,
              label: 'Duracao',
              value: _formatDuration(meeting.durationSeconds!),
            ),
          _InfoTile(
            icon: meeting.type == 'online' ? Icons.videocam : Icons.people,
            label: 'Tipo',
            value: meeting.type == 'online' ? 'Online' : 'Presencial',
          ),
          if (meeting.language != null)
            _InfoTile(
              icon: Icons.language,
              label: 'Idioma',
              value: meeting.language!,
            ),
          _InfoTile(
            icon: Icons.info_outline,
            label: 'Status',
            value: _statusLabel(meeting.status),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    if (minutes > 0) return '${minutes}min ${seconds}s';
    return '${seconds}s';
  }

  String _statusLabel(String status) {
    return switch (status) {
      'recording' => 'Gravando',
      'processing' => 'Processando',
      'completed' => 'Concluido',
      'failed' => 'Erro no processamento',
      _ => status,
    };
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Transcript Tab ---

class _TranscriptTab extends StatelessWidget {
  final Meeting meeting;

  const _TranscriptTab({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transcript = meeting.refinedTranscript ?? meeting.rawTranscript;

    if (transcript == null || transcript.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.text_snippet_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                meeting.status == 'processing'
                    ? 'A transcricao esta sendo processada...'
                    : 'Transcricao nao disponivel',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meeting.refinedTranscript == null &&
              meeting.rawTranscript != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Transcricao bruta (a versao refinada sera gerada em breve)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ),
          SelectableText(
            transcript,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Actions Tab ---

class _ActionsTab extends ConsumerWidget {
  final String meetingId;

  const _ActionsTab({required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(meetingActionItemsProvider(meetingId));
    final theme = Theme.of(context);

    return actionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro: $error')),
      data: (actions) {
        if (actions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma acao identificada',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final isDone = action.status == 'done';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: isDone,
                onChanged: (_) {
                  ref
                      .read(actionItemsProvider.notifier)
                      .toggleStatus(action.id);
                },
                title: Text(
                  action.description,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                subtitle: action.assignee != null
                    ? Text(action.assignee!)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          },
        );
      },
    );
  }
}

// --- Notes Tab ---

class _NotesTab extends StatefulWidget {
  final Meeting meeting;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  const _NotesTab({
    required this.meeting,
    required this.controller,
    required this.onChanged,
    required this.onSave,
  });

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Adicione suas notas aqui...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save),
              label: const Text('Salvar notas'),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Audio Player Bar ---

class _AudioPlayerBar extends StatefulWidget {
  final AudioPlayer player;

  const _AudioPlayerBar({required this.player});

  @override
  State<_AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<_AudioPlayerBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Play/Pause button
            StreamBuilder<PlayerState>(
              stream: widget.player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final playing = playerState?.playing ?? false;
                final processingState = playerState?.processingState;

                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: Icon(
                    playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    if (playing) {
                      widget.player.pause();
                    } else {
                      widget.player.play();
                    }
                  },
                );
              },
            ),

            // Seek bar
            Expanded(
              child: StreamBuilder<Duration?>(
                stream: widget.player.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;

                  return StreamBuilder<Duration>(
                    stream: widget.player.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              min: 0,
                              max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                              value: position.inMilliseconds
                                  .toDouble()
                                  .clamp(0, duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                              onChanged: (value) {
                                widget.player.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
