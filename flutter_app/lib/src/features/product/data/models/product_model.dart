import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    super.description,
    super.sku,
    super.barcode,
    super.imageUrl,
    super.categoryId,
    super.categoryName,
    super.unit,
    super.hsnCode,
    super.gstRate,
    super.costPrice,
    super.sellingPrice,
    super.minStockLevel,
    super.totalStock,
    super.stockValue,
    super.stockValueMrp,
    super.status,
    required super.createdAt,
    required super.updatedAt,
    super.firstBatchNumber,
    super.firstExpiryDate,
    super.firstMrp,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      sku: json['sku'],
      barcode: json['barcode'],
      imageUrl: json['imageUrl'],
      categoryId: json['categoryId'] ?? category?['id'],
      categoryName: json['categoryName'] ?? category?['name'],
      unit: json['unit'] ?? 'PCS',
      hsnCode: json['hsnCode'],
      gstRate: _toDouble(json['gstRate']) ?? 0,
      costPrice: _toDouble(json['costPrice']) ?? 0,
      sellingPrice: _toDouble(json['sellingPrice']) ?? 0,
      minStockLevel: _toInt(json['minStockLevel']) ?? 10,
      totalStock: _toInt(json['totalStock']) ?? 0,
      stockValue: _toDouble(json['stockValue']) ?? 0,
      stockValueMrp: _toDouble(json['stockValueMrp']) ?? 0,
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      firstBatchNumber: json['firstBatchNumber'],
      firstExpiryDate: json['firstExpiryDate'] != null
          ? DateTime.tryParse(json['firstExpiryDate'])
          : null,
      firstMrp: _toDouble(json['firstMrp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'unit': unit,
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'minStockLevel': minStockLevel,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product toEntity() => this;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
