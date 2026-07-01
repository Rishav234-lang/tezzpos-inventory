import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        data: (product) => _buildContent(context, ref, product),
        loading: () => _buildShimmer(context),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) => _buildBottomActions(context, ref, product),
        loading: () => null,
        error: (error, stackTrace) => null,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Product product) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Product Details'),
          actions: [
            IconButton(
              onPressed: () => _showOptions(context, ref, product),
              icon: const Icon(Icons.more_vert),
            ),
          ],
          floating: true,
          snap: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          image: product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    product.imageUrl!.startsWith('http')
                                        ? product.imageUrl!
                                        : '${ApiConstants.baseUrl}${product.imageUrl!}',
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {},
                                )
                              : null,
                        ),
                        child: product.imageUrl == null ||
                                product.imageUrl!.isEmpty
                            ? Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: product.isActive
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.isActive ? 'Active' : 'Inactive',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: product.isActive
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${product.sku ?? 'N/A'}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.categoryName ?? 'Uncategorized',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Price & stock cards
                Row(
                  children: [
                    _buildInfoCard(context, label: 'Cost Price',
                        value: '₹ ${NumberFormat('#,##,##0.00').format(product.costPrice)}'),
                    const SizedBox(width: 8),
                    _buildInfoCard(context, label: 'Selling Price',
                        value: '₹ ${NumberFormat('#,##,##0.00').format(product.sellingPrice)}', highlight: true),
                    const SizedBox(width: 8),
                    _buildInfoCard(context, label: 'MRP',
                        value: product.firstMrp != null
                            ? '₹ ${NumberFormat('#,##,##0.00').format(product.firstMrp)}'
                            : '—'),
                    const SizedBox(width: 8),
                    _buildInfoCard(context, label: 'In Stock',
                        value: '${product.totalStock}',
                        valueColor: product.isOutOfStock
                            ? AppColors.error
                            : product.isLowStock
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32)),
                  ],
                ),
                const SizedBox(height: 20),
                // Product Information card
                _buildSectionTitle('Product Information'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      _buildBarcodeRow(context, product.barcode),
                      const Divider(height: 16, thickness: 0.5),
                      _buildInfoRow('Category', product.categoryName ?? 'Uncategorized'),
                      const Divider(height: 16, thickness: 0.5),
                      _buildInfoRow('Unit', product.unit),
                      if (product.hsnCode != null && product.hsnCode!.isNotEmpty) ...[
                        const Divider(height: 16, thickness: 0.5),
                        _buildInfoRow('HSN Code', product.hsnCode!),
                      ],
                      const Divider(height: 16, thickness: 0.5),
                      _buildInfoRow('GST Rate', '${product.gstRate.toStringAsFixed(0)}%'),
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        const Divider(height: 16, thickness: 0.5),
                        _buildInfoRow('Description', product.description!, multiLine: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Inventory card
                _buildSectionTitle('Inventory'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Available Stock', '${product.totalStock}',
                          valueColor: product.isOutOfStock
                              ? AppColors.error
                              : product.isLowStock
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF2E7D32)),
                      const Divider(height: 16, thickness: 0.5),
                      _buildInfoRow('Reorder Level', '${product.minStockLevel}'),
                      const Divider(height: 16, thickness: 0.5),
                      _buildInfoRow('Stock Value (Cost)',
                          '₹ ${NumberFormat('#,##,##0.00').format(product.stockValue)}'),
                      if (product.stockValueMrp > 0) ...[
                        const Divider(height: 16, thickness: 0.5),
                        _buildInfoRow('Stock Value (MRP)',
                            '₹ ${NumberFormat('#,##,##0.00').format(product.stockValueMrp)}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Timestamps card
                _buildSectionTitle('Timestamps'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Created On', dateFormat.format(product.createdAt)),
                      const Divider(height: 16, thickness: 0.5),
                      _buildInfoRow('Last Updated', dateFormat.format(product.updatedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String label, required String value, bool highlight = false, Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.primary.withValues(alpha: 0.25) : AppColors.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? (highlight ? AppColors.primary : AppColors.onSurface),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      ],
    );
  }

  Widget _buildBarcodeRow(BuildContext context, String? barcode) {
    final display = barcode ?? 'N/A';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Barcode', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        GestureDetector(
          onTap: barcode != null
              ? () {
                  Clipboard.setData(ClipboardData(text: barcode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barcode copied to clipboard'), duration: Duration(seconds: 1)),
                  );
                }
              : null,
          child: Row(
            children: [
              Text(display,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              if (barcode != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.content_copy, size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool multiLine = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.onSurface),
              textAlign: TextAlign.end,
              maxLines: multiLine ? 3 : 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, Product product) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context
                    .push('${AppRoutes.editProduct}/${product.id}'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirm(context, ref, product),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Product'),
              onTap: () {
                context.pop();
                context.push('${AppRoutes.editProduct}/${product.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Product'),
              onTap: () {
                context.pop();
                _showDeleteConfirm(context, ref, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete\n"${product.name}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    context.pop();
                    await ref
                        .read(productNotifierProvider.notifier)
                        .deleteProduct(product.id);
                    if (!context.mounted) return;
                    final notifierState = ref.read(productNotifierProvider);
                    if (notifierState.hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${notifierState.error}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } else {
                      ref.invalidate(productsProvider);
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product deleted')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ))),
                const SizedBox(width: 12),
                Expanded(
                    child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ))),
                const SizedBox(width: 12),
                Expanded(
                    child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ))),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 16, width: 120, color: AppColors.surface),
            const SizedBox(height: 12),
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 12, width: 80, color: AppColors.surface),
                    Container(height: 12, width: 100, color: AppColors.surface),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
