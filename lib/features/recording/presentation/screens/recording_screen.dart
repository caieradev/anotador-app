import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recording_provider.dart';
import '../../providers/speech_provider.dart';
import '../widgets/live_transcript.dart';
import '../widgets/recording_controls.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize speech recognition
    Future.microtask(() {
      ref.read(speechProvider.notifier).initialize();
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    final speechNotifier = ref.read(speechProvider.notifier);
    final recordingNotifier = ref.read(recordingProvider.notifier);
    final speechState = ref.read(speechProvider);

    await recordingNotifier.startRecording(language: speechState.selectedLocale);
    await speechNotifier.startListening();
  }

  Future<void> _stopRecording() async {
    final speechNotifier = ref.read(speechProvider.notifier);
    final recordingNotifier = ref.read(recordingProvider.notifier);

    await speechNotifier.stopListening();

    final transcript = ref.read(speechProvider).transcript;
    await recordingNotifier.stopRecording(rawTranscript: transcript);

    if (!mounted) return;

    final recordingState = ref.read(recordingProvider);
    if (recordingState.meetingId != null) {
      // Navigate to meeting detail
      context.go('/meeting/${recordingState.meetingId}');
    }

    // Reset providers for next recording
    recordingNotifier.reset();
    speechNotifier.reset();
    // Re-initialize speech for next use
    await ref.read(speechProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final speechState = ref.watch(speechProvider);
    final theme = Theme.of(context);
    final isRecording = recordingState.status == RecordingStatus.recording;
    final isUploading = recordingState.status == RecordingStatus.uploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gravar'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Meeting type selector
              _MeetingTypeSelector(
                selectedType: recordingState.meetingType,
                enabled: recordingState.status == RecordingStatus.idle,
                onTypeChanged: (type) {
                  ref.read(recordingProvider.notifier).setMeetingType(type);
                },
              ),
              const SizedBox(height: 32),

              // Timer display
              Text(
                _formatTime(recordingState.elapsedSeconds),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),

              // Status text
              Text(
                _statusText(recordingState.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _statusColor(recordingState.status, theme),
                ),
              ),
              const SizedBox(height: 24),

              // Live transcript
              Expanded(
                child: LiveTranscript(text: speechState.displayText),
              ),
              const SizedBox(height: 24),

              // Recording controls
              if (isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Enviando gravacao...'),
                  ],
                )
              else
                RecordingControls(
                  isRecording: isRecording,
                  onRecord: _startRecording,
                  onStop: _stopRecording,
                ),

              // Error message
              if (recordingState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  recordingState.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(RecordingStatus status) {
    return switch (status) {
      RecordingStatus.idle => 'Toque para gravar',
      RecordingStatus.recording => 'Gravando...',
      RecordingStatus.paused => 'Pausado',
      RecordingStatus.stopped => 'Gravacao finalizada',
      RecordingStatus.uploading => 'Enviando...',
      RecordingStatus.error => 'Erro',
    };
  }

  Color _statusColor(RecordingStatus status, ThemeData theme) {
    return switch (status) {
      RecordingStatus.recording => Colors.red,
      RecordingStatus.error => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }
}

class _MeetingTypeSelector extends StatelessWidget {
  final String selectedType;
  final bool enabled;
  final ValueChanged<String> onTypeChanged;

  const _MeetingTypeSelector({
    required this.selectedType,
    required this.enabled,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'presential',
          icon: Icon(Icons.people),
          label: Text('Presencial'),
        ),
        ButtonSegment(
          value: 'online',
          icon: Icon(Icons.videocam),
          label: Text('Online'),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: enabled
          ? (selection) => onTypeChanged(selection.first)
          : null,
    );
  }
}
