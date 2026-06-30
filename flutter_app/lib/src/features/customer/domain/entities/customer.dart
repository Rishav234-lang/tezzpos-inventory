import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? mobile;
  final String? gstNumber;
  final String? email;
  final String? address;
  final String status;
  final double totalPurchaseAmount;
  final double totalPaidAmount;
  final double outstandingBalance;
  final DateTime? lastPurchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.mobile,
    this.gstNumber,
    this.email,
    this.address,
    this.status = 'ACTIVE',
    this.totalPurchaseAmount = 0,
    this.totalPaidAmount = 0,
    this.outstandingBalance = 0,
    this.lastPurchaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isActive => status == 'ACTIVE';

  String get formattedLastPurchaseDate {
    if (lastPurchaseDate == null) return 'N/A';
    final d = lastPurchaseDate!;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mobile,
        gstNumber,
        email,
        address,
        status,
        totalPurchaseAmount,
        totalPaidAmount,
        outstandingBalance,
        lastPurchaseDate,
        createdAt,
        updatedAt,
      ];
}
