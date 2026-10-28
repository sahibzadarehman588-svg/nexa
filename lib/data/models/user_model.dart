class UserModel {
  final String userId;
  final String email;
  final String? displayName;
  final String? secretPassword;
  final String? firebasePassword;
  final String? role;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    this.displayName,
    this.secretPassword,
    this.firebasePassword,
    this.role,
    this.profilePhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      secretPassword: json['secretPassword'] as String?,
      firebasePassword: json['firebasePassword'] as String?,
      role: json['role'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'secretPassword': secretPassword,
      'firebasePassword': firebasePassword,
      'role': role,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? secretPassword,
    String? firebasePassword,
    String? role,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      secretPassword: secretPassword ?? this.secretPassword,
      firebasePassword: firebasePassword ?? this.firebasePassword,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
