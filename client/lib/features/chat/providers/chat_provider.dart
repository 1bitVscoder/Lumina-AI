import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/network.dart';
import '../../../shared/models/message.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../settings/providers/settings_provider.dart';
import 'tts_provider.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isTyping;
  final String? conversationId;
  final DateTime? rateLimitResetAt;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.conversationId,
    this.rateLimitResetAt,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isTyping,
    String? conversationId,
    DateTime? rateLimitResetAt,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      conversationId: conversationId ?? this.conversationId,
      rateLimitResetAt: rateLimitResetAt,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(ChatState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final client = supabase.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      
      // 1. Fetch user record from users table to get generated DB UUID
      final userData = await client
          .from('users')
          .select('id')
          .eq('google_uid', user.id)
          .maybeSingle();
          
      if (userData == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final dbUserId = userData['id'] as String;

      // 2. Fetch latest conversation id
      final convData = await client
          .from('conversations')
          .select('id')
          .eq('user_id', dbUserId)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
       
      String? convId;
      List<Message> loadedMessages = [];
      
      if (convData != null) {
        convId = convData['id'] as String;
        
        // Fetch last 30 messages in chronological order
        final msgData = await client
            .from('messages')
            .select()
            .eq('conversation_id', convId)
            .order('created_at', ascending: true)
            .limit(30);
             
        loadedMessages = (msgData as List).map((m) => Message.fromJson(m)).toList();
      }
      
      // If conversation is brand new and has no history, add a welcoming prompt
      if (loadedMessages.isEmpty) {
        final aiName = _ref.read(userProfileProvider).aiName;
        loadedMessages = [
          Message(
            id: 'welcome',
            conversationId: convId ?? 'new',
            userId: 'lumina',
            role: 'assistant',
            content: 'Hey, I\'m $aiName. Good to see you.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          )
        ];
      }
      
      state = ChatState(
        messages: loadedMessages,
        conversationId: convId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Failed to load chat history: $e");
    }
  }

  Future<void> sendMessage(String text, {String? imageBase64}) async {
    if (text.trim().isEmpty) return;
    
    // Check local rate limit flag before executing request
    if (state.rateLimitResetAt != null && state.rateLimitResetAt!.isAfter(DateTime.now())) {
      return;
    }

    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userMessage = Message(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversationId ?? 'new',
      userId: user.id,
      role: 'user',
      content: text,
      imageUrl: imageBase64,
      createdAt: DateTime.now(),
    );

    // Append user message locally and show typing animation
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    try {
      final dio = _ref.read(dioProvider);
      
      // Convert history messages to expected backend JSON format
      final formattedHistory = state.messages
          .where((m) => m.id != 'welcome') // skip static welcome message
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      final response = await dio.post('/chat', data: {
        'user_id': user.id,
        'conversation_id': state.conversationId,
        'message': text,
        'image_base64': imageBase64,
        'history': formattedHistory,
      });

      final replyText = response.data['reply'] as String;
      final newConvId = response.data['conversation_id'] as String;

      final aiMessage = Message(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: newConvId,
        userId: 'lumina',
        role: 'assistant',
        content: replyText,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        conversationId: newConvId,
        isTyping: false,
      );

      // Speak if autoplay is enabled
      final autoplay = _ref.read(settingsProvider).autoplayTts;
      if (autoplay) {
        _ref.read(ttsProvider).speak(replyText);
      }
    } catch (e) {
      state = state.copyWith(isTyping: false);
      
      if (e is DioException && e.response?.statusCode == 429) {
        final errorData = e.response?.data;
        // Parse detail reset timestamp from backend standard response
        final resetAtStr = errorData?['detail']?['reset_at'] as String?;
        if (resetAtStr != null) {
          state = state.copyWith(
            rateLimitResetAt: DateTime.parse(resetAtStr).toLocal(),
          );
        }
      } else {
        debugPrint("Chat message sending failed: $e");
      }
    }
  }

  Future<void> clearHistory() async {
    try {
      final client = supabase.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final userData = await client
          .from('users')
          .select('id')
          .eq('google_uid', user.id)
          .maybeSingle();
      if (userData == null) return;
      final dbUserId = userData['id'] as String;

      // Deletes conversations, which cascades to delete messages
      await client.from('conversations').delete().eq('user_id', dbUserId);

      // Local state resets back to welcome message
      final aiName = _ref.read(userProfileProvider).aiName;
      state = ChatState(
        messages: [
          Message(
            id: 'welcome',
            conversationId: 'new',
            userId: 'lumina',
            role: 'assistant',
            content: 'Hey, I\'m $aiName. Good to see you.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          )
        ],
        conversationId: null,
        isLoading: false,
      );
    } catch (e) {
      debugPrint("Failed to clear chat history: $e");
    }
  }

  void clearRateLimit() {
    state = state.copyWith(rateLimitResetAt: null);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
