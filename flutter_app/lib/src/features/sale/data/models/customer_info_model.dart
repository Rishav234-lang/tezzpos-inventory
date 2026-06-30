import '../../domain/entities/customer_info.dart';

class CustomerInfoModel extends CustomerInfo {
  const CustomerInfoModel({
    required super.id,
    required super.name,
    super.mobile,
    super.gstNumber,
    super.address,
  });

  factory CustomerInfoModel.fromJson(Map<String, dynamic> json) {
    return CustomerInfoModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'],
      gstNumber: json['gstNumber'],
      address: json['address'],
    );
  }

  CustomerInfo toEntity() => this;
}
