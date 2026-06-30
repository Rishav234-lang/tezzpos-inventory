import 'package:equatable/equatable.dart';

import 'customer_info.dart';

class SaleReturnItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final int quantity;
  final double price;
  final double totalAmount;

  const SaleReturnItem({
    required this.id,
    required this.productId,
    this.productName = '',
    this.productSku,
    required this.quantity,
    this.price = 0,
    this.totalAmount = 0,
  });

  @override
  List<Object?> get props => [id, productId, productName, productSku, quantity, price, totalAmount];
}

class SaleReturn extends Equatable {
  final String id;
  final String saleId;
  final String? originalInvoiceNumber;
  final String returnNumber;
  final DateTime returnDate;
  final double totalAmount;
  final double refundAmount;
  final String? reason;
  final String status;
  final CustomerInfo? customer;
  final List<SaleReturnItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SaleReturn({
    required this.id,
    required this.saleId,
    this.originalInvoiceNumber,
    required this.returnNumber,
    required this.returnDate,
    this.totalAmount = 0,
    this.refundAmount = 0,
    this.reason,
    this.status = 'PENDING',
    this.customer,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        saleId,
        returnNumber,
        returnDate,
        totalAmount,
        refundAmount,
        reason,
        status,
        customer,
        items,
        createdAt,
        updatedAt,
      ];
}
