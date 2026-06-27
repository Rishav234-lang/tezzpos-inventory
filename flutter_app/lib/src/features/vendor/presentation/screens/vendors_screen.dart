import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(
      vendorsProvider(VendorFilter(search: _searchQuery)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendors'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.addVendor),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Vendor'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your vendors',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.isEmpty ? null : value);
              },
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: vendorsAsync.when(
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = vendors[index];
                      return _VendorTile(
                        vendor: vendor,
                        onTap: () => context.push(
                          '${AppRoutes.vendorDetail}/${vendor.id}',
                        ),
                      );
                    },
                  );
                },
                loading: () => _buildShimmerList(),
                error: (error, stackTrace) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No vendors found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first vendor to get started',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmerTile(),
      ),
    );
  }

  Widget _buildShimmerTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                  Container(height: 16, width: 120, color: AppColors.background),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                          color: vendor.outstandingBalance > 0 ? AppColors.error : AppColors.success,
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
              // Right side: more icon + Active badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.more_vert,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0';
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      final s = amount.toStringAsFixed(0);
      var result = '';
      var count = 0;
      for (var i = s.length - 1; i >= 0; i--) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          result = ',$result';
        }
        result = s[i] + result;
        count++;
      }
      return result;
    }
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
