import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? sku;
  final int quantity;
  final double purchasePrice;
  final double mrp;
  final DateTime? expiryDate;
  final double totalAmount;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.purchasePrice,
    required this.mrp,
    this.expiryDate,
    required this.totalAmount,
  });

  double get savings => (mrp - purchasePrice) * quantity;

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        sku,
        quantity,
        purchasePrice,
        mrp,
        expiryDate,
        totalAmount,
      ];
}
