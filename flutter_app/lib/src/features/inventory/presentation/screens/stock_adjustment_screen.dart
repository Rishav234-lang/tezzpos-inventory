import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  final String? productId;

  const StockAdjustmentScreen({super.key, this.productId});

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  String _changeType = 'ADD';
  String? _reason;
  bool _isSaving = false;

  final _reasons = [
    'Purchase',
    'Sale',
    'Damaged',
    'Expired',
    'Stock count',
    'Other',
  ];

  int get _qty => int.tryParse(_qtyController.text.trim()) ?? 0;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = widget.productId != null
        ? ref.watch(productDetailProvider(widget.productId!))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Adjust Stock'),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: productAsync == null
          ? _buildPickItemMessage()
          : productAsync.when(
              data: _buildForm,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
    );
  }

  Widget _buildPickItemMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Select an item first',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Open Stock, tap an item, then choose Adjust Stock.',
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

  Widget _buildForm(Product product) {
    final newStock = _previewStock(product.totalStock);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductCard(product),
          const SizedBox(height: 16),
          _buildFormCard(
            children: [
              Text(
                'What do you want to do?',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _changeButton('ADD', 'Add', Icons.add)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _changeButton('REDUCE', 'Reduce', Icons.remove),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _changeButton('SET', 'Set', Icons.edit)),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Quantity', required: true),
              const SizedBox(height: 8),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  'Enter quantity',
                  suffix: product.unit,
                ),
              ),
              const SizedBox(height: 18),
              _buildLabel('Reason'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: _inputDecoration('Select reason'),
                items: _reasons
                    .map(
                      (reason) =>
                          DropdownMenuItem(value: reason, child: Text(reason)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _reason = value),
              ),
              const SizedBox(height: 18),
              _buildLabel('Note'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: _inputDecoration('Optional'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreview(product.totalStock, newStock, product.unit),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : () => _submit(product),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Stock',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current stock: ${product.totalStock} ${product.unit}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _changeButton(String value, String label, IconData icon) {
    final selected = _changeType == value;
    return InkWell(
      onTap: () => setState(() => _changeType = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(int current, int newStock, String unit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _previewItem('Current', '$current $unit')),
          Icon(Icons.arrow_forward, color: AppColors.onSurfaceVariant),
          Expanded(
            child: _previewItem('After Save', '$newStock $unit', active: true),
          ),
        ],
      ),
    );
  }

  Widget _previewItem(String label, String value, {bool active = false}) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            color: active ? AppColors.primary : AppColors.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.16),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.16),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  int _previewStock(int current) {
    switch (_changeType) {
      case 'ADD':
        return current + _qty;
      case 'REDUCE':
        return (current - _qty).clamp(0, 999999);
      default:
        return _qty;
    }
  }

  Future<void> _submit(Product product) async {
    if (_qty <= 0) {
      _showSnack('Please enter quantity');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider).dio;
      await dio.post(
        ApiConstants.inventoryAdjust,
        data: {
          'productId': product.id,
          'adjustmentType': _changeType == 'ADD'
              ? 'INCREASE'
              : _changeType == 'REDUCE'
              ? 'DECREASE'
              : 'SET',
          'quantity': _qty,
          'reason': _reason ?? 'Stock count',
          'reference': null,
          'notes': _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
        },
      );

      if (!mounted) return;
      ref.invalidate(productDetailProvider(product.id));
      ref.invalidate(inventoryStatsProvider);
      context.pop();
      _showSnack('Stock updated');
    } catch (error) {
      _showSnack('Failed to update stock', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }
}
