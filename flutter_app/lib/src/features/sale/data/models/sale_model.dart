import 'customer_info_model.dart';
import 'sale_item_model.dart';
import '../../domain/entities/sale.dart';

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    super.customerId,
    super.customer,
    required super.invoiceNumber,
    required super.invoiceDate,
    super.subtotal,
    super.discount,
    super.taxAmount,
    super.cgstAmount,
    super.sgstAmount,
    super.igstAmount,
    super.isInterState,
    super.totalAmount,
    super.paidAmount,
    super.balanceAmount,
    super.paymentMethod,
    super.status,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final itemsJson = (json['items'] as List<dynamic>?) ?? [];
    return SaleModel(
      id: json['id'] ?? '',
      customerId: json['customerId'],
      customer: customerJson != null ? CustomerInfoModel.fromJson(customerJson) : null,
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceDate: json['invoiceDate'] != null ? DateTime.parse(json['invoiceDate']) : DateTime.now(),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      taxAmount: _toDouble(json['taxAmount']),
      cgstAmount: _toDouble(json['cgstAmount']),
      sgstAmount: _toDouble(json['sgstAmount']),
      igstAmount: _toDouble(json['igstAmount']),
      isInterState: json['isInterState'] ?? false,
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      balanceAmount: _toDouble(json['balanceAmount']),
      paymentMethod: json['paymentMethod'],
      status: json['status'] ?? 'UNPAID',
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      items: itemsJson.map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Sale toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
