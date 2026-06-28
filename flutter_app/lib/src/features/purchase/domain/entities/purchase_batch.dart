import 'package:equatable/equatable.dart';

class PurchaseBatch extends Equatable {
  final String id;
  final String batchNumber;
  final String productId;
  final DateTime purchaseDate;
  final double purchasePrice;
  final double mrp;
  final DateTime? expiryDate;
  final int purchasedQuantity;
  final int availableQuantity;
  final String status;

  const PurchaseBatch({
    required this.id,
    required this.batchNumber,
    required this.productId,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.mrp,
    this.expiryDate,
    required this.purchasedQuantity,
    required this.availableQuantity,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        batchNumber,
        productId,
        purchaseDate,
        purchasePrice,
        mrp,
        expiryDate,
        purchasedQuantity,
        availableQuantity,
        status,
      ];
}
