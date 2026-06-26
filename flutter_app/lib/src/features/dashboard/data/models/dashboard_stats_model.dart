import '../../domain/entities/dashboard_stats.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalProducts,
    required super.totalVendors,
    required super.totalCustomers,
    required super.inventoryValue,
    required super.todaySales,
    required super.todaySalesCount,
    required super.monthlySales,
    required super.monthlySalesCount,
    required super.todayPurchases,
    required super.monthlyPurchases,
    required super.grossProfit,
    required super.pendingReceivables,
    required super.pendingPayables,
    required super.expiringSoonCount,
    required super.lowStockCount,
    required super.todaySalesTarget,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return DashboardStatsModel(
      totalProducts: _parseInt(stats['totalProducts']),
      totalVendors: _parseInt(stats['totalVendors']),
      totalCustomers: _parseInt(stats['totalCustomers']),
      inventoryValue: _parseDouble(stats['inventoryValue']),
      todaySales: _parseDouble(stats['todaySales']),
      todaySalesCount: _parseInt(stats['todaySalesCount']),
      monthlySales: _parseDouble(stats['monthlySales']),
      monthlySalesCount: _parseInt(stats['monthlySalesCount']),
      todayPurchases: _parseDouble(stats['todayPurchases']),
      monthlyPurchases: _parseDouble(stats['monthlyPurchases']),
      grossProfit: _parseDouble(stats['grossProfit']),
      pendingReceivables: _parseDouble(stats['pendingReceivables']),
      pendingPayables: _parseDouble(stats['pendingPayables']),
      expiringSoonCount: _parseInt(stats['expiringSoonCount']),
      lowStockCount: _parseInt(stats['lowStockCount']),
      todaySalesTarget: _parseDouble(stats['todaySalesTarget']),
    );
  }
}

class RecentTransactionModel extends RecentTransaction {
  const RecentTransactionModel({
    required super.id,
    required super.invoiceNumber,
    required super.type,
    super.customerName,
    super.vendorName,
    required super.totalAmount,
    required super.date,
    required super.status,
  });

  factory RecentTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecentTransactionModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      type: _detectType(json),
      customerName: json['customer']?['name'],
      vendorName: json['vendor']?['name'],
      totalAmount: _parseDouble(json['totalAmount']),
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: json['status'] ?? '',
    );
  }

  static String _detectType(Map<String, dynamic> json) {
    if (json.containsKey('customerId') || json.containsKey('customer')) return 'SALE';
    if (json.containsKey('vendorId') || json.containsKey('vendor')) return 'PURCHASE';
    return 'PAYMENT';
  }
}

class TopSellingProductModel extends TopSellingProduct {
  const TopSellingProductModel({
    required super.productId,
    required super.productName,
    required super.totalQuantity,
    required super.totalRevenue,
  });

  factory TopSellingProductModel.fromJson(Map<String, dynamic> json) {
    return TopSellingProductModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      totalQuantity: _parseInt(json['totalQuantity']),
      totalRevenue: _parseDouble(json['totalRevenue']),
    );
  }
}

class ChartDataPointModel extends ChartDataPoint {
  const ChartDataPointModel({
    required super.date,
    required super.amount,
    required super.count,
  });

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      date: json['date'] ?? '',
      amount: _parseDouble(json['amount']),
      count: _parseInt(json['count']),
    );
  }
}
