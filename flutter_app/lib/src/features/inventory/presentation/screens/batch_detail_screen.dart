import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';

final _batchDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, batchId) async {
  final dio = ref.watch(dioProvider).dio;
  final response = await dio.get('${ApiConstants.inventoryBatches}/$batchId');
  return response.data as Map<String, dynamic>;
});

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is num) return value.toInt();
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is num) return value.toDouble();
  return 0.0;
}

class BatchDetailScreen extends ConsumerWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(_batchDetailProvider(batchId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Batch Details'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_batchDetailProvider(batchId)),
        child: batchAsync.when(
          data: (data) => _buildContent(context, data),
          loading: () => _buildShimmer(),
          error: (e, _) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> batch) {
    final currency = NumberFormat('#,##,##0.00');
    final dateTimeFormat = DateFormat('dd MMM yyyy hh:mm a');

    final batchNumber = batch['batchNumber'] ?? 'N/A';
    final status = batch['status'] ?? 'ACTIVE';
    final purchasedQty = _toInt(batch['purchasedQuantity']);
    final availableQty = _toInt(batch['availableQuantity']);
    final soldQty = purchasedQty - availableQty;
    final purchasePrice = _toDouble(batch['purchasePrice']);
    final mrp = _toDouble(batch['mrp']);
    final product = batch['product'] as Map<String, dynamic>?;
    final unit = (product?['unit'] as String?)?.toLowerCase() ?? 'pcs';
    final vendor = batch['vendor'] as Map<String, dynamic>?;
    final purchase = batch['purchase'] as Map<String, dynamic>?;
    final saleItems = (batch['saleItems'] as List<dynamic>?) ?? [];

    DateTime? purchaseDate;
    if (batch['purchaseDate'] != null) {
      purchaseDate = DateTime.tryParse(batch['purchaseDate']);
    }
    DateTime? expiryDate;
    if (batch['expiryDate'] != null) {
      expiryDate = DateTime.tryParse(batch['expiryDate']);
    }
    DateTime? createdAt;
    if (batch['createdAt'] != null) {
      createdAt = DateTime.tryParse(batch['createdAt']);
    }

    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
    final isExpiringSoon = expiryDate != null && !isExpired && expiryDate.difference(DateTime.now()).inDays <= 30;

    Color expiryColor = AppColors.onSurface;
    if (isExpired) expiryColor = AppColors.error;
    if (isExpiringSoon) expiryColor = const Color(0xFFE65100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, batchNumber, status),
          const SizedBox(height: 16),
          _buildInfoCard(context, product, vendor, purchase, purchaseDate),
          const SizedBox(height: 16),
          _buildMetricsCard(context, purchasePrice, mrp, expiryDate, expiryColor, purchasedQty, availableQty, soldQty, unit),
          const SizedBox(height: 16),
          _buildStockMovementCard(context, dateTimeFormat, saleItems, currency, unit),
          if (createdAt != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Created On', dateTimeFormat.format(createdAt)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String batchNumber, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.layers_outlined, size: 28, color: Color(0xFF388E3C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch No.', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                Text(batchNumber, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'ACTIVE' ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status == 'ACTIVE' ? 'Active' : 'Depleted',
              style: context.textTheme.labelSmall?.copyWith(
                color: status == 'ACTIVE' ? const Color(0xFF388E3C) : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    Map<String, dynamic>? product,
    Map<String, dynamic>? vendor,
    Map<String, dynamic>? purchase,
    DateTime? purchaseDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Batch Information', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildInfoRow(context, 'Product', product != null ? '${product['name'] ?? 'N/A'} (${product['sku'] ?? ''})' : 'N/A'),
          _buildInfoRow(context, 'Vendor', vendor?['name'] ?? 'N/A'),
          _buildInfoRow(context, 'Purchase Invoice', purchase?['invoiceNumber'] ?? 'N/A'),
          _buildInfoRow(context, 'Purchase Date', purchaseDate != null ? DateFormat('dd MMM yyyy').format(purchaseDate) : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(
    BuildContext context,
    double purchasePrice,
    double mrp,
    DateTime? expiryDate,
    Color expiryColor,
    int purchasedQty,
    int availableQty,
    int soldQty,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Metrics', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          Row(
            children: [
              _MetricBox(label: 'Purchase Price', value: '₹ ${NumberFormat('#,##,##0.00').format(purchasePrice)}'),
              _MetricBox(label: 'MRP', value: '₹ ${NumberFormat('#,##,##0.00').format(mrp)}'),
              _MetricBox(
                label: 'Expiry Date',
                value: expiryDate != null ? DateFormat('dd MMM yyyy').format(expiryDate) : 'N/A',
                valueColor: expiryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricBox(label: 'Purchased Qty', value: '$purchasedQty $unit'),
              _MetricBox(label: 'Available Qty', value: '$availableQty $unit', valueColor: const Color(0xFF388E3C)),
              _MetricBox(label: 'Sold Qty', value: '$soldQty $unit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockMovementCard(
    BuildContext context,
    DateFormat dateTimeFormat,
    List<dynamic> saleItems,
    NumberFormat currency,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Movement', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          if (saleItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No sales recorded for this batch',
                  style: context.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          else
            Column(
              children: saleItems.map((item) {
                final sale = (item as Map<String, dynamic>)['sale'] as Map<String, dynamic>?;
                final quantity = _toInt(item['quantity']);
                final createdAt = item['createdAt'] != null ? DateTime.tryParse(item['createdAt']) : null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFFEF6C00), size: 20),
                  ),
                  title: Text(
                    sale?['invoiceNumber'] ?? 'Sale',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    createdAt != null ? dateTimeFormat.format(createdAt) : 'N/A',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  trailing: Text(
                    '-$quantity $unit',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.background,
        child: Column(
          children: [
            Container(height: 90, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 16),
            Container(height: 160, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 16),
            Container(height: 160, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.onSurface)),
        ],
      ),
    );
  }
}
