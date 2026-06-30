import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/purchase_providers.dart';

class PurchaseReturnScreen extends ConsumerStatefulWidget {
  final String purchaseId;

  const PurchaseReturnScreen({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends ConsumerState<PurchaseReturnScreen> {
  final Map<String, TextEditingController> _returnQtyControllers = {};
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = 'Damaged';
  bool _isSubmitting = false;

  final List<String> _reasons = ['Damaged', 'Expired', 'Wrong Item', 'Quality Issue', 'Other'];

  @override
  void dispose() {
    for (final controller in _returnQtyControllers.values) {
      controller.dispose();
    }
    _reasonController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submitReturn() async {
    final purchaseAsync = ref.read(purchaseDetailProvider(widget.purchaseId));
    if (!purchaseAsync.hasValue) return;
    final purchase = purchaseAsync.value!;

    final returnItems = <Map<String, dynamic>>[];
    for (final item in purchase.items) {
      final controller = _returnQtyControllers[item.id];
      if (controller == null) continue;
      final qty = int.tryParse(controller.text) ?? 0;
      if (qty > 0) {
        if (qty > item.quantity) {
          _showError('Return qty cannot exceed purchased qty for ${item.productName}');
          return;
        }
        returnItems.add({
          'purchaseItemId': item.id,
          'productId': item.productId,
          'quantity': qty,
        });
      }
    }

    if (returnItems.isEmpty) {
      _showError('Please enter return quantity for at least one product');
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Implement actual return API call when backend supports it
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase return created successfully')),
    );
    context.pop();

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(widget.purchaseId));
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        title: Text(
          'Purchase Return',
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: purchaseAsync.when(
        data: (purchase) {
          // Initialize controllers lazily
          for (final item in purchase.items) {
            _returnQtyControllers.putIfAbsent(item.id, () => TextEditingController(text: '0'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original Invoice Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Original Invoice', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(purchase.invoiceNumber, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vendor', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(purchase.vendor?.name ?? '—', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice Date', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(dateFormat.format(purchase.purchaseDate), style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Balance Amount', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text('₹ ${currency.format(purchase.balanceAmount)}', style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Select Products to Return
                Text(
                  'Select Product to Return',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...purchase.items.map((item) {
                  final controller = _returnQtyControllers[item.id]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Purchased Qty: ${item.quantity}', style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSmallField(
                          label: 'Return Qty',
                          controller: controller,
                          keyboardType: TextInputType.number,
                          hint: '0',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Reason
                Text(
                  'Reason',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReason,
                      items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() => _selectedReason = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error', style: TextStyle(color: AppColors.error)),
        ),
      ),
      bottomNavigationBar: purchaseAsync.when(
        data: (_) => Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReturn,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.assignment_return, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Creating...' : 'Create Return',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSmallField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
