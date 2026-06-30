import 'customer_info_model.dart';
import '../../domain/entities/sale_return.dart';

class SaleReturnModel extends SaleReturn {
  const SaleReturnModel({
    required super.id,
    required super.saleId,
    super.originalInvoiceNumber,
    required super.returnNumber,
    required super.returnDate,
    super.totalAmount,
    super.refundAmount,
    super.reason,
    super.status,
    super.customer,
    super.items,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SaleReturnModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final saleJson = json['sale'] as Map<String, dynamic>?;
    final itemsJson = (json['items'] as List<dynamic>?) ?? [];
    return SaleReturnModel(
      id: json['id'] ?? '',
      saleId: json['saleId'] ?? '',
      originalInvoiceNumber: saleJson?['invoiceNumber'],
      returnNumber: json['returnNumber'] ?? '',
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : DateTime.now(),
      totalAmount: _toDouble(json['totalAmount']),
      refundAmount: _toDouble(json['refundAmount']),
      reason: json['reason'],
      status: json['status'] ?? 'PENDING',
      customer: customerJson != null ? CustomerInfoModel.fromJson(customerJson) : null,
      items: itemsJson.map((e) {
        final item = e as Map<String, dynamic>;
        final product = item['product'] as Map<String, dynamic>?;
        return SaleReturnItem(
          id: item['id'] ?? '',
          productId: item['productId'] ?? '',
          productName: product?['name'] ?? '',
          productSku: product?['sku'],
          quantity: item['quantity'] ?? 0,
          price: _toDouble(item['price']),
          totalAmount: _toDouble(item['totalAmount']),
        );
      }).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  SaleReturn toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
