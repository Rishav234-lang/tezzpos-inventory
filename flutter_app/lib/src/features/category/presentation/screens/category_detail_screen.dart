import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryDetailProvider(categoryId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: categoryAsync.when(
        data: (category) => _buildContent(context, ref, category),
        loading: () => _buildShimmer(context),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: categoryAsync.when(
        data: (category) => _buildBottomActions(context, ref, category),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Category category) {
    final iconColor = _categoryColor(category.name);
    final bgColor = iconColor.withValues(alpha: 0.1);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Category Details'),
          actions: [
            IconButton(
              onPressed: () => _showOptions(context, ref, category),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _categoryIcon(category.name),
                          color: iconColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: category.isActive
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category.isActive ? 'Active' : 'Inactive',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: category.isActive
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${category.itemCount} Items',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Info fields
                _InfoRow(icon: Icons.calendar_today, label: 'Created On', value: dateFormat.format(category.createdAt)),
                _InfoRow(icon: Icons.person_outline, label: 'Created By', value: 'Owner'),
                _InfoRow(icon: Icons.edit_note, label: 'Last Updated', value: dateFormat.format(category.updatedAt)),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.description_outlined, label: 'Description', value: category.description ?? 'No description'),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.shield_outlined, label: 'Status', value: category.isActive ? 'Active' : 'Inactive'),
                const SizedBox(height: 24),
                // Items section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items in this Category (${category.itemCount})',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'View All',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (category.itemCount == 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('No items in this category')),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions(BuildContext context, WidgetRef ref, Category category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('${AppRoutes.editCategory}/${category.id}'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Category'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref, category),
                icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                label: const Text('Delete Category', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 120, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 16),
            Container(height: 48, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            Container(height: 48, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            Container(height: 48, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, Category category) {
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
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit Category'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('${AppRoutes.editCategory}/${category.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete Category'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref, category);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
              if (context.mounted) {
                context.go(AppRoutes.categories);
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('beverage')) return Icons.local_cafe;
    if (lower.contains('snack')) return Icons.fastfood;
    if (lower.contains('dairy') || lower.contains('bakery')) return Icons.cake;
    if (lower.contains('grocery') || lower.contains('staple')) return Icons.shopping_bag;
    if (lower.contains('personal') || lower.contains('care')) return Icons.spa;
    if (lower.contains('household')) return Icons.home;
    if (lower.contains('baby')) return Icons.child_care;
    return Icons.category;
  }

  Color _categoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('beverage')) return const Color(0xFF1565C0);
    if (lower.contains('snack')) return const Color(0xFFF9A825);
    if (lower.contains('dairy') || lower.contains('bakery')) return const Color(0xFF2E7D32);
    if (lower.contains('grocery') || lower.contains('staple')) return const Color(0xFF6A1B9A);
    if (lower.contains('personal') || lower.contains('care')) return const Color(0xFFE91E63);
    if (lower.contains('household')) return const Color(0xFF00838F);
    if (lower.contains('baby')) return const Color(0xFFEF6C00);
    return AppColors.primary;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
