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
    super.subscriptionStatus,
    super.subscriptionEndDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: userData['id'] ?? json['id'] ?? '',
      email: userData['email'] ?? json['email'] ?? '',
      name: userData['name'] ?? json['name'] ?? '',
      role: userData['role'] ?? json['role'] ?? 'owner',
      companyId: userData['companyId'] ?? json['companyId'],
      companyName: userData['companyName'] ?? json['companyName'],
      companyStatus: userData['companyStatus'] ?? json['companyStatus'],
      token: json['token'] as String? ?? userData['token'] as String?,
      subscriptionStatus: userData['subscriptionStatus'] ?? json['subscriptionStatus'],
      subscriptionEndDate: userData['subscriptionEndDate'] != null
          ? DateTime.tryParse(userData['subscriptionEndDate'])
          : (json['subscriptionEndDate'] != null
              ? DateTime.tryParse(json['subscriptionEndDate'])
              : null),
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
      'subscriptionStatus': subscriptionStatus,
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
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
      subscriptionStatus: subscriptionStatus,
      subscriptionEndDate: subscriptionEndDate,
    );
  }
}
