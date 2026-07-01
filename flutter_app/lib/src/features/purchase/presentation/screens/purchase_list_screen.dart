import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../vendor/domain/entities/vendor.dart';
import '../../data/models/purchase_model.dart';
import '../../domain/entities/purchase.dart';
import '../providers/purchase_providers.dart';
import '../widgets/purchase_pickers.dart';

class PurchaseListScreen extends ConsumerStatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  ConsumerState<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends ConsumerState<PurchaseListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  PurchaseFilter _filter = const PurchaseFilter();
  int _currentPage = 1;
  Vendor? _selectedVendor;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    setState(() {
      _currentPage = 1;
      // Backend doesn't support search yet, but we keep the UI ready
    });
  }

  void _applyStatusFilter({String? status}) {
    setState(() {
      _currentPage = 1;
      _filter = _filter.copyWith(status: status);
    });
  }

  void _applyVendorFilter(Vendor? vendor) {
    setState(() {
      _currentPage = 1;
      _selectedVendor = vendor;
      _filter = _filter.copyWith(vendorId: vendor?.id);
    });
  }

  void _applyDateFilter(DateTime? start, DateTime? end) {
    setState(() {
      _currentPage = 1;
      _startDate = start;
      _endDate = end;
      _filter = _filter.copyWith(
        startDate: start != null ? DateFormat('yyyy-MM-dd').format(start) : null,
        endDate: end != null ? DateFormat('yyyy-MM-dd').format(end) : null,
      );
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _currentPage = 1;
      final newOrder = _filter.sortOrder == 'desc' ? 'asc' : 'desc';
      _filter = _filter.copyWith(sortOrder: newOrder);
    });
  }

  void _clearFilters() {
    setState(() {
      _currentPage = 1;
      _selectedVendor = null;
      _startDate = null;
      _endDate = null;
      _filter = const PurchaseFilter();
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _filter = _filter.copyWith(page: page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            SliverToBoxAdapter(child: _buildSummaryCards(purchasesAsync)),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(child: _buildFilterChips(context)),
            purchasesAsync.when(
              data: (data) {
                final purchases = _extractPurchases(data);
                final pagination = data['pagination'] as Map<String, dynamic>?;
                return _buildPurchaseList(context, purchases, pagination);
              },
              loading: () => SliverToBoxAdapter(child: _buildShimmer(context)),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addPurchase),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Purchase', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  List<Purchase> _extractPurchases(Map<String, dynamic> data) {
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.dashboard),
            child: const Icon(Icons.menu, color: AppColors.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Purchases',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _searchFocusNode.requestFocus(),
            icon: const Icon(Icons.search, color: AppColors.onSurface),
          ),
          IconButton(
            onPressed: () => _showStatusFilter(context),
            icon: const Icon(Icons.filter_alt_outlined, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AsyncValue<Map<String, dynamic>> purchasesAsync) {
    if (purchasesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _SummaryCardShimmer()),
            SizedBox(width: 10),
            Expanded(child: _SummaryCardShimmer()),
            SizedBox(width: 10),
            Expanded(child: _SummaryCardShimmer()),
          ],
        ),
      );
    }

    if (purchasesAsync.hasError) return const SizedBox.shrink();

    final data = purchasesAsync.valueOrNull ?? {};
    final purchases = _extractPurchases(data);

    final total = purchases.fold<double>(0, (s, p) => s + p.totalAmount);
    final paid = purchases.fold<double>(0, (s, p) => s + p.paidAmount);
    final pending = purchases.fold<double>(0, (s, p) => s + p.balanceAmount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Total Purchase',
              value: '₹${_formatAmount(total)}',
              icon: Icons.receipt_outlined,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: 'Paid',
              value: '₹${_formatAmount(paid)}',
              icon: Icons.check_circle_outline,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: 'Pending',
              value: '₹${_formatAmount(pending)}',
              icon: Icons.access_time,
              iconBg: const Color(0xFFFFEBEE),
              iconColor: const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##,###').format(amount);
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _applySearch,
          decoration: InputDecoration(
            hintText: 'Search invoice / vendor',
            hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final hasActiveFilters = _filter.status != null ||
        _filter.vendorId != null ||
        _filter.startDate != null ||
        _filter.sortOrder != 'desc';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _FilterChip(
            label: _dateFilterLabel(),
            icon: Icons.calendar_today_outlined,
            isActive: _filter.startDate != null,
            onTap: () => _showDateFilter(context),
          ),
          _FilterChip(
            label: _vendorFilterLabel(),
            icon: Icons.person_outline,
            isActive: _filter.vendorId != null,
            onTap: () => _showVendorFilter(context),
          ),
          _FilterChip(
            label: _statusFilterLabel(),
            icon: Icons.verified_outlined,
            isActive: _filter.status != null,
            onTap: () => _showStatusFilter(context),
          ),
          _FilterChip(
            label: _filter.sortOrder == 'desc' ? 'Newest' : 'Oldest',
            icon: _filter.sortOrder == 'desc' ? Icons.arrow_downward : Icons.arrow_upward,
            isActive: _filter.sortOrder != 'desc',
            onTap: _toggleSortOrder,
          ),
          if (hasActiveFilters)
            _FilterChip(
              label: 'Clear',
              icon: Icons.close,
              isActive: true,
              isClear: true,
              onTap: _clearFilters,
            ),
        ],
      ),
    );
  }

  String _dateFilterLabel() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}';
    }
    if (_startDate != null) return DateFormat('dd MMM yyyy').format(_startDate!);
    return 'Date';
  }

  String _vendorFilterLabel() {
    return _selectedVendor?.name ?? 'Vendor';
  }

  String _statusFilterLabel() {
    if (_filter.status == null) return 'Status';
    return _filter.status!.capitalize;
  }

  void _showDateFilter(BuildContext context) async {
    final now = DateTime.now();
    final initialDateRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _applyDateFilter(picked.start, picked.end);
    }
  }

  void _showVendorFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => VendorPicker(
          onSelected: (vendor) {
            Navigator.pop(ctx);
            _applyVendorFilter(vendor);
          },
        ),
      ),
    );
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                trailing: _filter.status == null || _filter.status!.isEmpty
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _applyStatusFilter(status: null);
                },
              ),
              ListTile(
                title: const Text('Paid'),
                trailing: _filter.status == 'PAID'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _applyStatusFilter(status: 'PAID');
                },
              ),
              ListTile(
                title: const Text('Partial'),
                trailing: _filter.status == 'PARTIAL'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _applyStatusFilter(status: 'PARTIAL');
                },
              ),
              ListTile(
                title: const Text('Unpaid'),
                trailing: _filter.status == 'UNPAID'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _applyStatusFilter(status: 'UNPAID');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseList(
    BuildContext context,
    List<Purchase> purchases,
    Map<String, dynamic>? pagination,
  ) {
    if (purchases.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Purchases Yet',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first purchase to get started',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalPages = (pagination?['totalPages'] as int?) ?? 1;
    final hasNext = (pagination?['hasNext'] as bool?) ?? false;
    final hasPrev = (pagination?['hasPrev'] as bool?) ?? false;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < purchases.length) {
            return _PurchaseTile(purchase: purchases[index]);
          }
          // Pagination bar at the bottom
          if (index == purchases.length && totalPages > 1) {
            return _buildPagination(hasPrev, hasNext, totalPages);
          }
          return null;
        },
        childCount: purchases.length + (totalPages > 1 ? 1 : 0),
      ),
    );
  }

  Widget _buildPagination(bool hasPrev, bool hasNext, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: hasPrev ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page $_currentPage of $totalPages'),
          IconButton(
            onPressed: hasNext ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Column(
          children: List.generate(6, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          )),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardShimmer extends StatelessWidget {
  const _SummaryCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isClear;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.isClear = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isClear ? AppColors.errorLight : (isActive ? AppColors.primaryContainer : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isClear
                ? AppColors.error.withValues(alpha: 0.3)
                : (isActive ? AppColors.primary.withValues(alpha: 0.4) : AppColors.outline.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isClear ? AppColors.error : (isActive ? AppColors.primary : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: isClear ? AppColors.error : (isActive ? AppColors.primary : AppColors.onSurfaceVariant),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final Purchase purchase;

  const _PurchaseTile({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final statusColor = _statusColor(purchase.status);
    final statusBg = _statusBg(purchase.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.purchaseDetail}/${purchase.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt,
                      size: 20,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.invoiceNumber,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          purchase.vendor?.name ?? 'Unknown Vendor',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${_formatAmount(purchase.totalAmount)}',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(purchase.purchaseDate),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.shopping_basket_outlined, size: 12, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${purchase.itemCount} items',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(purchase.status),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##,###').format(amount);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFF2E7D32);
      case 'PARTIAL':
        return const Color(0xFFF9A825);
      case 'UNPAID':
        return const Color(0xFFC62828);
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFFE8F5E9);
      case 'PARTIAL':
        return const Color(0xFFFFFDE7);
      case 'UNPAID':
        return const Color(0xFFFFEBEE);
      default:
        return AppColors.surfaceVariant;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'PARTIAL':
        return 'Partial';
      case 'UNPAID':
        return 'Unpaid';
      default:
        return status;
    }
  }
}
