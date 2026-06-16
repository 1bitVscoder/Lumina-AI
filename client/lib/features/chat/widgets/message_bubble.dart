import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../shared/models/message.dart';
import '../providers/tts_provider.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Bubble color schemes
    final userBgColor = isDarkMode ? LuminaColors.userBubbleDark : LuminaColors.userBubble;
    final aiBgColor = isDarkMode ? LuminaColors.aiBubbleDark : LuminaColors.aiBubble;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    // Time Formatter (HH:MM)
    final timeStr = "${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}";

    // Handle optional base64 image payload or URL
    Widget? imageWidget;
    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      try {
        final cleanBase64 = message.imageUrl!.contains(',')
            ? message.imageUrl!.split(',')[1]
            : message.imageUrl!;
        final decodedBytes = base64Decode(cleanBase64);
        imageWidget = Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(maxHeight: 220),
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              decodedBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        );
      } catch (e) {
        // Fallback for standard remote image URL
        imageWidget = Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(maxHeight: 220),
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        );
      }
    }

    if (message.isUser) {
      // User Bubble (Right-aligned, Sage green)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: userBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(LuminaRadius.bubbleUser),
              topRight: Radius.circular(LuminaRadius.bubbleUser),
              bottomLeft: Radius.circular(LuminaRadius.bubbleUser),
              bottomRight: Radius.circular(4), // Tail bottom-right
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageWidget != null) imageWidget,
                // Message Content
                if (message.content.isNotEmpty)
                  Text(
                    message.content,
                    style: GoogleFonts.dmSans(
                      fontSize: LuminaTypography.sizeBody,
                      color: primaryTextColor,
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 4),
                // Timestamp
                Text(
                  timeStr,
                  style: GoogleFonts.dmSans(
                    fontSize: LuminaTypography.sizeCaption,
                    color: secTextColor.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // AI Companion Bubble (Left-aligned, Paper white)
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(right: 48, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: aiBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(LuminaRadius.bubbleAi),
              topRight: Radius.circular(LuminaRadius.bubbleAi),
              bottomLeft: Radius.circular(4), // Tail bottom-left
              bottomRight: Radius.circular(LuminaRadius.bubbleAi),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageWidget != null) imageWidget,
                // AI Response Content (in JetBrains Mono)
                if (message.content.isNotEmpty)
                  Text(
                    message.content,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: LuminaTypography.sizeBody - 1,
                      color: primaryTextColor,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 6),
                
                // Timestamp and TTS Action row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.dmSans(
                        fontSize: LuminaTypography.sizeCaption,
                        color: secTextColor.withAlpha(204),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Speak Button Icon (16px) linked to ttsProvider
                    GestureDetector(
                      onTap: () {
                        ref.read(ttsProvider).speak(message.content);
                      },
                      child: Icon(
                        Icons.volume_up_outlined,
                        size: 16,
                        color: secTextColor.withAlpha(204),
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
  }
}
