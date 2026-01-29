class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isSuperAdmin;
  final bool isAnonymous;

  /// Compatibility alias (some parts of the app expect `.uid`)
  String get uid => id;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isSuperAdmin = false,
    this.isAnonymous = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isSuperAdmin: (map['isSuperAdmin'] ?? false) as bool,
      isAnonymous: (map['isAnonymous'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isSuperAdmin': isSuperAdmin,
      'isAnonymous': isAnonymous,
    };
  }
}

