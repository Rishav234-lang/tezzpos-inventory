import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? companyId;
  final String? companyName;
  final String? companyStatus;
  final String? token;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.companyId,
    this.companyName,
    this.companyStatus,
    this.token,
    this.subscriptionStatus,
    this.subscriptionEndDate,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isOwner => role == 'owner';

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? companyId,
    String? companyName,
    String? companyStatus,
    String? token,
    String? subscriptionStatus,
    DateTime? subscriptionEndDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyStatus: companyStatus ?? this.companyStatus,
      token: token ?? this.token,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'companyId': companyId,
      'companyName': companyName,
      'companyStatus': companyStatus,
      'token': token,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'owner',
      companyId: map['companyId'],
      companyName: map['companyName'],
      companyStatus: map['companyStatus'],
      token: map['token'],
      subscriptionStatus: map['subscriptionStatus'],
      subscriptionEndDate: map['subscriptionEndDate'] != null
          ? DateTime.tryParse(map['subscriptionEndDate'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, email, name, role, companyId, companyName, companyStatus, token, subscriptionStatus, subscriptionEndDate];
}
