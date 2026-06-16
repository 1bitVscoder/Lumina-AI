class Message {
  final String id;
  final String conversationId;
  final String userId;
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String? reaction;

  Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.reaction,
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
      reaction: json['reaction'],
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
      'reaction': reaction,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? userId,
    String? role,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    String? reaction,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      reaction: reaction ?? this.reaction,
    );
  }

  bool get isUser => role == 'user';
  bool get isError => role == 'error';
}
