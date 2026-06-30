import '../../domain/entities/sale_item.dart';

class SaleItemModel extends SaleItem {
  const SaleItemModel({
    required super.id,
    required super.productId,
    super.batchId,
    super.productName,
    super.productSku,
    super.productHsnCode,
    super.batchNumber,
    required super.quantity,
    super.sellingPrice,
    super.discount,
    super.cgstRate,
    super.sgstRate,
    super.igstRate,
    super.cgstAmount,
    super.sgstAmount,
    super.igstAmount,
    super.taxAmount,
    super.totalAmount,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final batch = json['batch'] as Map<String, dynamic>?;
    return SaleItemModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      batchId: json['batchId'],
      productName: product?['name'] ?? '',
      productSku: product?['sku'],
      productHsnCode: product?['hsnCode'],
      batchNumber: batch?['batchNumber'],
      quantity: json['quantity'] ?? 0,
      sellingPrice: _toDouble(json['sellingPrice']),
      discount: _toDouble(json['discount']),
      cgstRate: _toDouble(json['cgstRate']),
      sgstRate: _toDouble(json['sgstRate']),
      igstRate: _toDouble(json['igstRate']),
      cgstAmount: _toDouble(json['cgstAmount']),
      sgstAmount: _toDouble(json['sgstAmount']),
      igstAmount: _toDouble(json['igstAmount']),
      taxAmount: _toDouble(json['taxAmount']),
      totalAmount: _toDouble(json['totalAmount']),
    );
  }

  SaleItem toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
