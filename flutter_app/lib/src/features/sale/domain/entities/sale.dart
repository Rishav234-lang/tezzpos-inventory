import 'package:equatable/equatable.dart';

import 'customer_info.dart';
import 'sale_item.dart';

class Sale extends Equatable {
  final String id;
  final String? customerId;
  final CustomerInfo? customer;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final bool isInterState;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String? paymentMethod;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem> items;

  const Sale({
    required this.id,
    this.customerId,
    this.customer,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.subtotal = 0,
    this.discount = 0,
    this.taxAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.isInterState = false,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.paymentMethod,
    this.status = 'UNPAID',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  bool get isPaid => status == 'PAID';
  bool get isPartial => status == 'PARTIAL';
  bool get isUnpaid => status == 'UNPAID';
  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [
        id,
        customerId,
        invoiceNumber,
        invoiceDate,
        subtotal,
        discount,
        taxAmount,
        cgstAmount,
        sgstAmount,
        igstAmount,
        isInterState,
        totalAmount,
        paidAmount,
        balanceAmount,
        paymentMethod,
        status,
        notes,
        createdAt,
        updatedAt,
        items,
      ];
}
