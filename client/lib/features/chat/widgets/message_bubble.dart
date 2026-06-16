import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../shared/models/message.dart';
import '../providers/tts_provider.dart';
import '../providers/chat_provider.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  void _showReactionMenu(BuildContext context, WidgetRef ref) {
    final List<String> emojis = ["👍", "❤️", "😂", "😮", "😢", "🙏"];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF2C2C3C) : const Color(0xFFE5E5E5),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(chatProvider.notifier).setMessageReaction(message.id, emoji);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'read') {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.blue,
      );
    } else if (status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.grey,
      );
    } else {
      return const Icon(
        Icons.done,
        size: 15,
        color: Colors.grey,
      );
    }
  }

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

    // Compute status
    final chatState = ref.watch(chatProvider);
    String status = '';
    if (message.isUser) {
      final index = chatState.messages.indexOf(message);
      if (index != -1) {
        bool hasAssistantReply = false;
        for (int i = index + 1; i < chatState.messages.length; i++) {
          if (chatState.messages[i].role == 'assistant') {
            hasAssistantReply = true;
            break;
          }
        }
        if (hasAssistantReply) {
          status = 'read';
        } else if (chatState.isTyping) {
          status = 'delivered';
        } else {
          status = 'sent';
        }
      } else {
        status = 'sent';
      }
    }

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

    if (message.isError) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(right: 48, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? LuminaColors.accentRed.withValues(alpha: 0.15) 
                : LuminaColors.accentRed.withValues(alpha: 0.08),
            border: Border.all(
              color: LuminaColors.accentRed.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(LuminaRadius.bubbleAi),
              topRight: Radius.circular(LuminaRadius.bubbleAi),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(LuminaRadius.bubbleAi),
            ),
          ),
          child: InkWell(
            onTap: () {
              ref.read(chatProvider.notifier).retryLastMessage();
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(LuminaRadius.bubbleAi),
              topRight: Radius.circular(LuminaRadius.bubbleAi),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(LuminaRadius.bubbleAi),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: LuminaColors.accentRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.content,
                      style: GoogleFonts.dmSans(
                        fontSize: LuminaTypography.sizeBody - 1,
                        color: LuminaColors.accentRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget bubbleWidget;

    if (message.isUser) {
      bubbleWidget = Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: userBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(LuminaRadius.bubbleUser),
              topRight: Radius.circular(LuminaRadius.bubbleUser),
              bottomLeft: Radius.circular(LuminaRadius.bubbleUser),
              bottomRight: Radius.circular(4),
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
                    const SizedBox(width: 4),
                    _buildStatusIcon(status),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      bubbleWidget = Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(right: 48, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: aiBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(LuminaRadius.bubbleAi),
              topRight: Radius.circular(LuminaRadius.bubbleAi),
              bottomLeft: Radius.circular(4),
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

    return GestureDetector(
      onDoubleTap: () {
        if (message.reaction == "❤️") {
          ref.read(chatProvider.notifier).setMessageReaction(message.id, null);
        } else {
          ref.read(chatProvider.notifier).setMessageReaction(message.id, "❤️");
        }
      },
      onLongPress: () {
        _showReactionMenu(context, ref);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bubbleWidget,
          if (message.reaction != null)
            Positioned(
              bottom: -4,
              right: message.isUser ? null : 16,
              left: message.isUser ? 16 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2C2A4A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF3C3A5A) : const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  message.reaction!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
