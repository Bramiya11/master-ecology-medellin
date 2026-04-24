import 'package:equatable/equatable.dart';

import '../core/constants/app_constants.dart';

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isCitizen => role == UserRole.citizen;
  bool get isRecycler => role == UserRole.recycler;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, email, role, avatarUrl, createdAt];
}
