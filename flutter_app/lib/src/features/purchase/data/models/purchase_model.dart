import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_batch.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/entities/vendor_payment.dart';

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.vendorId,
    required super.invoiceNumber,
    required super.purchaseDate,
    required super.totalAmount,
    required super.paidAmount,
    required super.balanceAmount,
    required super.status,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.vendor,
    super.itemCount,
    super.items,
    super.batches,
    super.vendorPayments,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final vendorJson = json['vendor'] as Map<String, dynamic>?;
    final countJson = json['_count'] as Map<String, dynamic>?;

    return PurchaseModel(
      id: json['id'] ?? '',
      vendorId: json['vendorId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      totalAmount: _parseDecimal(json['totalAmount']),
      paidAmount: _parseDecimal(json['paidAmount']),
      balanceAmount: _parseDecimal(json['balanceAmount']),
      status: json['status'] ?? 'UNPAID',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      vendor: vendorJson != null
          ? VendorInfo(
              id: vendorJson['id'] ?? '',
              name: vendorJson['name'] ?? '',
              mobile: vendorJson['mobile'] as String?,
              gstNumber: vendorJson['gstNumber'] as String?,
              email: vendorJson['email'] as String?,
              address: vendorJson['address'] as String?,
            )
          : null,
      itemCount: (countJson?['items'] as num?)?.toInt() ?? 0,
      items: _parseItems(json['items']),
      batches: _parseBatches(json['batches']),
      vendorPayments: _parseVendorPayments(json['vendorPayments']),
    );
  }

  static List<PurchaseItem> _parseItems(dynamic itemsJson) {
    if (itemsJson == null) return const [];
    final list = itemsJson as List<dynamic>;
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      final product = json['product'] as Map<String, dynamic>?;
      return PurchaseItem(
        id: json['id'] ?? '',
        productId: json['productId'] ?? '',
        productName: product?['name'] ?? 'Unknown',
        sku: product?['sku'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        purchasePrice: _parseDecimal(json['purchasePrice']),
        mrp: _parseDecimal(json['mrp']),
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'])
            : null,
        totalAmount: _parseDecimal(json['totalAmount']),
      );
    }).toList();
  }

  static List<PurchaseBatch> _parseBatches(dynamic batchesJson) {
    if (batchesJson == null) return const [];
    final list = batchesJson as List<dynamic>;
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      return PurchaseBatch(
        id: json['id'] ?? '',
        batchNumber: json['batchNumber'] ?? '',
        productId: json['productId'] ?? '',
        purchaseDate: json['purchaseDate'] != null
            ? DateTime.parse(json['purchaseDate'])
            : DateTime.now(),
        purchasePrice: _parseDecimal(json['purchasePrice']),
        mrp: _parseDecimal(json['mrp']),
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'])
            : null,
        purchasedQuantity: (json['purchasedQuantity'] as num?)?.toInt() ?? 0,
        availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
        status: json['status'] ?? 'ACTIVE',
      );
    }).toList();
  }

  static List<VendorPayment> _parseVendorPayments(dynamic paymentsJson) {
    if (paymentsJson == null) return const [];
    final list = paymentsJson as List<dynamic>;
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      return VendorPayment(
        id: json['id'] ?? '',
        vendorId: json['vendorId'] ?? '',
        purchaseId: json['purchaseId'] as String?,
        amount: _parseDecimal(json['amount']),
        paymentDate: json['paymentDate'] != null
            ? DateTime.parse(json['paymentDate'])
            : DateTime.now(),
        paymentMethod: json['paymentMethod'] ?? 'CASH',
        referenceNo: json['referenceNo'] as String?,
        notes: json['notes'] as String?,
      );
    }).toList();
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'vendor': vendor != null ? {'id': vendor!.id, 'name': vendor!.name} : null,
      'itemCount': itemCount,
    };
  }

  Purchase toEntity() => this;
}
