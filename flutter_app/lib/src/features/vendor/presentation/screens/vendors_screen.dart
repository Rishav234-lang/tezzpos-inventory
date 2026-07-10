import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.addVendor),
            tooltip: 'Create Supplier',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vendorsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildSearchBox(context),
            const SizedBox(height: 12),
            vendorsAsync.when(
              data: (vendors) {
                if (vendors.isEmpty) return _buildEmptyState();
                return Column(
                  children: [
                    for (final vendor in vendors) ...[
                      _VendorTile(
                        vendor: vendor,
                        onTap: () => context.push(
                          '${AppRoutes.vendorDetail}/${vendor.id}',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
              loading: () => _buildShimmerList(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load vendors',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addVendor),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Supplier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          final current = ref.read(vendorFilterProvider);
          ref.read(vendorFilterProvider.notifier).state = current.copyWith(
            search: value.isEmpty ? null : value,
          );
        },
        decoration: InputDecoration(
          hintText: 'Search supplier...',
          hintStyle: TextStyle(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: ref.watch(vendorFilterProvider).search != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: AppColors.onSurfaceVariant,
                  onPressed: () {
                    _searchController.clear();
                    ref.read(vendorFilterProvider.notifier).state =
                        VendorFilter();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filter = ref.watch(vendorFilterProvider);
    final isSearching = filter.search != null && filter.search!.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.store_outlined,
                color: AppColors.primary.withValues(alpha: 0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No Suppliers Found' : 'No Suppliers Yet',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search term.'
                  : 'Add your first supplier to get started.',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!isSearching)
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addVendor),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Supplier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(vendorFilterProvider.notifier).state =
                      VendorFilter();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: Column(children: List.generate(6, (_) => _buildShimmerTile())),
    );
  }

  Widget _buildShimmerTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    color: AppColors.background,
                  ),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: AppColors.background),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;

  const _VendorTile({required this.vendor, required this.onTap});

  Color _getAvatarColor() {
    final letter = vendor.initials.isNotEmpty ? vendor.initials[0] : 'A';
    final colors = <String, Color>{
      'A': const Color(0xFF7C4DFF),
      'B': const Color(0xFF7C4DFF),
      'S': const Color(0xFF69F0AE),
      'G': const Color(0xFFFFAB40),
      'M': const Color(0xFF448AFF),
      'R': const Color(0xFFFF8A80),
      'P': const Color(0xFFE040FB),
      'K': const Color(0xFF18FFFF),
      'N': const Color(0xFFEEFF41),
      'T': const Color(0xFF40C4FF),
    };
    return colors[letter] ?? const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAvatarColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    vendor.initials,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getAvatarColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vendor.mobile ?? 'N/A',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildInfoColumn(
                          'Purchase',
                          '₹ ${_formatAmount(vendor.totalPurchaseAmount)}',
                        ),
                        const SizedBox(width: 16),
                        _buildInfoColumn(
                          'Due',
                          '₹ ${_formatAmount(vendor.outstandingBalance)}',
                          color: vendor.outstandingBalance > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoColumn(
                          'Last Purchase',
                          vendor.formattedLastPurchaseDate,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right side: badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: vendor.isActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vendor.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: vendor.isActive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
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
    if (amount >= 100000) {
      return '${NumberFormat('#,##,##0.##').format(amount / 100000)}L';
    }
    if (amount >= 1000) return NumberFormat('#,##,##0').format(amount);
    return amount.toStringAsFixed(0);
  }

  Widget _buildInfoColumn(String label, String value, {Color? color}) {
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
            color: color ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
