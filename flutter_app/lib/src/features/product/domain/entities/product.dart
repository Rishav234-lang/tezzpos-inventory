import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  final String? hsnCode;
  final double gstRate;
  final double costPrice;
  final double sellingPrice;
  final int minStockLevel;
  final int totalStock;
  final double stockValue;
  final double stockValueMrp;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firstBatchNumber;
  final DateTime? firstExpiryDate;
  final double? firstMrp;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.unit = 'PCS',
    this.hsnCode,
    this.gstRate = 0,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.minStockLevel = 10,
    this.totalStock = 0,
    this.stockValue = 0,
    this.stockValueMrp = 0,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
    this.firstBatchNumber,
    this.firstExpiryDate,
    this.firstMrp,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isLowStock => totalStock > 0 && totalStock <= minStockLevel;
  bool get isOutOfStock => totalStock == 0;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        sku,
        barcode,
        imageUrl,
        categoryId,
        categoryName,
        unit,
        hsnCode,
        gstRate,
        costPrice,
        sellingPrice,
        minStockLevel,
        totalStock,
        stockValue,
        stockValueMrp,
        status,
        firstBatchNumber,
        firstExpiryDate,
        firstMrp,
      ];
}
