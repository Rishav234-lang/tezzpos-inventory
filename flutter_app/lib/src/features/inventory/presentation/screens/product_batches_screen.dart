import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';

final _productBatchesProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  final dio = ref.watch(dioProvider).dio;
  final response = await dio.get(
    ApiConstants.inventoryBatches,
    queryParameters: {'productId': productId, 'limit': 50},
  );
  return response.data as Map<String, dynamic>;
});

class ProductBatchesScreen extends ConsumerWidget {
  final String productId;

  const ProductBatchesScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(_productBatchesProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Product Batches'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: batchesAsync.when(
        data: (data) {
          final batches = (data['data'] as List<dynamic>?) ?? [];
          if (batches.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index] as Map<String, dynamic>;
              return _BatchCard(batch: batch);
            },
          );
        },
        loading: () => _buildShimmer(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 56, color: AppColors.outline),
          const SizedBox(height: 12),
          Text('No batches found', style: context.textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, _) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final Map<String, dynamic> batch;

  const _BatchCard({required this.batch});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateTimeFormat = DateFormat('dd MMM yyyy hh:mm a');

    final batchId = batch['id'] as String?;
    final batchNumber = batch['batchNumber'] ?? 'N/A';
    final status = batch['status'] ?? 'ACTIVE';
    final purchasedQty = batch['purchasedQuantity'] as int? ?? 0;
    final availableQty = batch['availableQuantity'] as int? ?? 0;
    final soldQty = purchasedQty - availableQty;
    final purchasePrice = (batch['purchasePrice'] as num?)?.toDouble() ?? 0.0;
    final mrp = (batch['mrp'] as num?)?.toDouble() ?? 0.0;
    final productName = (batch['product'] as Map<String, dynamic>?)?['name'] ?? 'N/A';
    final productSku = (batch['product'] as Map<String, dynamic>?)?['sku'] ?? '';
    final vendorName = (batch['vendor'] as Map<String, dynamic>?)?['name'] ?? 'N/A';
    final invoiceNumber = (batch['purchase'] as Map<String, dynamic>?)?['invoiceNumber'] ?? 'N/A';

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

    return InkWell(
      onTap: batchId != null ? () => context.push('${AppRoutes.batchDetail}/$batchId') : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.layers_outlined, size: 22, color: Color(0xFF388E3C)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Batch No.', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
                            Text(batchNumber, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'ACTIVE' ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status == 'ACTIVE' ? 'Active' : 'Depleted',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: status == 'ACTIVE' ? const Color(0xFF388E3C) : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Product', value: '$productName ($productSku)'),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Vendor', value: vendorName),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Purchase Invoice', value: invoiceNumber),
                  if (purchaseDate != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Purchase Date', value: dateFormat.format(purchaseDate)),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MetricBox(label: 'Purchase Price', value: '₹ ${currency.format(purchasePrice)}'),
                  _MetricBox(label: 'MRP', value: '₹ ${currency.format(mrp)}'),
                  _MetricBox(
                    label: 'Expiry Date',
                    value: expiryDate != null ? dateFormat.format(expiryDate) : 'N/A',
                    valueColor: expiryColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _MetricBox(label: 'Purchased Qty', value: '$purchasedQty pcs'),
                  _MetricBox(label: 'Available Qty', value: '$availableQty pcs', valueColor: const Color(0xFF388E3C)),
                  _MetricBox(label: 'Sold Qty', value: '$soldQty pcs'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  if (createdAt != null)
                    Text(
                      'Created On  ${dateTimeFormat.format(createdAt)}',
                      style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
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
          Text(label, style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            value,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
