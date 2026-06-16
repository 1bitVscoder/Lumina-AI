class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String aiName;
  final String archetype;
  final bool onboarded;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.aiName,
    required this.archetype,
    required this.onboarded,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      aiName: json['ai_name'] ?? 'Lumina',
      archetype: json['archetype'] ?? '',
      onboarded: json['onboarded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'ai_name': aiName,
      'archetype': archetype,
      'onboarded': onboarded,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? aiName,
    String? archetype,
    bool? onboarded,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aiName: aiName ?? this.aiName,
      archetype: archetype ?? this.archetype,
      onboarded: onboarded ?? this.onboarded,
    );
  }
}
