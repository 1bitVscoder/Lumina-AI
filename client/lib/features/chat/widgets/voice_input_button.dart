import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme.dart';

class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final VoidCallback? onListeningStarted;
  final VoidCallback? onListeningStopped;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onListeningStarted,
    this.onListeningStopped,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      _pulseController.stop();
      setState(() {
        _isListening = false;
      });
      widget.onListeningStopped?.call();
    } else {
      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              if (mounted && _isListening) {
                _pulseController.stop();
                setState(() {
                  _isListening = false;
                });
                widget.onListeningStopped?.call();
              }
            }
          },
          onError: (errorNotification) {
            debugPrint("SpeechToText Error: $errorNotification");
            if (mounted && _isListening) {
              _pulseController.stop();
              setState(() {
                _isListening = false;
              });
              widget.onListeningStopped?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Voice input error: ${errorNotification.errorMsg}")),
              );
            }
          },
        );

        if (available) {
          setState(() {
            _isListening = true;
          });
          _pulseController.repeat();
          widget.onListeningStarted?.call();
          
          await _speech.listen(
            onResult: (result) {
              widget.onResult(result.recognizedWords);
            },
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Voice recognition is not available on this device.")),
            );
          }
        }
      } catch (e) {
        debugPrint("SpeechToText Init Exception: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied or configuration error.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _isListening 
        ? LuminaColors.accentRed 
        : (isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isListening)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 38 + 24 * _pulseAnimation.value,
                height: 38 + 24 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LuminaColors.accentRed.withAlpha((76 * (1.0 - _pulseAnimation.value)).round()),
                ),
              );
            },
          ),
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none_outlined,
            color: iconColor,
            size: 22,
          ),
          onPressed: _toggleListening,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }
}
