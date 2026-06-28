import 'package:equatable/equatable.dart';

import 'purchase_batch.dart';
import 'purchase_item.dart';
import 'vendor_payment.dart';

class Purchase extends Equatable {
  final String id;
  final String vendorId;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VendorInfo? vendor;
  final int itemCount;
  final List<PurchaseItem> items;
  final List<PurchaseBatch> batches;
  final List<VendorPayment> vendorPayments;

  const Purchase({
    required this.id,
    required this.vendorId,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.vendor,
    this.itemCount = 0,
    this.items = const [],
    this.batches = const [],
    this.vendorPayments = const [],
  });

  bool get isPaid => status == 'PAID';
  bool get isPartial => status == 'PARTIAL';
  bool get isUnpaid => status == 'UNPAID';

  @override
  List<Object?> get props => [
        id,
        vendorId,
        invoiceNumber,
        purchaseDate,
        totalAmount,
        paidAmount,
        balanceAmount,
        status,
        notes,
        createdAt,
        updatedAt,
        vendor,
        itemCount,
        items,
        batches,
        vendorPayments,
      ];
}

class VendorInfo extends Equatable {
  final String id;
  final String name;
  final String? mobile;
  final String? gstNumber;
  final String? email;
  final String? address;

  const VendorInfo({
    required this.id,
    required this.name,
    this.mobile,
    this.gstNumber,
    this.email,
    this.address,
  });

  @override
  List<Object?> get props => [id, name, mobile, gstNumber, email, address];
}
