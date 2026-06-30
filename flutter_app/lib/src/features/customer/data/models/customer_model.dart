import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    super.mobile,
    super.gstNumber,
    super.email,
    super.address,
    super.status,
    super.totalPurchaseAmount,
    super.totalPaidAmount,
    super.outstandingBalance,
    super.lastPurchaseDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'],
      gstNumber: json['gstNumber'],
      email: json['email'],
      address: json['address'],
      status: json['status'] ?? 'ACTIVE',
      totalPurchaseAmount: _toDouble(json['totalPurchaseAmount']),
      totalPaidAmount: _toDouble(json['totalPaidAmount']),
      outstandingBalance: _toDouble(json['outstandingBalance']),
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.parse(json['lastPurchaseDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'gstNumber': gstNumber,
      'email': email,
      'address': address,
      'status': status,
      'totalPurchaseAmount': totalPurchaseAmount,
      'totalPaidAmount': totalPaidAmount,
      'outstandingBalance': outstandingBalance,
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Customer toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
