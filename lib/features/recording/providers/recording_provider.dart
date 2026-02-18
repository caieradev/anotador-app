import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../meetings/data/repositories/meeting_repository.dart';
import '../../meetings/domain/models/meeting.dart';

enum RecordingStatus { idle, recording, paused, stopped, uploading, error }

class RecordingState {
  final RecordingStatus status;
  final int elapsedSeconds;
  final String meetingType;
  final String? meetingId;
  final String? errorMessage;
  final Meeting? meeting;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.elapsedSeconds = 0,
    this.meetingType = 'presential',
    this.meetingId,
    this.errorMessage,
    this.meeting,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    int? elapsedSeconds,
    String? meetingType,
    String? meetingId,
    String? errorMessage,
    Meeting? meeting,
  }) {
    return RecordingState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      meetingType: meetingType ?? this.meetingType,
      meetingId: meetingId ?? this.meetingId,
      errorMessage: errorMessage ?? this.errorMessage,
      meeting: meeting ?? this.meeting,
    );
  }
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  final AudioRecorder _recorder;
  final MeetingRepository _meetingRepository;
  final Ref _ref;
  Timer? _timer;
  String? _filePath;

  RecordingNotifier(this._meetingRepository, this._ref)
      : _recorder = AudioRecorder(),
        super(const RecordingState());

  void setMeetingType(String type) {
    if (state.status == RecordingStatus.idle) {
      state = state.copyWith(meetingType: type);
    }
  }

  Future<void> startRecording({String? language}) async {
    try {
      debugPrint('[Recording] Requesting mic permission...');
      final hasPermission = await _recorder.hasPermission();
      debugPrint('[Recording] Mic permission: $hasPermission');
      if (!hasPermission) {
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Permissao de microfone negada',
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final id = const Uuid().v4();
      _filePath = '${tempDir.path}/recording_$id.m4a';
      debugPrint('[Recording] File path: $_filePath');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _filePath!,
      );
      debugPrint('[Recording] Recorder started');

      // Create meeting in Supabase
      final user = _ref.read(currentUserProvider);
      debugPrint('[Recording] User: ${user?.id}');
      if (user != null) {
        final meeting = await _meetingRepository.createMeeting(
          userId: user.id,
          type: state.meetingType,
          language: language,
        );
        debugPrint('[Recording] Meeting created: ${meeting.id}');
        state = state.copyWith(
          status: RecordingStatus.recording,
          elapsedSeconds: 0,
          meetingId: meeting.id,
          meeting: meeting,
        );
      } else {
        debugPrint('[Recording] WARNING: No user logged in!');
        state = state.copyWith(
          status: RecordingStatus.recording,
          elapsedSeconds: 0,
        );
      }

      _startTimer();
    } catch (e, st) {
      debugPrint('[Recording] ERROR startRecording: $e');
      debugPrint('[Recording] Stack: $st');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Erro ao iniciar gravacao: $e',
      );
    }
  }

  Future<void> stopRecording({String? rawTranscript}) async {
    try {
      debugPrint('[Recording] Stopping recording...');
      _stopTimer();
      final path = await _recorder.stop();
      debugPrint('[Recording] Recorder stopped, path: $path');
      state = state.copyWith(status: RecordingStatus.stopped);

      if (path != null && state.meetingId != null) {
        state = state.copyWith(status: RecordingStatus.uploading);
        debugPrint('[Recording] Uploading audio for meeting: ${state.meetingId}');

        final user = _ref.read(currentUserProvider);
        if (user != null) {
          // Read audio file
          final file = File(path);
          final audioData = await file.readAsBytes();
          debugPrint('[Recording] Audio file size: ${audioData.length} bytes');

          // Upload audio to Supabase Storage
          final storagePath = await _meetingRepository.uploadAudio(
            user.id,
            state.meetingId!,
            audioData,
            'm4a',
          );
          debugPrint('[Recording] Uploaded to storage: $storagePath');

          // Update meeting with audio URL, transcript, and status
          final updateData = <String, dynamic>{
            'audio_url': storagePath,
            'ended_at': DateTime.now().toIso8601String(),
            'duration_seconds': state.elapsedSeconds,
            'status': 'processing',
          };

          if (rawTranscript != null && rawTranscript.isNotEmpty) {
            updateData['raw_transcript'] = rawTranscript;
            debugPrint('[Recording] Raw transcript length: ${rawTranscript.length}');
          }

          await _meetingRepository.updateMeeting(
            state.meetingId!,
            updateData,
          );
          debugPrint('[Recording] Meeting updated to processing');

          // Trigger backend processing (fire-and-forget)
          _triggerProcessing(state.meetingId!);

          // Clean up temp file
          if (await file.exists()) {
            await file.delete();
            debugPrint('[Recording] Temp file cleaned up');
          }
        }

        state = state.copyWith(status: RecordingStatus.stopped);
        debugPrint('[Recording] Done!');
      }
    } catch (e, st) {
      debugPrint('[Recording] ERROR stopRecording: $e');
      debugPrint('[Recording] Stack: $st');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Erro ao parar gravacao: $e',
      );
    }
  }

  Future<void> _triggerProcessing(String meetingId) async {
    try {
      final url = '${AppConstants.backendUrl}/api/meetings/$meetingId/process';
      debugPrint('[Recording] Triggering backend: $url');
      final response = await http.post(Uri.parse(url));
      debugPrint('[Recording] Backend response: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[Recording] ERROR triggering backend: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _stopTimer();
    state = const RecordingState();
  }

  @override
  void dispose() {
    _stopTimer();
    _recorder.dispose();
    super.dispose();
  }
}

final recordingProvider =
    StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  final meetingRepo = ref.watch(meetingRepositoryProvider);
  return RecordingNotifier(meetingRepo, ref);
});
