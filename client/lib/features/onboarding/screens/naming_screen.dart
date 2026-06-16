import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/onboarding_provider.dart';

class NamingScreen extends ConsumerStatefulWidget {
  const NamingScreen({super.key});

  @override
  ConsumerState<NamingScreen> createState() => _NamingScreenState();
}

class _NamingScreenState extends ConsumerState<NamingScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: LuminaSpacing.xxl),
              
              // Centered prompt
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Before we start...",
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.sm),
                  Text(
                    "What do you want to call me?",
                    style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LuminaSpacing.xxl),
                  
                  // Pill shaped text field
                  TextField(
                    controller: _nameController,
                    maxLength: 20,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Nova, Arlo, Sage...",
                      counterText: "", // hide character count text below
                      filled: true,
                      fillColor: isDarkMode ? LuminaColors.surfaceDark : LuminaColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(LuminaRadius.input),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      onboardingNotifier.updateCompanionName(val);
                    },
                  ),
                ],
              ),
              
              // Bottom continue action
              Padding(
                padding: const EdgeInsets.only(bottom: LuminaSpacing.xl),
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
                        onPressed: (onboardingState.companionName.trim().length < 3 || onboardingState.isLoading)
                            ? null
                            : () async {
                                try {
                                  await onboardingNotifier.finalizeOnboarding();
                                  if (context.mounted) {
                                    context.go('/chat');
                                  }
                                } catch (e) {
                                  debugPrint("Onboarding finalize failed: $e");
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Let's go",
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: LuminaTypography.sizeBodyLarge,
                                    ),
                                  ),
                                  const SizedBox(width: LuminaSpacing.xs),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
