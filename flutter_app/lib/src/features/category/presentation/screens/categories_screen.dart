import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(_searchQuery));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addCategory),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, categoriesAsync),
          SliverToBoxAdapter(child: _buildSearchBar(context)),
          categoriesAsync.when(
            data: (categories) => _buildCategoryList(context, categories),
            loading: () => SliverToBoxAdapter(child: _buildShimmer(context)),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load categories', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$error', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AsyncValue<List<Category>> categoriesAsync) {
    final count = categoriesAsync.valueOrNull?.length ?? 0;
    final filteredCount = categoriesAsync.valueOrNull != null ? _applyStatusFilter(categoriesAsync.valueOrNull!).length : 0;
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go(AppRoutes.dashboard),
      ),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: _statusFilter != 'All',
            backgroundColor: Colors.orange,
            label: const Text(''),
            child: const Icon(Icons.filter_list, color: Colors.white),
          ),
          onPressed: () => _showFilterSheet(context),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Categories',
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusFilter == 'All'
                        ? '$count categories total'
                        : '$filteredCount of $count · Filter: $_statusFilter',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search categories...',
            hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
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
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          )),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter by Status', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (_statusFilter != 'All')
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); setState(() => _statusFilter = 'All'); },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
              for (final option in ['All', 'Active', 'Inactive'])
                ListTile(
                  title: Text(option),
                  trailing: _statusFilter == option ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () { Navigator.pop(ctx); setState(() => _statusFilter = option); },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Category> _applyStatusFilter(List<Category> cats) {
    if (_statusFilter == 'Active') return cats.where((c) => c.isActive).toList();
    if (_statusFilter == 'Inactive') return cats.where((c) => !c.isActive).toList();
    return cats;
  }

  Widget _buildCategoryList(BuildContext context, List<Category> categories) {
    final filtered = _applyStatusFilter(categories);
    if (filtered.isEmpty) {
      final isFiltered = _statusFilter != 'All' || _searchQuery.isNotEmpty;
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
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFiltered ? Icons.filter_list_off : Icons.category_outlined,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isFiltered ? 'No Results Found' : 'No Categories Yet',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? 'Try changing your search or filter.'
                      : 'Create your first category to organize products.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isFiltered)
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.addCategory),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => setState(() { _statusFilter = 'All'; _searchController.clear(); _searchQuery = ''; }),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = filtered[index];
          return _CategoryTile(
            category: category,
            onTap: () => context.push('${AppRoutes.categoryDetail}/${category.id}'),
          );
        },
        childCount: filtered.length,
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = _categoryColor(category.name);
    final bgColor = iconColor.withValues(alpha: 0.12);
    final isActive = category.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  // Left accent bar
                  Container(width: 4, height: 72, color: iconColor),
                  const SizedBox(width: 12),
                  // Icon / image
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      image: category.imageUrl != null && category.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                category.imageUrl!.startsWith('http')
                                    ? category.imageUrl!
                                    : '${ApiConstants.baseUrl}${category.imageUrl!}',
                              ),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {},
                            )
                          : null,
                    ),
                    child: category.imageUrl == null || category.imageUrl!.isEmpty
                        ? Icon(_categoryIcon(category.name), color: iconColor, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            category.itemCount == 0 ? 'No items' : '${category.itemCount} item${category.itemCount == 1 ? '' : 's'}',
                            style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Options button
                  IconButton(
                    onPressed: () => _showOptions(context, ref),
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: AppColors.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
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
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
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
                ref.invalidate(categoriesProvider(''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category deleted')),
                );
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
