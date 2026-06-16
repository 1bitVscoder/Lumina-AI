import 'package:flutter_test/flutter_test.dart';

import 'package:client/shared/models/message.dart';

void main() {
  test('Message serializes Supabase message rows', () {
    final message = Message.fromJson({
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'user_id': 'user-1',
      'role': 'user',
      'content': 'hello',
      'image_url': 'data:image/jpeg;base64,abc',
      'created_at': '2026-06-07T12:00:00.000Z',
    });

    expect(message.id, 'msg-1');
    expect(message.conversationId, 'conv-1');
    expect(message.isUser, isTrue);
    expect(message.imageUrl, 'data:image/jpeg;base64,abc');
    expect(
      message.toJson(),
      containsPair('created_at', message.createdAt.toIso8601String()),
    );
  });
}
