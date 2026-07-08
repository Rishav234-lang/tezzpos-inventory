import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/sale.dart';
import '../providers/sale_providers.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final current = ref.read(saleFilterProvider);
      ref.read(saleFilterProvider.notifier).state = current.copyWith(search: value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final currency = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Sale',
            onPressed: () => context.push(AppRoutes.sales),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(salesProvider),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search invoice no. or customer...',
                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          color: AppColors.onSurfaceVariant,
                          onPressed: () {
                            _searchController.clear();
                            ref.read(saleFilterProvider.notifier).state = SaleFilter();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ),
          ),
          _buildFilterChips(),
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return _SaleTile(sale: sale, currency: currency);
                  },
                );
              },
              loading: () => _buildShimmer(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildFilterChips() {
    final filter = ref.watch(saleFilterProvider);
    final options = ['All', 'Paid', 'Unpaid', 'Credit'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final statusMap = {'Paid': 'PAID', 'Unpaid': 'UNPAID', 'Credit': 'PARTIAL'};
          final selectedStatus = option == 'All' ? null : statusMap[option];
          final isSelected = filter.status == selectedStatus && (option != 'All' || filter.status == null);
          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (_) {
              final current = ref.read(saleFilterProvider);
              ref.read(saleFilterProvider.notifier).state = current.copyWith(status: selectedStatus);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w600),
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3))),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final filter = ref.watch(saleFilterProvider);
    final hasFilters = filter.status != null || _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
                color: AppColors.primary.withValues(alpha: 0.5), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No Sales Found' : 'No Sales Yet',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters ? 'Try adjusting your search or filter.' : 'Your sales invoices will appear here.',
              style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(saleFilterProvider.notifier).state = SaleFilter();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant, highlightColor: AppColors.surface,
        child: Column(
          children: List.generate(6, (_) => Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          )),
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  final NumberFormat currency;

  const _SaleTile({required this.sale, required this.currency});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isPaid = sale.status == 'PAID';
    final isPartial = sale.status == 'PARTIAL';

    Color statusColor;
    if (isPaid) {
      statusColor = const Color(0xFF2E7D32);
    } else if (isPartial) {
      statusColor = const Color(0xFFEF6C00);
    } else {
      statusColor = AppColors.error;
    }

    final statusLabel = sale.status.toLowerCase() == 'paid' ? 'Paid'
        : sale.status.toLowerCase() == 'partial' ? 'Partial'
        : 'Unpaid';

    return InkWell(
      onTap: () => context.push('${AppRoutes.saleDetail}/${sale.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateFormat.format(sale.invoiceDate),
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sale.customer?.name ?? 'Walk-in',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹ ${currency.format(sale.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
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
