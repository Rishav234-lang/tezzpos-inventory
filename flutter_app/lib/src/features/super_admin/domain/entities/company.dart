import 'package:equatable/equatable.dart';

class Owner extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const Owner({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, email, phone];
}

class SubscriptionInfo extends Equatable {
  final String id;
  final String planId;
  final String? planName;
  final String billingCycle;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double? customPrice;

  const SubscriptionInfo({
    required this.id,
    required this.planId,
    this.planName,
    required this.billingCycle,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.customPrice,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 7;
  }

  @override
  List<Object?> get props => [id, planId, planName, billingCycle, startDate, endDate, status, customPrice];
}

class Company extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? gstNumber;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Owner? owner;
  final SubscriptionInfo? subscription;

  const Company({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.gstNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
    this.subscription,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isPending => status == 'PENDING';

  String get initials {
    if (name.isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Company copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gstNumber,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Owner? owner,
    SubscriptionInfo? subscription,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, address, gstNumber, status, createdAt, updatedAt, owner, subscription];
}
