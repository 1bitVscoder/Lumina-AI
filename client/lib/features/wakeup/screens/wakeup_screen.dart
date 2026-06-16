import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/network.dart';
import '../../auth/providers/auth_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../settings/providers/settings_provider.dart';

class WakeupScreen extends ConsumerStatefulWidget {
  const WakeupScreen({super.key});

  @override
  ConsumerState<WakeupScreen> createState() => _WakeupScreenState();
}

class _WakeupScreenState extends ConsumerState<WakeupScreen> {
  late Timer _messageTimer;
  late Timer _pollingTimer;
  int _currentMessageIndex = 0;
  bool _isTimeout = false;
  final Stopwatch _stopwatch = Stopwatch();



  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _startMessageCycle();
    _startPolling();
  }

  @override
  void dispose() {
    _messageTimer.cancel();
    _pollingTimer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isTimeout) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % 4; // 4 messages total
        });
      }
    });
  }

  void _startPolling() {
    // Check backend health immediately on startup, then poll every 3 seconds
    _checkBackendHealth();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_stopwatch.elapsed.inSeconds >= 90) {
        if (mounted && !_isTimeout) {
          setState(() {
            _isTimeout = true;
          });
        }
      }
      _checkBackendHealth();
    });
  }

  Future<void> _checkBackendHealth() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/ping');
      if (response.statusCode == 200) {
        _pollingTimer.cancel();
        _messageTimer.cancel();
        if (mounted) {
          _navigateNext();
        }
      }
    } catch (_) {
      // Fail silently and retry on next interval
    }
  }

  void _navigateNext() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      context.go('/login');
    } else {
      final profile = ref.read(userProfileProvider);
      if (!profile.onboarded) {
        context.go('/onboarding/quiz');
      } else {
        context.go('/chat');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final aiName = settings.aiName;
    
    final List<String> loadingSubtitles = [
      "Hold on, they don't do mornings...",
      "Making coffee... probably.",
      "Give it a sec, almost there.",
      "$aiName is on their way.",
    ];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    final currentMessage = _isTimeout
        ? "Taking longer than usual... still trying."
        : loadingSubtitles[_currentMessageIndex % loadingSubtitles.length];

    return Scaffold(
      backgroundColor: isDarkMode ? LuminaColors.backgroundDark : LuminaColors.background,
      body: Stack(
        children: [
          // Centered Wakeup info
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$aiName is waking up...",
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LuminaSpacing.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      currentMessage,
                      key: ValueKey<String>(currentMessage),
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        color: _isTimeout ? LuminaColors.accentRed : secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.lg),
                  // Animated Dots Indicator (Sequential Fade)
                  const FadingDotsIndicator(),
                ],
              ),
            ),
          ),
          
          // Bottom message
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: LuminaSpacing.xl),
              child: Text(
                "This might take a minute on the free tier",
                style: GoogleFonts.dmSans(
                  fontSize: LuminaTypography.sizeCaption,
                  color: LuminaColors.textTimestamp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadingDotsIndicator extends StatefulWidget {
  const FadingDotsIndicator({super.key});

  @override
  State<FadingDotsIndicator> createState() => _FadingDotsIndicatorState();
}

class _FadingDotsIndicatorState extends State<FadingDotsIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimationCycle();
  }

  void _startAnimationCycle() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward().then((_) {
          if (mounted) {
            _controllers[i].reverse();
          }
        });
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return FadeTransition(
          opacity: _animations[index],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
