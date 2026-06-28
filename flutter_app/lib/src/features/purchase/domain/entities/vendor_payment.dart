import 'package:equatable/equatable.dart';

class VendorPayment extends Equatable {
  final String id;
  final String vendorId;
  final String? purchaseId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? referenceNo;
  final String? notes;

  const VendorPayment({
    required this.id,
    required this.vendorId,
    this.purchaseId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNo,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        vendorId,
        purchaseId,
        amount,
        paymentDate,
        paymentMethod,
        referenceNo,
        notes,
      ];
}
