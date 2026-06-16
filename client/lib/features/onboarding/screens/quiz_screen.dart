import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/onboarding_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late PageController _pageController;
  late List<TextEditingController> _customAnswerControllers;
  int _localQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _customAnswerControllers = List.generate(
      quizQuestions.length,
      (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _customAnswerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildIntroScreen(BuildContext context, OnboardingState state, OnboardingNotifier notifier) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    return Scaffold(
      backgroundColor: isDarkMode ? LuminaColors.backgroundDark : LuminaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl, vertical: LuminaSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: LuminaSpacing.xl),
              
              Center(
                child: SvgPicture.asset(
                  'assets/lumina_logo_clean.svg',
                  width: 100,
                  height: 100,
                ),
              ),
              
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "I want to know you before we talk.",
                    style: GoogleFonts.lora(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LuminaSpacing.md),
                  Text(
                    "Calibration helps me adapt my companion archetype and tone to suit your vibe. Would you like to take a short 4-question personality quiz?",
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: secondaryTextColor,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LuminaSpacing.md),
                      child: Text(
                        state.errorMessage!,
                        style: GoogleFonts.dmSans(
                          color: LuminaColors.accentRed,
                          fontSize: LuminaTypography.sizeBody,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              notifier.startQuiz();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LuminaColors.accentAmber,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Bring it on"),
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.md),
                  
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              try {
                                await notifier.skipQuiz();
                                if (context.mounted) {
                                  context.go('/onboarding/name');
                                }
                              } catch (e) {
                                debugPrint("Error skipping quiz: $e");
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTextColor,
                        side: const BorderSide(color: LuminaColors.divider, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LuminaRadius.button),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(LuminaColors.accentAmber),
                              ),
                            )
                          : const Text("I'm not ready"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);

    if (!onboardingState.isIntroCompleted) {
      return _buildIntroScreen(context, onboardingState, onboardingNotifier);
    }

    final totalQuestions = quizQuestions.length;
    final progress = (_localQuestionIndex + 1) / totalQuestions;
    
    // Sync state index changes with PageView controller
    if (onboardingState.currentQuestionIndex != _localQuestionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            onboardingState.currentQuestionIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        setState(() {
          _localQuestionIndex = onboardingState.currentQuestionIndex;
        });
      });
    }

    // Sync controllers with state
    for (int i = 0; i < totalQuestions; i++) {
      final storedAnswer = (i == onboardingState.currentQuestionIndex)
          ? (onboardingState.selectedAnswerForCurrentQuestion ?? '')
          : (i < onboardingState.selectedAnswers.length ? onboardingState.selectedAnswers[i] : '');
      final question = quizQuestions[i];
      if (storedAnswer.isNotEmpty && !question.options.contains(storedAnswer)) {
        if (_customAnswerControllers[i].text.trim() != storedAnswer.trim()) {
          _customAnswerControllers[i].value = TextEditingValue(
            text: storedAnswer,
            selection: TextSelection.collapsed(offset: storedAnswer.length),
          );
        }
      } else {
        if (_customAnswerControllers[i].text.isNotEmpty) {
          _customAnswerControllers[i].clear();
        }
      }
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    final hasAnswer = onboardingState.selectedAnswerForCurrentQuestion != null &&
        onboardingState.selectedAnswerForCurrentQuestion!.trim().isNotEmpty;

    final physics = hasAnswer
        ? const ClampingScrollPhysics()
        : const BackwardOnlyScrollPhysics(parent: ClampingScrollPhysics());

    return Scaffold(
      backgroundColor: isDarkMode ? LuminaColors.backgroundDark : LuminaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 5,
              color: LuminaColors.divider.withValues(alpha: 0.3),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: MediaQuery.of(context).size.width * progress,
                height: 5,
                color: LuminaColors.accentAmber,
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuminaSpacing.xl,
                      vertical: LuminaSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "QUIZ",
                          style: GoogleFonts.dmSans(
                            fontSize: LuminaTypography.sizeCaption,
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.accentAmber,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          "${_localQuestionIndex + 1} / $totalQuestions",
                          style: GoogleFonts.dmSans(
                            fontSize: LuminaTypography.sizeCaption,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: (details) {
                          if (_localQuestionIndex == 0 &&
                              details.primaryVelocity != null &&
                              details.primaryVelocity! > 0) {
                            onboardingNotifier.goBackToIntro();
                          }
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          physics: physics,
                          itemCount: totalQuestions,
                          onPageChanged: (index) {
                            if (index == onboardingState.currentQuestionIndex) {
                              setState(() {
                                _localQuestionIndex = index;
                              });
                              return;
                            }
                            if (index < _localQuestionIndex) {
                              onboardingNotifier.previousQuestion();
                            } else {
                              onboardingNotifier.nextQuestion();
                            }
                            setState(() {
                              _localQuestionIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final question = quizQuestions[index];
                            return Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question.question,
                                        style: GoogleFonts.lora(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color: primaryTextColor,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: LuminaSpacing.xl),
                                      ...question.options.map((option) {
                                        final isSelected = (index == onboardingState.currentQuestionIndex)
                                            ? onboardingState.selectedAnswerForCurrentQuestion == option
                                            : (index < onboardingState.selectedAnswers.length && onboardingState.selectedAnswers[index] == option);
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: LuminaSpacing.md),
                                          child: OptionButton(
                                            text: option,
                                            isSelected: isSelected,
                                            onTap: () {
                                              _customAnswerControllers[index].clear();
                                              onboardingNotifier.selectOption(option);
                                            },
                                          ),
                                        );
                                      }),
                                      
                                      const SizedBox(height: LuminaSpacing.md),
                                      Text(
                                        "Or write your own answer:",
                                        style: GoogleFonts.dmSans(
                                          fontSize: LuminaTypography.sizeCaption,
                                          color: secondaryTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: LuminaSpacing.xs),
                                      TextField(
                                        controller: _customAnswerControllers[index],
                                        style: GoogleFonts.dmSans(
                                          fontSize: LuminaTypography.sizeBody,
                                          color: primaryTextColor,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Type your manual answer here...",
                                          prefixIcon: Icon(
                                            Icons.edit_note_rounded,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                        onChanged: (text) {
                                          if (text.trim().isNotEmpty) {
                                            onboardingNotifier.selectOption(text.trim());
                                          } else {
                                            onboardingNotifier.selectOption('');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LuminaSpacing.xl,
                        vertical: LuminaSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (onboardingState.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: LuminaSpacing.md),
                              child: Text(
                                onboardingState.errorMessage!,
                                style: GoogleFonts.dmSans(
                                  color: LuminaColors.accentRed,
                                  fontSize: LuminaTypography.sizeBody,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (onboardingState.selectedAnswerForCurrentQuestion == null || 
                                          onboardingState.selectedAnswerForCurrentQuestion!.trim().isEmpty || 
                                          onboardingState.isLoading)
                                  ? null
                                  : () async {
                                      final isLast = _localQuestionIndex == totalQuestions - 1;
                                      onboardingNotifier.nextQuestion();
                                      
                                      if (isLast && !onboardingState.isLoading) {
                                        context.go('/onboarding/name');
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LuminaColors.accentAmber,
                                disabledBackgroundColor: LuminaColors.disabled,
                              ),
                              child: onboardingState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _localQuestionIndex == totalQuestions - 1 ? "Calculate Vibe" : "Next Vibe",
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class OptionButton extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.04), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _bounceController.forward(from: 0.0);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: LuminaSpacing.md,
            vertical: LuminaSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? (isDarkMode ? LuminaColors.userBubbleDark : LuminaColors.userBubble)
                : (isDarkMode ? LuminaColors.surfaceDark : Colors.white),
            border: Border.all(
              color: widget.isSelected ? LuminaColors.accentGreen : LuminaColors.divider,
              width: widget.isSelected ? 1.5 : 0.8,
            ),
            borderRadius: BorderRadius.circular(LuminaRadius.button),
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.dmSans(
              fontSize: LuminaTypography.sizeBody,
              color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class BackwardOnlyScrollPhysics extends ScrollPhysics {
  const BackwardOnlyScrollPhysics({super.parent});

  @override
  BackwardOnlyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BackwardOnlyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // offset < 0 means dragging finger left (scrolling forward/right to next page)
    if (offset < 0) {
      return 0.0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // velocity < 0 means flinging forward/right
    if (velocity < 0) {
      return null;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

