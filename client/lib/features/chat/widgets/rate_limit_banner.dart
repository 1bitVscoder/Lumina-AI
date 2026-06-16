import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/chat_provider.dart';

class RateLimitBanner extends ConsumerStatefulWidget {
  final DateTime resetAt;

  const RateLimitBanner({
    super.key,
    required this.resetAt,
  });

  @override
  ConsumerState<RateLimitBanner> createState() => _RateLimitBannerState();
}

class _RateLimitBannerState extends ConsumerState<RateLimitBanner> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final difference = widget.resetAt.difference(now);
    
    if (difference.isNegative || difference == Duration.zero) {
      _timer.cancel();
      // Unlock the chat provider dynamically
      ref.read(chatProvider.notifier).clearRateLimit();
    } else {
      setState(() {
        _timeLeft = difference;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final aiName = ref.watch(userProfileProvider).aiName;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bannerBg = isDarkMode ? LuminaColors.surfaceDark : const Color(0xFFFFF7E6);
    final borderColor = isDarkMode ? LuminaColors.accentAmber.withAlpha(128) : LuminaColors.divider;
    final textColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: LuminaSpacing.md,
        vertical: LuminaSpacing.xs,
      ),
      padding: const EdgeInsets.all(LuminaSpacing.md),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(LuminaRadius.card),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.hourglass_empty_outlined,
                color: LuminaColors.accentAmber,
                size: 20,
              ),
              const SizedBox(width: LuminaSpacing.sm),
              Expanded(
                child: Text(
                  "$aiName needs a break — you've talked a lot today. Come back tomorrow 💬",
                  style: GoogleFonts.dmSans(
                    fontSize: LuminaTypography.sizeBody - 1,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuminaSpacing.sm),
          Divider(color: borderColor, height: 0.5),
          const SizedBox(height: LuminaSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Unlocking in:",
                style: GoogleFonts.dmSans(
                  fontSize: LuminaTypography.sizeCaption,
                  color: LuminaColors.textSecondary,
                ),
              ),
              Text(
                _formatDuration(_timeLeft),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: LuminaTypography.sizeBody - 1,
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.accentAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
