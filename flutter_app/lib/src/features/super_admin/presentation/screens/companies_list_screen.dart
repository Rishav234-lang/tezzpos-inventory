import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/company.dart';
import '../providers/super_admin_providers.dart';

class CompaniesListScreen extends ConsumerStatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  ConsumerState<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends ConsumerState<CompaniesListScreen> {
  final _searchController = TextEditingController();
  var _filter = const CompanyFilter();
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
      setState(() => _filter = _filter.copyWith(search: value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Companies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.addCompany),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search companies',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            _buildFilterChips(),
            Expanded(
              child: companiesAsync.when(
                data: (companies) {
                  if (companies.isEmpty) return _buildEmptyState();
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(companiesProvider(_filter)),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: companies.length,
                      itemBuilder: (context, index) => _CompanyTile(company: companies[index]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final options = ['All', 'Active', 'Pending', 'Suspended'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final statusMap = {'Active': 'ACTIVE', 'Pending': 'PENDING', 'Suspended': 'SUSPENDED'};
          final selectedStatus = option == 'All' ? null : statusMap[option];
          final isSelected = _filter.status == selectedStatus;
          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (_) => setState(() => _filter = _filter.copyWith(status: selectedStatus)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 56, color: AppColors.outline),
          const SizedBox(height: 12),
          Text('No companies found', style: context.textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CompanyTile extends ConsumerWidget {
  final Company company;

  const _CompanyTile({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    if (company.isActive) {
      statusColor = const Color(0xFF2E7D32);
    } else if (company.isSuspended) {
      statusColor = AppColors.error;
    } else {
      statusColor = const Color(0xFFEF6C00);
    }

    return InkWell(
      onTap: () => context.push('${AppRoutes.companyDetail}/${company.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE3F2FD),
              child: Text(company.initials, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(company.email, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  if (company.owner != null)
                    Text('Owner: ${company.owner!.name}', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(company.status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) async {
                if (value == 'expire') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('End Grace Period?'),
                      content: const Text('This will immediately expire the subscription and suspend the company. The owner will be redirected to the payment screen on next login.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Expire Now', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final notifier = ref.read(superAdminNotifierProvider.notifier);
                    final success = await notifier.expireCompanyNow(company.id);
                    if (success) {
                      ref.invalidate(companiesProvider(const CompanyFilter()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subscription expired. Grace period ended.'), backgroundColor: AppColors.success),
                        );
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(notifier.lastError ?? 'Failed to expire'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'expire', child: Row(
                  children: [
                    Icon(Icons.timer_off, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('End Grace Period'),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
