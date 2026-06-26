import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalProducts;
  final int totalVendors;
  final int totalCustomers;
  final double inventoryValue;
  final double todaySales;
  final int todaySalesCount;
  final double monthlySales;
  final int monthlySalesCount;
  final double todayPurchases;
  final double monthlyPurchases;
  final double grossProfit;
  final double pendingReceivables;
  final double pendingPayables;
  final int expiringSoonCount;
  final int lowStockCount;
  final double todaySalesTarget;

  const DashboardStats({
    required this.totalProducts,
    required this.totalVendors,
    required this.totalCustomers,
    required this.inventoryValue,
    required this.todaySales,
    required this.todaySalesCount,
    required this.monthlySales,
    required this.monthlySalesCount,
    required this.todayPurchases,
    required this.monthlyPurchases,
    required this.grossProfit,
    required this.pendingReceivables,
    required this.pendingPayables,
    required this.expiringSoonCount,
    required this.lowStockCount,
    required this.todaySalesTarget,
  });

  @override
  List<Object?> get props => [
        totalProducts,
        totalVendors,
        totalCustomers,
        inventoryValue,
        todaySales,
        todaySalesCount,
        monthlySales,
        monthlySalesCount,
        todayPurchases,
        monthlyPurchases,
        grossProfit,
        pendingReceivables,
        pendingPayables,
        expiringSoonCount,
        lowStockCount,
        todaySalesTarget,
      ];
}

class RecentTransaction extends Equatable {
  final String id;
  final String invoiceNumber;
  final String type; // 'SALE', 'PURCHASE', 'PAYMENT'
  final String? customerName;
  final String? vendorName;
  final double totalAmount;
  final DateTime date;
  final String status;

  const RecentTransaction({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    this.customerName,
    this.vendorName,
    required this.totalAmount,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props => [id, invoiceNumber, type, customerName, vendorName, totalAmount, date, status];
}

class TopSellingProduct extends Equatable {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [productId, productName, totalQuantity, totalRevenue];
}

class ChartDataPoint extends Equatable {
  final String date;
  final double amount;
  final int count;

  const ChartDataPoint({
    required this.date,
    required this.amount,
    required this.count,
  });

  @override
  List<Object?> get props => [date, amount, count];
}
