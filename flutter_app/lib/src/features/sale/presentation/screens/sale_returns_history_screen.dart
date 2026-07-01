import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/sale_return.dart';
import '../providers/sale_providers.dart';

class SaleReturnsHistoryScreen extends ConsumerStatefulWidget {
  const SaleReturnsHistoryScreen({super.key});

  @override
  ConsumerState<SaleReturnsHistoryScreen> createState() => _SaleReturnsHistoryScreenState();
}

class _SaleReturnsHistoryScreenState extends ConsumerState<SaleReturnsHistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(saleReturnsProvider(SaleReturnFilter()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Sale Returns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(saleReturnsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(saleReturnsProvider),
              color: AppColors.primary,
              child: returnsAsync.when(
                data: (returns) {
                  final filtered = _applySearch(returns);
                  if (filtered.isEmpty) return _buildEmptyState(context);
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _SaleReturnTile(saleReturn: filtered[index]),
                  );
                },
                loading: () => _buildShimmer(),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Failed to load returns', style: context.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('$e', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(saleReturnsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<SaleReturn> _applySearch(List<SaleReturn> returns) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return returns;
    return returns.where((r) {
      return r.returnNumber.toLowerCase().contains(query) ||
          (r.originalInvoiceNumber?.toLowerCase().contains(query) ?? false) ||
          (r.customer?.name.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () => setState(() {}));
        },
        decoration: InputDecoration(
          hintText: 'Search by return no., invoice or customer',
          hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchController.clear()),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_return_outlined, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text('No sale returns found', style: context.textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(
              'Sale returns will appear here after\nyou process a return from a sale.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 88,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _SaleReturnTile extends StatelessWidget {
  final SaleReturn saleReturn;

  const _SaleReturnTile({required this.saleReturn});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: () => context.push('${AppRoutes.saleReturnDetail}/${saleReturn.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_return, color: Color(0xFFC62828), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        saleReturn.returnNumber,
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          saleReturn.status,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invoice: ${saleReturn.originalInvoiceNumber ?? '—'}  •  ${saleReturn.customer?.name ?? 'Walk-in'}',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(saleReturn.returnDate),
                    style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹ ${currency.format(saleReturn.totalAmount)}',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                const SizedBox(height: 4),
                Text(
                  '${saleReturn.items.length} item${saleReturn.items.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
