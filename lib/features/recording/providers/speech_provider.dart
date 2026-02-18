import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechStatus { unavailable, available, listening }

class SpeechState {
  final SpeechStatus status;
  final String transcript;
  final String currentWords;
  final String selectedLocale;

  const SpeechState({
    this.status = SpeechStatus.unavailable,
    this.transcript = '',
    this.currentWords = '',
    this.selectedLocale = 'pt_BR',
  });

  String get displayText {
    if (currentWords.isNotEmpty) {
      if (transcript.isNotEmpty) {
        return '$transcript $currentWords';
      }
      return currentWords;
    }
    return transcript;
  }

  SpeechState copyWith({
    SpeechStatus? status,
    String? transcript,
    String? currentWords,
    String? selectedLocale,
  }) {
    return SpeechState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      currentWords: currentWords ?? this.currentWords,
      selectedLocale: selectedLocale ?? this.selectedLocale,
    );
  }
}

class SpeechNotifier extends StateNotifier<SpeechState> {
  final SpeechToText _speech;

  SpeechNotifier()
      : _speech = SpeechToText(),
        super(const SpeechState());

  Future<void> initialize() async {
    final available = await _speech.initialize(
      onError: (error) {
        // If we get a "no match" error while listening, restart listening
        if (error.errorMsg == 'error_no_match' &&
            state.status == SpeechStatus.listening) {
          _restartListening();
          return;
        }
        state = state.copyWith(status: SpeechStatus.available);
      },
      onStatus: (status) {
        if (status == 'done' && state.status == SpeechStatus.listening) {
          // Commit current words and restart listening
          _commitCurrentWords();
          _restartListening();
        }
      },
    );

    if (available) {
      state = state.copyWith(status: SpeechStatus.available);
    }
  }

  void setLocale(String locale) {
    state = state.copyWith(selectedLocale: locale);
  }

  Future<void> startListening() async {
    if (state.status == SpeechStatus.unavailable) return;

    state = state.copyWith(
      status: SpeechStatus.listening,
      currentWords: '',
    );

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: state.selectedLocale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    if (result.finalResult) {
      final newTranscript = state.transcript.isEmpty
          ? result.recognizedWords
          : '${state.transcript} ${result.recognizedWords}';
      state = state.copyWith(
        transcript: newTranscript,
        currentWords: '',
      );
    } else {
      state = state.copyWith(currentWords: result.recognizedWords);
    }
  }

  void _commitCurrentWords() {
    if (state.currentWords.isNotEmpty) {
      final newTranscript = state.transcript.isEmpty
          ? state.currentWords
          : '${state.transcript} ${state.currentWords}';
      state = state.copyWith(
        transcript: newTranscript,
        currentWords: '',
      );
    }
  }

  Future<void> _restartListening() async {
    if (!mounted) return;
    if (state.status != SpeechStatus.listening) return;

    // Small delay before restarting
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted || state.status != SpeechStatus.listening) return;

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: state.selectedLocale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    _commitCurrentWords();
    await _speech.stop();
    if (mounted) {
      state = state.copyWith(status: SpeechStatus.available);
    }
  }

  void reset() {
    _speech.stop();
    state = const SpeechState();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

final speechProvider =
    StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  return SpeechNotifier();
});
