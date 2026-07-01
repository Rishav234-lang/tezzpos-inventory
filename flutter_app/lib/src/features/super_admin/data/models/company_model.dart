import '../../domain/entities/company.dart';

class OwnerModel extends Owner {
  const OwnerModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

class SubscriptionInfoModel extends SubscriptionInfo {
  const SubscriptionInfoModel({
    required super.id,
    required super.planId,
    super.planName,
    required super.billingCycle,
    required super.startDate,
    required super.endDate,
    required super.status,
    super.customPrice,
  });

  factory SubscriptionInfoModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfoModel(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['plan']?['name'],
      billingCycle: json['billingCycle'] ?? 'MONTHLY',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'TRIAL',
      customPrice: json['customPrice'] != null ? (json['customPrice'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'billingCycle': billingCycle,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'customPrice': customPrice,
    };
  }
}

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.address,
    super.gstNumber,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.owner,
    super.subscription,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      gstNumber: json['gstNumber'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      owner: json['owner'] != null ? OwnerModel.fromJson(json['owner'] as Map<String, dynamic>) : null,
      subscription: json['subscription'] != null
          ? SubscriptionInfoModel.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gstNumber': gstNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'owner': owner != null ? (owner as OwnerModel).toJson() : null,
      'subscription': subscription != null ? (subscription as SubscriptionInfoModel).toJson() : null,
    };
  }

  Company toEntity() {
    return Company(
      id: id,
      name: name,
      email: email,
      phone: phone,
      address: address,
      gstNumber: gstNumber,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: owner,
      subscription: subscription,
    );
  }
}
