class Message {
  final String id;
  final String conversationId;
  final String userId;
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
}
