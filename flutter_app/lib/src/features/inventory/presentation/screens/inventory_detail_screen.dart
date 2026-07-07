import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final String productId;

  const InventoryDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        data: (product) => _buildContent(context, ref, product),
        loading: () => _buildShimmer(context),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) => _buildBottomBar(context, product),
        loading: () => null,
        error: (_, _) => null,
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune, color: AppColors.primary),
              title: const Text('Adjust Stock'),
              onTap: () {
                ctx.pop();
                context.push(AppRoutes.stockAdjustment);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.view_list_outlined,
                color: AppColors.primary,
              ),
              title: const Text('View Stock Details'),
              onTap: () {
                ctx.pop();
                context.push('${AppRoutes.productBatches}/$productId');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Edit Product'),
              onTap: () {
                ctx.pop();
                context.push('${AppRoutes.editProduct}/$productId');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Product product) {
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    final stockValue = product.stockValue;
    final stockValueMrp = product.stockValueMrp;

    String expiryAlert;
    Color expiryColor;
    if (product.firstExpiryDate == null) {
      expiryAlert = 'No Expiry Soon';
      expiryColor = const Color(0xFF388E3C);
    } else {
      final diff = product.firstExpiryDate!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        expiryAlert = 'Expired';
        expiryColor = AppColors.error;
      } else if (diff == 0) {
        expiryAlert = 'Expires Today!';
        expiryColor = AppColors.error;
      } else if (diff <= 7) {
        expiryAlert = 'Expires in $diff days';
        expiryColor = AppColors.error;
      } else if (diff <= 30) {
        expiryAlert = 'Expires in $diff days';
        expiryColor = const Color(0xFFE65100);
      } else {
        expiryAlert = 'No Expiry Soon';
        expiryColor = const Color(0xFF388E3C);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Stock Details'),
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          actions: [
            IconButton(
              onPressed: () =>
                  context.push('${AppRoutes.editProduct}/$productId'),
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            ),
            IconButton(
              onPressed: () => _showOptions(context),
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
                _buildHeaderCard(context, product),
                const SizedBox(height: 16),

                // Quick metrics row
                _buildQuickMetrics(context, product, currency),
                const SizedBox(height: 20),

                // Stock Overview
                _buildSectionTitle(context, 'Stock Summary'),
                const SizedBox(height: 12),
                _buildStockOverview(
                  context,
                  product,
                  currency,
                  dateFormat,
                  stockValue,
                  stockValueMrp,
                  expiryAlert,
                  expiryColor,
                ),
                const SizedBox(height: 20),

                // Actions
                _buildSectionTitle(context, 'Actions'),
                const SizedBox(height: 12),
                _buildActions(context, product),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Product product) {
    String statusText;
    Color statusBg;
    Color statusFg;
    if (product.isOutOfStock) {
      statusText = 'Out of Stock';
      statusBg = const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFC62828);
    } else if (product.isLowStock) {
      statusText = 'Low Stock';
      statusBg = const Color(0xFFFFF3E0);
      statusFg = const Color(0xFFE65100);
    } else {
      statusText = 'In Stock';
      statusBg = const Color(0xFFE8F5E9);
      statusFg = const Color(0xFF2E7D32);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        product.imageUrl!.startsWith('http')
                            ? product.imageUrl!
                            : '${ApiConstants.baseUrl}${product.imageUrl!}',
                      ),
                      fit: BoxFit.contain,
                      onError: (_, _) {},
                    )
                  : null,
            ),
            child: product.imageUrl == null || product.imageUrl!.isEmpty
                ? Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.sku ?? 'N/A'}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Barcode: ${product.barcode ?? 'N/A'}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LabelValue(
                      label: 'Category',
                      value: product.categoryName ?? 'N/A',
                    ),
                    const SizedBox(width: 24),
                    _LabelValue(label: 'Unit', value: product.unit),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: context.textTheme.labelSmall?.copyWith(
                color: statusFg,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetrics(
    BuildContext context,
    Product product,
    NumberFormat currency,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _QuickMetric(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            value: '${product.totalStock}',
            label: 'In Stock',
          ),
          _divider(),
          _QuickMetric(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF388E3C),
            iconBg: const Color(0xFFE8F5E9),
            value: '₹ ${currency.format(product.stockValue)}',
            label: 'Stock Value',
          ),
          _divider(),
          _QuickMetric(
            icon: Icons.shopping_cart_outlined,
            iconColor: const Color(0xFFF57C00),
            iconBg: const Color(0xFFFFF3E0),
            value: '₹ ${currency.format(product.costPrice)}',
            label: 'Purchase Price',
          ),
          _divider(),
          _QuickMetric(
            icon: Icons.sell_outlined,
            iconColor: const Color(0xFF6A1B9A),
            iconBg: const Color(0xFFF3E5F5),
            value: product.firstMrp != null
                ? '₹ ${currency.format(product.firstMrp)}'
                : 'N/A',
            label: 'MRP',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 48,
    color: AppColors.outline.withValues(alpha: 0.15),
  );

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStockOverview(
    BuildContext context,
    Product product,
    NumberFormat currency,
    DateFormat dateFormat,
    double stockValue,
    double stockValueMrp,
    String expiryAlert,
    Color expiryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _OverviewRow(
            label: 'Low Stock Level',
            value: '${product.minStockLevel} pcs',
          ),
          const Divider(height: 20),
          _OverviewRow(
            label: 'In Stock',
            value: '${product.totalStock} pcs',
            valueColor: const Color(0xFF388E3C),
          ),
          const Divider(height: 20),
          _OverviewRow(
            label: 'Stock Value (Cost)',
            value: '₹ ${currency.format(stockValue)}',
          ),
          const Divider(height: 20),
          _OverviewRow(
            label: 'Stock Value (MRP)',
            value: '₹ ${currency.format(stockValueMrp)}',
          ),
          if (product.firstExpiryDate != null) ...[
            const Divider(height: 20),
            _OverviewRow(
              label: 'Expiry Date',
              value: dateFormat.format(product.firstExpiryDate!),
            ),
          ],
          const Divider(height: 20),
          _OverviewRow(
            label: 'Expiry Alert',
            value: expiryAlert,
            valueColor: expiryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Product product) {
    final actions = [
      _ActionData(
        icon: Icons.tune,
        label: 'Stock\nAdjustment',
        iconBg: AppColors.primaryContainer,
        iconColor: AppColors.primary,
        onTap: () => context.push('${AppRoutes.stockAdjustment}/${product.id}'),
      ),
      _ActionData(
        icon: Icons.layers_outlined,
        label: 'Stock\nDetails',
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF388E3C),
        onTap: () => context.push('${AppRoutes.productBatches}/${product.id}'),
      ),
      _ActionData(
        icon: Icons.add_shopping_cart_outlined,
        label: 'Add\nPurchase',
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        onTap: () => context.push(AppRoutes.addPurchase),
      ),
      _ActionData(
        icon: Icons.history,
        label: 'Sales\nHistory',
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF6A1B9A),
        onTap: () => context.push(AppRoutes.salesHistory),
      ),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: a.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: a.iconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(a.icon, size: 20, color: a.iconColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.label,
                            textAlign: TextAlign.center,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () =>
            context.push('${AppRoutes.stockAdjustment}/${product.id}'),
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text(
          'Adjust Stock',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            5,
            (_) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _QuickMetric({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _OverviewRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}
