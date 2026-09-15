class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String role;
  final String? className;
  final String? levelName;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.bio,
    required this.role,
    this.className,
    this.levelName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      role: map['role'] as String? ?? 'membre',
      className: (map['classes'] as Map<String, dynamic>?)?['name'] as String?,
      levelName: (map['levels'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}

class ProfileStats {
  final int skillsValidated;

  const ProfileStats({required this.skillsValidated});
}
