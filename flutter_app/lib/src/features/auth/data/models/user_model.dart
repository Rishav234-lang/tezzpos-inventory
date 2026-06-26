import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.companyId,
    super.companyName,
    super.companyStatus,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>? ?? {};
    return UserModel(
      id: userData['id'] ?? '',
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      role: userData['role'] ?? 'owner',
      companyId: userData['companyId'],
      companyName: userData['companyName'],
      companyStatus: userData['companyStatus'],
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'companyId': companyId,
      'companyName': companyName,
      'companyStatus': companyStatus,
      'token': token,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      role: role,
      companyId: companyId,
      companyName: companyName,
      companyStatus: companyStatus,
      token: token,
    );
  }
}
