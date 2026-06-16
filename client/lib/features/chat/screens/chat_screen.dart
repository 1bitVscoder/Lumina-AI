import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/rate_limit_banner.dart';
import '../widgets/typing_indicator.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import 'live_voice_overlay.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/ambient_particles.dart';
import '../widgets/entrance_transition.dart';
import '../../../shared/widgets/update_prompt_dialog.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  String _formatHeaderDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[dateTime.month - 1]} ${dateTime.day}";
    }
  }

  String _getCozyStatus(String aiName, String archetype, bool isTyping) {
    if (isTyping) {
      return "$aiName is typing...";
    }
    final hour = DateTime.now().hour;
    final arch = archetype.toLowerCase();

    if (hour >= 5 && hour < 12) {
      if (arch == 'jester') return "$aiName is cracking early jokes ☀️";
      if (arch == 'analyst') return "$aiName is plotting the day 📊";
      if (arch == 'venter') return "$aiName is brewing morning coffee ☕";
      return "$aiName is reading the morning news 📰";
    } else if (hour >= 12 && hour < 17) {
      if (arch == 'jester') return "$aiName is taking a quick nap 😴";
      if (arch == 'seeker') return "$aiName is deep in thought 💭";
      return "$aiName is working on projects 💻";
    } else if (hour >= 17 && hour < 21) {
      if (arch == 'venter') return "$aiName is brewing chamomile tea 🍵";
      if (arch == 'drifter') return "$aiName is winding down 🌇";
      return "$aiName is playing cozy games 🎮";
    } else {
      if (arch == 'seeker') return "$aiName is gazing at the stars 🌌";
      if (arch == 'drifter') return "$aiName is dreaming 🌙";
      return "$aiName is reading under blankets 📖";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final profile = ref.watch(userProfileProvider);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    return Container(
      color: isDarkMode ? LuminaColors.backgroundDark : LuminaColors.background,
      child: Stack(
        children: [
          // Background drift particle canvas
          const Positioned.fill(
            child: AmbientParticles(count: 22),
          ),
          
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: isDarkMode 
                  ? const GlassContainer(
                      blur: 16,
                      opacity: 0.15,
                      borderRadius: BorderRadius.zero,
                      border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 0.8)),
                      child: SizedBox.expand(),
                    )
                  : const GlassContainer(
                      blur: 16,
                      opacity: 0.45,
                      borderRadius: BorderRadius.zero,
                      border: Border(bottom: BorderSide(color: Color(0x0A000000), width: 0.8)),
                      child: SizedBox.expand(),
                    ),
              titleSpacing: 0,
              title: Row(
                children: [
                  const SizedBox(width: LuminaSpacing.sm), // breathing space from screen edge
                  // Gradient Mesh Avatar (No letters, organic look)
                  GradientMeshAvatar(
                    size: 36,
                    isThinking: chatState.isTyping,
                  ),
                  const SizedBox(width: LuminaSpacing.md),
                  
                  // Name & Status Subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.aiName,
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        _getCozyStatus(profile.aiName, profile.archetype, chatState.isTyping),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: chatState.isTyping ? LuminaColors.accentAmber : LuminaColors.accentGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.headset_mic_outlined),
                  onPressed: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierLabel: "LiveVoice",
                      barrierColor: Colors.black.withValues(alpha: 0.5),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return const LiveVoiceOverlay();
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        return FadeTransition(
                          opacity: anim1,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim1),
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    context.push('/settings');
                  },
                ),
                const SizedBox(width: LuminaSpacing.sm),
              ],
            ),
            body: Column(
              children: [
                // Message List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuminaSpacing.md,
                      vertical: LuminaSpacing.sm,
                    ),
                    reverse: true, // latest at bottom
                    itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // If typing indicator is active, it occupies the 0th item in reversed list
                      if (chatState.isTyping && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: TypingIndicator(),
                        );
                      }

                      // Adjust index if typing indicator is showing
                      final messageIndex = chatState.isTyping ? index - 1 : index;
                      // Reversed list mapping (index 0 is latest, length-1 is oldest)
                      final messages = chatState.messages.reversed.toList();
                      final message = messages[messageIndex];

                      // Determine date header placement
                      bool showDateHeader = false;
                      if (messageIndex == messages.length - 1) {
                        // Oldest item in list
                        showDateHeader = true;
                      } else {
                        final nextOlderMessage = messages[messageIndex + 1];
                        if (message.createdAt.year != nextOlderMessage.createdAt.year ||
                            message.createdAt.month != nextOlderMessage.createdAt.month ||
                            message.createdAt.day != nextOlderMessage.createdAt.day) {
                          showDateHeader = true;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? LuminaColors.surfaceDark.withAlpha(128) 
                                        : LuminaColors.surface.withAlpha(128),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatHeaderDate(message.createdAt),
                                    style: GoogleFonts.dmSans(
                                      fontSize: LuminaTypography.sizeCaption,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: EntranceTransition(
                              child: MessageBubble(
                                message: message,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                if (chatState.rateLimitResetAt != null &&
                    chatState.rateLimitResetAt!.isAfter(DateTime.now()))
                  RateLimitBanner(resetAt: chatState.rateLimitResetAt!),

                // Chat Input Bar
                ChatInputBar(
                  enabled: chatState.rateLimitResetAt == null ||
                      !chatState.rateLimitResetAt!.isAfter(DateTime.now()),
                  onSend: (text, imageBase64) {
                    chatNotifier.sendMessage(text, imageBase64: imageBase64);
                  },
                ),
              ],
            ),
          ),
          // Native App Updater Modal Prompt Overlay
          const Positioned.fill(
            child: UpdatePromptDialog(),
          ),
        ],
      ),
    );
  }
}

// Warm analogue multi-colored gradient mesh circle with fluid thinking animations
class GradientMeshAvatar extends StatefulWidget {
  final double size;
  final bool isThinking;

  const GradientMeshAvatar({
    super.key,
    this.size = 36,
    this.isThinking = false,
  });

  @override
  State<GradientMeshAvatar> createState() => _GradientMeshAvatarState();
}

class _GradientMeshAvatarState extends State<GradientMeshAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isThinking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GradientMeshAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking != oldWidget.isThinking) {
      if (widget.isThinking) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 350));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFE6D5B8), // Warm beige
            Color(0xFFE8C288), // Warm soft gold
            Color(0xFFD4820A), // Warm amber
            Color(0xFF6B8F5E), // Sage green accent
            Color(0xFFE6D5B8), // Loop wrapper
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );

    if (widget.isThinking) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _controller.value * 2 * pi,
              child: child,
            ),
          );
        },
        child: avatar,
      );
    }

    return avatar;
  }
}
