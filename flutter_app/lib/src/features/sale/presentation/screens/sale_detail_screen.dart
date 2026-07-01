import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/sale_providers.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final currency = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Sale Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: saleAsync.when(
        data: (sale) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, sale),
              const SizedBox(height: 16),
              _buildStatsRow(context, sale, currency),
              const SizedBox(height: 16),
              _buildItemsSection(context, sale, currency),
              const SizedBox(height: 16),
              _buildTotalsSection(context, sale, currency),
              const SizedBox(height: 100),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: saleAsync.when(
        data: (sale) => _buildBottomBar(context, sale),
        loading: () => null,
        error: (_, _) => null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              sale.customer?.name.isNotEmpty == true ? sale.customer!.name[0].toUpperCase() : 'W',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customer?.name ?? 'Walk-in Customer',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(sale.customer?.mobile ?? '', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(sale.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sale.status,
              style: TextStyle(color: _statusColor(sale.status), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFF2E7D32);
      case 'PARTIAL':
        return const Color(0xFFEF6C00);
      default:
        return AppColors.error;
    }
  }

  Widget _buildStatsRow(BuildContext context, sale, NumberFormat currency) {
    return Row(
      children: [
        _buildStatCard('Total Amount', '₹ ${currency.format(sale.totalAmount)}', const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _buildStatCard('Total Paid', '₹ ${currency.format(sale.paidAmount)}', const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        _buildStatCard('Outstanding', '₹ ${currency.format(sale.balanceAmount)}', AppColors.error),
        const SizedBox(width: 10),
        _buildStatCard('Total Items', '${sale.totalQuantity}', const Color(0xFF6A1B9A)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, sale, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sale.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${item.quantity} × ₹ ${currency.format(item.sellingPrice)}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹ ${currency.format(item.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (item.taxAmount > 0)
                        Text('Tax: ₹ ${currency.format(item.taxAmount)}', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(BuildContext context, sale, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', sale.subtotal, currency),
          _buildTotalRow('Discount', sale.discount, currency),
          _buildTotalRow('Tax', sale.taxAmount, currency),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹ ${currency.format(sale.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, NumberFormat currency) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          Text('₹ ${currency.format(value)}', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, sale) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('${AppRoutes.billInvoice}/$saleId'),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Bill'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.push('${AppRoutes.saleReturn}/$saleId'),
              icon: const Icon(Icons.assignment_return, size: 18),
              label: const Text('Return'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('${AppRoutes.receivePayment}/${sale.customer?.id ?? ''}'),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
