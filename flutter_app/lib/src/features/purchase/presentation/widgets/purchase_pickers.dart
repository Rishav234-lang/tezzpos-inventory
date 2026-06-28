import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../vendor/domain/entities/vendor.dart';
import '../../../vendor/presentation/providers/vendor_providers.dart';

class VendorPicker extends ConsumerStatefulWidget {
  final void Function(Vendor) onSelected;
  const VendorPicker({super.key, required this.onSelected});

  @override
  ConsumerState<VendorPicker> createState() => _VendorPickerState();
}

class _VendorPickerState extends ConsumerState<VendorPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(
      vendorsProvider(VendorFilter(search: _search.isEmpty ? null : _search)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select Vendor',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: vendorsAsync.when(
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return const Center(child: Text('No vendors found'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: vendors.length,
                    itemBuilder: (_, i) {
                      final v = vendors[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            v.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(v.name, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: v.mobile != null ? Text(v.mobile!) : null,
                        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
                        onTap: () => widget.onSelected(v),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductPicker extends ConsumerStatefulWidget {
  final void Function(Product) onSelected;
  const ProductPicker({super.key, required this.onSelected});

  @override
  ConsumerState<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<ProductPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider(ProductFilter(search: _search.isEmpty ? null : _search, limit: 50)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select Product',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(Icons.image, size: 20, color: AppColors.onSurfaceVariant),
                                  ),
                                )
                              : const Icon(Icons.image, size: 20, color: AppColors.onSurfaceVariant),
                        ),
                        title: Text(p.name, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'SKU: ${p.sku ?? "N/A"} | Stock: ${p.totalStock}',
                          style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        trailing: Text(
                          'Rs ${p.costPrice.toStringAsFixed(2)}',
                          style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        onTap: () => widget.onSelected(p),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
