import 'package:flutter/material.dart';

class RecordingControls extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onRecord;
  final VoidCallback onStop;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.onRecord,
    required this.onStop,
  });

  @override
  State<RecordingControls> createState() => _RecordingControlsState();
}

class _RecordingControlsState extends State<RecordingControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant RecordingControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isRecording) ...[
          // Stop button
          SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              heroTag: 'stop',
              onPressed: widget.onStop,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.stop_rounded,
                size: 32,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
        // Main record button
        ScaleTransition(
          scale: widget.isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          child: SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton.large(
              heroTag: 'record',
              onPressed: widget.isRecording ? widget.onStop : widget.onRecord,
              backgroundColor:
                  widget.isRecording ? Colors.red : colorScheme.primary,
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
