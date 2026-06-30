import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final String id;
  final String productId;
  final String? batchId;
  final String productName;
  final String? productSku;
  final String? productHsnCode;
  final String? batchNumber;
  final int quantity;
  final double sellingPrice;
  final double discount;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double taxAmount;
  final double totalAmount;

  const SaleItem({
    required this.id,
    required this.productId,
    this.batchId,
    this.productName = '',
    this.productSku,
    this.productHsnCode,
    this.batchNumber,
    required this.quantity,
    this.sellingPrice = 0,
    this.discount = 0,
    this.cgstRate = 0,
    this.sgstRate = 0,
    this.igstRate = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
  });

  double get taxableAmount => (quantity * sellingPrice) - discount;

  @override
  List<Object?> get props => [
        id,
        productId,
        batchId,
        productName,
        productSku,
        quantity,
        sellingPrice,
        discount,
        cgstRate,
        sgstRate,
        igstRate,
        cgstAmount,
        sgstAmount,
        igstAmount,
        taxAmount,
        totalAmount,
      ];
}
