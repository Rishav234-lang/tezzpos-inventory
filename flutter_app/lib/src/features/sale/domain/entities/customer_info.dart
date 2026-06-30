import 'package:equatable/equatable.dart';

class CustomerInfo extends Equatable {
  final String id;
  final String name;
  final String? mobile;
  final String? gstNumber;
  final String? address;

  const CustomerInfo({
    required this.id,
    required this.name,
    this.mobile,
    this.gstNumber,
    this.address,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, name, mobile, gstNumber, address];
}
