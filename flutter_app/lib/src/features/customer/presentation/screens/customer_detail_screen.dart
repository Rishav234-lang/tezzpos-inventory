import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_providers.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  late final _customerAsync = ref.watch(customerDetailProvider(widget.customerId));
  late final _ledgerAsync = ref.watch(customerLedgerProvider(widget.customerId));
  late final _salesAsync = ref.watch(customerSalesProvider(widget.customerId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: _customerAsync.when(
        data: (customer) => _buildContent(context, customer),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _customerAsync.when(
        data: (customer) => _buildBottomBar(context, customer),
        loading: () => null,
        error: (_, _) => null,
      ),
    );
  }

  Widget _buildContent(BuildContext context, Customer customer) {
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, customer),
          const SizedBox(height: 16),
          _buildInfoCard(context, customer, dateFormat),
          const SizedBox(height: 20),
          _buildStatsRow(context, customer, currency),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Recent Invoices'),
          const SizedBox(height: 8),
          _buildRecentInvoices(context, currency),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Outstanding Invoices'),
          const SizedBox(height: 8),
          _buildOutstandingInvoices(context, currency),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Payment History'),
          const SizedBox(height: 8),
          _buildPaymentHistory(context, currency),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(
              customer.initials,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.mobile ?? 'No mobile',
                  style: context.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                if (customer.gstNumber != null && customer.gstNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GSTIN: ${customer.gstNumber}',
                    style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: customer.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              customer.isActive ? 'Active' : 'Inactive',
              style: context.textTheme.labelSmall?.copyWith(
                color: customer.isActive ? const Color(0xFF2E7D32) : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Customer customer, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Information', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildInfoRow('Email', customer.email ?? 'Not provided'),
          if (customer.gstNumber != null && customer.gstNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('GST Number', customer.gstNumber!),
          ],
          if (customer.address != null && customer.address!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Address', customer.address!),
          ],
          const SizedBox(height: 12),
          _buildInfoRow('Created On', dateFormat.format(customer.createdAt)),
          const SizedBox(height: 12),
          _buildInfoRow('Last Updated', dateFormat.format(customer.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, Customer customer, NumberFormat currency) {
    return Row(
      children: [
        _buildStatCard('Total Purchases', '₹ ${currency.format(customer.totalPurchaseAmount)}', const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _buildStatCard('Total Paid', '₹ ${currency.format(customer.totalPaidAmount)}', const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        _buildStatCard('Outstanding', '₹ ${currency.format(customer.outstandingBalance)}', AppColors.error),
        const SizedBox(width: 10),
        _buildStatCard('Total Orders', _orderCountText, const Color(0xFF6A1B9A)),
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
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Text(title, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton(
          onPressed: () => _showComingSoon(),
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices(BuildContext context, NumberFormat currency) {
    return _salesAsync.when(
      data: (data) {
        final sales = (data['data'] as List<dynamic>?) ?? [];
        if (sales.isEmpty) return _buildEmptyBox('No recent invoices');
        return Column(
          children: sales.take(3).map((s) => _buildInvoiceTile(s as Map<String, dynamic>, currency)).toList(),
        );
      },
      loading: () => _buildShimmerBox(),
      error: (_, _) => _buildEmptyBox('Could not load invoices'),
    );
  }

  Widget _buildOutstandingInvoices(BuildContext context, NumberFormat currency) {
    return _ledgerAsync.when(
      data: (data) {
        final sales = (data['sales'] as List<dynamic>?) ?? [];
        final outstanding = sales.where((s) => (s as Map<String, dynamic>)['status'] != 'PAID').toList();
        if (outstanding.isEmpty) return _buildEmptyBox('No outstanding invoices');
        return Column(
          children: outstanding.take(3).map((s) => _buildInvoiceTile(s as Map<String, dynamic>, currency, isOutstanding: true)).toList(),
        );
      },
      loading: () => _buildShimmerBox(),
      error: (_, _) => _buildEmptyBox('Could not load outstanding invoices'),
    );
  }

  Widget _buildPaymentHistory(BuildContext context, NumberFormat currency) {
    return _ledgerAsync.when(
      data: (data) {
        final payments = (data['payments'] as List<dynamic>?) ?? [];
        if (payments.isEmpty) return _buildEmptyBox('No payment history');
        return Column(
          children: payments.take(3).map((p) => _buildPaymentTile(p as Map<String, dynamic>, currency)).toList(),
        );
      },
      loading: () => _buildShimmerBox(),
      error: (_, _) => _buildEmptyBox('Could not load payments'),
    );
  }

  Widget _buildInvoiceTile(Map<String, dynamic> sale, NumberFormat currency, {bool isOutstanding = false}) {
    final status = sale['status'] ?? 'UNPAID';
    final total = (sale['totalAmount'] as num?)?.toDouble() ?? 0;
    final paid = (sale['paidAmount'] as num?)?.toDouble() ?? 0;
    final due = total - paid;
    final date = sale['invoiceDate'] != null ? DateTime.tryParse(sale['invoiceDate']) : null;
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A';

    Color statusColor;
    switch (status) {
      case 'PAID':
        statusColor = const Color(0xFF2E7D32);
        break;
      case 'PARTIAL':
        statusColor = const Color(0xFFEF6C00);
        break;
      default:
        statusColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale['invoiceNumber'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                if (isOutstanding && due > 0) ...[
                  const SizedBox(height: 4),
                  Text('Due: ₹ ${currency.format(due)}', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹ ${currency.format(total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> payment, NumberFormat currency) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final date = payment['paymentDate'] != null ? DateTime.tryParse(payment['paymentDate']) : null;
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A';
    final method = payment['paymentMethod'] ?? 'CASH';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payment, color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Received Payment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$dateStr • $method', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text('₹ ${currency.format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: AppColors.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildShimmerBox() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Customer customer) {
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
              onPressed: () => context.push('${AppRoutes.editCustomer}/${customer.id}'),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
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
              onPressed: () => context.push('${AppRoutes.receivePayment}/${customer.id}'),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Receive Payment'),
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
              onPressed: () => _showComingSoon(),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share Ledger'),
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

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('${AppRoutes.editCustomer}/${widget.customerId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: AppColors.success),
              title: const Text('Receive Payment'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('${AppRoutes.receivePayment}/${widget.customerId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Customer'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(customerNotifierProvider.notifier).deleteCustomer(widget.customerId);
    if (!mounted) return;
    ref.invalidate(customersProvider(CustomerFilter()));
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  String get _orderCountText {
    if (!_salesAsync.hasValue) return '...';
    final data = _salesAsync.valueOrNull;
    if (data == null) return '0';
    return '${((data['data'] as List<dynamic>?) ?? []).length}';
  }
}
