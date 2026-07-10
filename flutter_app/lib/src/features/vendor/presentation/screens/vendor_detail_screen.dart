import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../purchase/presentation/providers/purchase_providers.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMakePaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Vendor vendor,
  ) {
    final amountController = TextEditingController();
    String selectedMethod = 'CASH';
    final methods = ['CASH', 'BANK_TRANSFER', 'UPI', 'CHEQUE'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Payment to ${vendor.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: methods
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setModalState(() => selectedMethod = v ?? 'CASH'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await ref
                        .read(purchaseNotifierProvider.notifier)
                        .recordPayment({
                          'vendorId': widget.vendorId,
                          'amount': amount,
                          'paymentMethod': selectedMethod,
                          'paymentDate': DateTime.now().toIso8601String(),
                        });
                    if (!context.mounted) return;
                    final state = ref.read(purchaseNotifierProvider);
                    if (state.hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${state.error}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } else {
                      ref.invalidate(vendorLedgerProvider(widget.vendorId));
                      ref.invalidate(vendorDetailProvider(widget.vendorId));
                      ref.invalidate(vendorsProvider);
                      ref.invalidate(purchasesProvider);
                      ref.invalidate(dashboardStatsProvider);
                      ref.invalidate(recentPurchasesProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment recorded successfully'),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Record Payment',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));
    final ledgerAsync = ref.watch(vendorLedgerProvider(widget.vendorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: vendorAsync.when(
        data: (vendor) => _buildContent(context, ref, vendor, ledgerAsync),
        loading: () => _buildShimmer(context),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: vendorAsync.when(
        data: (vendor) => _buildBottomActions(context, ref, vendor),
        loading: () => null,
        error: (error, stackTrace) => null,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Vendor vendor,
    AsyncValue<Map<String, dynamic>> ledgerAsync,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Supplier'),
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          actions: [
            IconButton(
              onPressed: () => _showOptions(context, ref, vendor),
              icon: const Icon(Icons.more_vert),
            ),
          ],
          floating: true,
          snap: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Purchases'),
              Tab(text: 'Stock'),
              Tab(text: 'Payments'),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                _buildHeaderCard(context, vendor),
                const SizedBox(height: 16),
                // Summary cards with real ledger data
                _buildSummaryCards(context, ledgerAsync),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, vendor, ledgerAsync),
              _buildPurchasesTab(context, ledgerAsync),
              _buildBatchesTab(context, ledgerAsync),
              _buildPaymentsTab(context, ledgerAsync),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Vendor vendor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    vendor.initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vendor.name,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: vendor.isActive
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vendor.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: vendor.isActive
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF757575),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GSTIN: ${vendor.gstNumber ?? 'N/A'}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Contact rows with icons
          if (vendor.mobile != null && vendor.mobile!.isNotEmpty)
            _buildContactRow(Icons.phone, vendor.mobile!),
          if (vendor.email != null && vendor.email!.isNotEmpty)
            _buildContactRow(Icons.email, vendor.email!),
          if (vendor.address != null && vendor.address!.isNotEmpty)
            _buildContactRow(Icons.location_on, vendor.address!),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> ledgerAsync,
  ) {
    final ledger = ledgerAsync.valueOrNull;
    final totalPurchase = ledger?['totalPurchaseAmount'] ?? 0;
    final totalPaid = ledger?['totalPaidAmount'] ?? 0;
    final outstanding = ledger?['outstandingBalance'] ?? 0;
    final purchases = (ledger?['purchases'] as List<dynamic>?) ?? [];
    final totalCount = purchases.length;

    final fmt = NumberFormat('#,##,##0');

    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              context,
              label: 'Total Purchase',
              value: fmt.format(
                totalPurchase is num ? totalPurchase.toDouble() : 0,
              ),
              icon: Icons.receipt_outlined,
              iconBg: AppColors.primaryContainer,
              iconColor: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              label: 'Total Paid',
              value: fmt.format(totalPaid is num ? totalPaid.toDouble() : 0),
              icon: Icons.payments_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              context,
              label: 'Outstanding',
              value: fmt.format(
                outstanding is num ? outstanding.toDouble() : 0,
              ),
              icon: Icons.warning_amber_outlined,
              iconBg: const Color(0xFFFFEBEE),
              iconColor: const Color(0xFFC62828),
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              label: 'Total Purchases',
              value: '$totalCount',
              icon: Icons.shopping_basket_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Vendor vendor,
    AsyncValue<Map<String, dynamic>> ledgerAsync,
  ) {
    return ledgerAsync.when(
      data: (ledger) {
        final purchases = (ledger['purchases'] as List<dynamic>?) ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outstanding Summary
              if (purchases.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Outstanding Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.purchases),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...purchases.take(3).map((p) {
                  final purchase = p as Map<String, dynamic>;
                  return _buildPurchaseRow(purchase, showStatus: true);
                }),
                const SizedBox(height: 20),
              ],
              // Recent Purchases
              if (purchases.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Purchases',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.purchases),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...purchases.take(1).map((p) {
                  final purchase = p as Map<String, dynamic>;
                  return _buildPurchaseRow(purchase, showStatus: true);
                }),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildPurchasesTab(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> ledgerAsync,
  ) {
    return ledgerAsync.when(
      data: (ledger) {
        final purchases = (ledger['purchases'] as List<dynamic>?) ?? [];
        if (purchases.isEmpty) {
          return const Center(
            child: Text(
              'No purchases found',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index] as Map<String, dynamic>;
            return _buildPurchaseCard(context, purchase);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    Map<String, dynamic> purchase,
  ) {
    final status = purchase['status'] as String? ?? 'UNPAID';
    final totalVal = _toDouble(purchase['totalAmount']);
    final paidVal = _toDouble(purchase['paidAmount']);
    final due = totalVal - paidVal;
    final date = purchase['purchaseDate'] != null
        ? DateTime.parse(purchase['purchaseDate'] as String)
        : DateTime.now();
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';
    final items = (purchase['items'] as List<dynamic>?)?.length ?? 0;

    Color statusColor;
    String statusText;
    if (status == 'PAID') {
      statusColor = const Color(0xFF2E7D32);
      statusText = 'Paid';
    } else if (due > 0 && paidVal > 0) {
      statusColor = const Color(0xFFE65100);
      statusText = 'Partial';
    } else {
      statusColor = const Color(0xFFC62828);
      statusText = 'Unpaid';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                purchase['invoiceNumber'] as String? ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹ ${NumberFormat('#,##,##0').format(totalVal)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildPurchaseMiniCol('Items', '$items')),
              Expanded(
                child: _buildPurchaseMiniCol(
                  'Paid',
                  '₹ ${NumberFormat('#,##,##0').format(paidVal)}',
                  valueColor: const Color(0xFF2E7D32),
                ),
              ),
              Expanded(
                child: _buildPurchaseMiniCol(
                  'Due',
                  '₹ ${NumberFormat('#,##,##0').format(due)}',
                  valueColor: due > 0
                      ? const Color(0xFFC62828)
                      : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseMiniCol(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseRow(
    Map<String, dynamic> purchase, {
    bool showStatus = true,
  }) {
    final status = purchase['status'] as String? ?? 'UNPAID';
    final totalVal = _toDouble(purchase['totalAmount']);
    final paidVal = _toDouble(purchase['paidAmount']);
    final due = totalVal - paidVal;
    final date = purchase['purchaseDate'] != null
        ? DateTime.parse(purchase['purchaseDate'] as String)
        : DateTime.now();
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';

    Color statusColor;
    String statusText;
    if (status == 'PAID') {
      statusColor = const Color(0xFF2E7D32);
      statusText = 'Paid';
    } else if (due > 0 && paidVal > 0) {
      statusColor = const Color(0xFFE65100);
      statusText = 'Due ₹${NumberFormat('#,##,##0').format(due)}';
    } else {
      statusColor = const Color(0xFFC62828);
      statusText = 'Due ₹${NumberFormat('#,##,##0').format(due)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                purchase['invoiceNumber'] as String? ?? 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${NumberFormat('#,##,##0').format(totalVal)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              if (showStatus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesTab(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> ledgerAsync,
  ) {
    return ledgerAsync.when(
      data: (ledger) {
        final purchases = (ledger['purchases'] as List<dynamic>?) ?? [];
        final allBatches = <Map<String, dynamic>>[];
        for (final p in purchases) {
          final purchase = p as Map<String, dynamic>;
          final batches = (purchase['batches'] as List<dynamic>?) ?? [];
          for (final b in batches) {
            final batch = b as Map<String, dynamic>;
            allBatches.add({
              ...batch,
              'invoiceNumber': purchase['invoiceNumber'] ?? 'N/A',
              'purchaseDate': purchase['purchaseDate'],
            });
          }
        }
        if (allBatches.isEmpty) {
          return const Center(
            child: Text(
              'No stock details found',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: allBatches.length,
          itemBuilder: (context, index) {
            return _buildBatchCard(context, allBatches[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildBatchCard(BuildContext context, Map<String, dynamic> batch) {
    final batchNumber = batch['batchNumber'] as String? ?? 'N/A';
    final expiryDate = batch['expiryDate'] != null
        ? DateTime.parse(batch['expiryDate'] as String)
        : null;
    final expiryStr = expiryDate != null
        ? '${expiryDate.day} ${_monthName(expiryDate.month)} ${expiryDate.year}'
        : 'N/A';
    final qty = batch['availableQuantity'] ?? 0;
    final price = _toDouble(batch['purchasePrice']);
    final status = batch['status'] as String? ?? 'ACTIVE';
    final invoice = batch['invoiceNumber'] as String? ?? 'N/A';

    final isActive = status == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batch: $batchNumber',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Invoice: $invoice',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildBatchMiniCol('Qty', '$qty')),
              Expanded(
                child: _buildBatchMiniCol(
                  'Purchase Price',
                  '₹ ${_formatAmount(price)}',
                ),
              ),
              Expanded(child: _buildBatchMiniCol('Expiry', expiryStr)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchMiniCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> ledgerAsync,
  ) {
    return ledgerAsync.when(
      data: (ledger) {
        final payments = (ledger['payments'] as List<dynamic>?) ?? [];
        if (payments.isEmpty) {
          return const Center(
            child: Text(
              'No payments found',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index] as Map<String, dynamic>;
            return _buildPaymentCard(context, payment);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> payment) {
    final amount = _toDouble(payment['amount']);
    final method = payment['paymentMethod'] as String? ?? 'CASH';
    final date = payment['paymentDate'] != null
        ? DateTime.parse(payment['paymentDate'] as String)
        : DateTime.now();
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';
    final note = payment['notes'] as String?;

    IconData methodIcon;
    switch (method) {
      case 'UPI':
        methodIcon = Icons.account_balance_wallet_outlined;
        break;
      case 'CARD':
        methodIcon = Icons.credit_card_outlined;
        break;
      case 'BANK_TRANSFER':
        methodIcon = Icons.account_balance_outlined;
        break;
      case 'CHEQUE':
        methodIcon = Icons.note_outlined;
        break;
      default:
        methodIcon = Icons.payments_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(methodIcon, color: const Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment via ${method.replaceAll('_', ' ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '₹ ${_formatAmount(amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${NumberFormat('#,##,##0.##').format(amount / 100000)}L';
    }
    if (amount >= 1000) return NumberFormat('#,##,##0').format(amount);
    return amount.toStringAsFixed(0);
  }

  Widget _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    Vendor vendor,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.addPurchase),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Purchase'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _showMakePaymentDialog(context, ref, vendor),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Make Payment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('${AppRoutes.editVendor}/${vendor.id}'),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Vendor'),
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
                    onPressed: () => _showDeleteConfirm(context, ref, vendor),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Vendor'),
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
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, Vendor vendor) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Vendor'),
              onTap: () {
                context.pop();
                context.push('${AppRoutes.editVendor}/${vendor.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Vendor'),
              onTap: () {
                context.pop();
                _showDeleteConfirm(context, ref, vendor);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, Vendor vendor) {
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
                'Delete Vendor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete\n"${vendor.name}"?',
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
                        .read(vendorNotifierProvider.notifier)
                        .deleteVendor(vendor.id);
                    if (!context.mounted) return;
                    final notifierState = ref.read(vendorNotifierProvider);
                    if (notifierState.hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${notifierState.error}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } else {
                      ref.invalidate(vendorsProvider);
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vendor deleted')),
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
                      color: AppColors.outline.withValues(alpha: 0.5),
                    ),
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
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
