import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/tts_provider.dart';

enum OrbState {
  listening,
  thinking,
  speaking,
}

class LiveVoiceOverlay extends ConsumerStatefulWidget {
  const LiveVoiceOverlay({super.key});

  @override
  ConsumerState<LiveVoiceOverlay> createState() => _LiveVoiceOverlayState();
}

class _LiveVoiceOverlayState extends ConsumerState<LiveVoiceOverlay> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  OrbState _orbState = OrbState.listening;
  String _statusText = "Tap or talk to start";
  String _userTranscript = "";
  String _aiResponseText = "";
  double _soundLevel = 0.0;
  
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initVoiceSystem();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _speech.stop();
    // Ensure TTS stops when exiting voice mode
    ref.read(ttsProvider).stop();
    super.dispose();
  }

  Future<void> _initVoiceSystem() async {
    try {
      final tts = ref.read(ttsProvider);
      tts.setCompletionHandler(() {
        if (mounted && _orbState == OrbState.speaking) {
          _startListening();
        }
      });
      tts.setErrorHandler((err) {
        debugPrint("TTS Voice Mode Error: $err");
        if (mounted) _startListening();
      });

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted && _orbState == OrbState.listening) {
              _processListeningDone();
            }
          }
        },
        onError: (err) {
          debugPrint("STT Voice Mode Error: $err");
          if (mounted) {
            setState(() {
              _statusText = "Didn't catch that. Tap to talk.";
              _orbState = OrbState.listening;
            });
            _pulseController.stop();
          }
        }
      );

      if (available) {
        _speechInitialized = true;
        _startListening();
      } else {
        setState(() {
          _statusText = "Voice input unavailable on this device";
        });
      }
    } catch (e) {
      debugPrint("Voice mode initialization exception: $e");
      setState(() {
        _statusText = "Permission denied or mic initialization failed";
      });
    }
  }

  void _startListening() async {
    if (!_speechInitialized) return;
    
    ref.read(ttsProvider).stop();

    setState(() {
      _orbState = OrbState.listening;
      _statusText = "Listening...";
      _userTranscript = "";
    });

    _pulseController.duration = const Duration(milliseconds: 1500);
    _pulseController.repeat(reverse: true);
    _rotateController.duration = const Duration(seconds: 10);
    _rotateController.repeat();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _userTranscript = result.recognizedWords;
        });
      },
      onSoundLevelChange: (level) {
        if (mounted) {
          setState(() {
            _soundLevel = level;
          });
        }
      },
    );
  }

  void _processListeningDone() {
    if (_userTranscript.trim().isNotEmpty) {
      _sendAndSpeak(_userTranscript.trim());
    } else {
      _startListening();
    }
  }

  Future<void> _sendAndSpeak(String text) async {
    await _speech.stop();
    
    setState(() {
      _orbState = OrbState.thinking;
      _statusText = "Thinking...";
      _aiResponseText = "";
      _soundLevel = 0.0;
    });

    _pulseController.duration = const Duration(milliseconds: 600);
    _pulseController.repeat(reverse: true);
    _rotateController.duration = const Duration(milliseconds: 1500);
    _rotateController.repeat();

    try {
      await ref.read(chatProvider.notifier).sendMessage(text);
      
      final messages = ref.read(chatProvider).messages;
      if (messages.isNotEmpty && messages.last.role == 'assistant') {
        final replyText = messages.last.content;
        _speakReply(replyText);
      } else {
        _startListening();
      }
    } catch (e) {
      debugPrint("Failed to fetch response: $e");
      _startListening();
    }
  }

  void _speakReply(String replyText) {
    setState(() {
      _orbState = OrbState.speaking;
      _statusText = "";
      _aiResponseText = replyText;
    });

    _pulseController.duration = const Duration(milliseconds: 800);
    _pulseController.repeat(reverse: true);
    _rotateController.duration = const Duration(seconds: 5);
    _rotateController.repeat();

    ref.read(ttsProvider).speak(replyText);
  }

  void _handleUserInterrupt() {
    HapticFeedback.lightImpact();
    ref.read(ttsProvider).stop();
    _speech.stop();
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    final aiName = ref.watch(settingsProvider).aiName;
    
    // Glowing color scheme corresponding to current state
    Color glowColor;
    switch (_orbState) {
      case OrbState.listening:
        glowColor = const Color(0xFF6B8F5E); // Sage green pulse
        break;
      case OrbState.thinking:
        glowColor = const Color(0xFF8B5CF6); // Deep purple
        break;
      case OrbState.speaking:
        glowColor = LuminaColors.accentAmber; // Amber gold
        break;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xFF0C0C0F).withValues(alpha: 0.85),
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LuminaSpacing.md,
                    vertical: LuminaSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        "$aiName Live",
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 44), // Alignment spacing
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Central Glowing Orb (Tap to Interrupt / Talk)
                GestureDetector(
                  onTap: _handleUserInterrupt,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Layer 1: Glowing soft blur shadow back layer
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 140 * _pulseAnimation.value,
                            height: 140 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withAlpha(102),
                                  blurRadius: 40 * _pulseAnimation.value,
                                  spreadRadius: 10 * _pulseAnimation.value,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // Layer 2: Rotating gradient mesh ring
                      RotationTransition(
                        turns: _rotateController,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                glowColor.withAlpha(0),
                                glowColor.withAlpha(153),
                                glowColor,
                                glowColor.withAlpha(51),
                                glowColor.withAlpha(0),
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      // Layer 3: Main inner orb circle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              glowColor.withAlpha(230),
                              glowColor.withAlpha(102),
                              const Color(0xFF16161A),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          border: Border.all(
                            color: glowColor.withAlpha(76),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _orbState == OrbState.listening 
                                ? Icons.mic 
                                : (_orbState == OrbState.thinking ? Icons.autorenew : Icons.volume_up),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Interactive status and live text readout panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
                  child: Column(
                    children: [
                      if (_statusText.isNotEmpty)
                        Text(
                          _statusText,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: LuminaSpacing.md),
                      
                      // User live transcription
                      if (_orbState == OrbState.listening && _userTranscript.isNotEmpty)
                        Text(
                          _userTranscript,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      
                      // Companion spoken text output
                      if (_orbState == OrbState.speaking && _aiResponseText.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            child: Text(
                              _aiResponseText,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // Dynamic Audio Waveform Visualizer
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: VoiceWaveformPainter(
                          soundLevel: _soundLevel,
                          time: DateTime.now().millisecondsSinceEpoch / 1000.0,
                          color: glowColor,
                          state: _orbState,
                        ),
                      );
                    },
                  ),
                ),
                
                const Spacer(),
                
                // Subtitle hint
                Text(
                  "Tap the orb to interrupt at any time",
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white30,
                  ),
                ),
                const SizedBox(height: LuminaSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VoiceWaveformPainter extends CustomPainter {
  final double soundLevel;
  final double time;
  final Color color;
  final OrbState state;

  VoiceWaveformPainter({
    required this.soundLevel,
    required this.time,
    required this.color,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double midY = size.height / 2;
    final double width = size.width;

    double amplitude = 0.0;
    if (state == OrbState.listening) {
      // Scale standard STT decibels (-2.0 to 10.0) to graphic height
      amplitude = ((soundLevel + 2.0).clamp(0.0, 12.0) / 12.0) * 38.0;
    } else if (state == OrbState.thinking) {
      amplitude = 5.0 + sin(time * 5.0) * 2.5;
    } else if (state == OrbState.speaking) {
      amplitude = 12.0 + sin(time * 8.0) * 10.0;
    }

    final List<double> phases = [0.0, 1.3, 2.6];
    final List<double> frequencies = [0.015, 0.024, 0.018];
    final List<double> opacities = [0.22, 0.12, 0.18];

    for (int i = 0; i < 3; i++) {
      final path = Path();
      paint.color = color.withValues(alpha: opacities[i]);
      
      path.moveTo(0, midY);

      for (double x = 0; x <= width; x += 4) {
        // Bell curve envelope so waves fade cleanly to 0 at edges
        final double envelope = sin((x / width) * pi);
        final double y = midY + sin(x * frequencies[i] + time * 5.5 + phases[i]) * amplitude * envelope;
        path.lineTo(x, y);
      }

      path.lineTo(width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWaveformPainter oldDelegate) => true;
}

