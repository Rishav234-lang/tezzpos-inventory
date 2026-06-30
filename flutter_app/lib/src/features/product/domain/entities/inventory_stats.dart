import 'package:equatable/equatable.dart';

class InventoryStats extends Equatable {
  final int totalProducts;
  final int totalStockQuantity;
  final double inventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;

  const InventoryStats({
    required this.totalProducts,
    required this.totalStockQuantity,
    required this.inventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringSoonCount,
  });

  @override
  List<Object?> get props => [
        totalProducts,
        totalStockQuantity,
        inventoryValue,
        lowStockCount,
        outOfStockCount,
        expiringSoonCount,
      ];
}
