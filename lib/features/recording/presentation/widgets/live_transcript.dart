import 'package:flutter/material.dart';

class LiveTranscript extends StatefulWidget {
  final String text;

  const LiveTranscript({super.key, required this.text});

  @override
  State<LiveTranscript> createState() => _LiveTranscriptState();
}

class _LiveTranscriptState extends State<LiveTranscript> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LiveTranscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = widget.text.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: isEmpty
          ? Center(
              child: Text(
                'Comece a gravar para ver a transcricao...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                widget.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
    );
  }
}
