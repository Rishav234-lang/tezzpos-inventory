import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/sale_providers.dart';

class CreateSaleReturnScreen extends ConsumerStatefulWidget {
  final String saleId;

  const CreateSaleReturnScreen({super.key, required this.saleId});

  @override
  ConsumerState<CreateSaleReturnScreen> createState() => _CreateSaleReturnScreenState();
}

class _ReturnItemData {
  final String productId;
  final String productName;
  final String? productSku;
  final int soldQuantity;
  int returnQuantity;
  final double price;

  _ReturnItemData({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.soldQuantity,
    required this.price,
  }) : returnQuantity = 0;

  double get totalAmount => returnQuantity * price;
}

class _CreateSaleReturnScreenState extends ConsumerState<CreateSaleReturnScreen> {
  final _refundController = TextEditingController();
  final _reasonController = TextEditingController();
  final List<_ReturnItemData> _returnItems = [];
  bool _isSaving = false;
  DateTime _returnDate = DateTime.now();

  @override
  void dispose() {
    _refundController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saleAsync = ref.watch(saleDetailProvider(widget.saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Sale Return'),
      ),
      body: saleAsync.when(
        data: (sale) {
          if (_returnItems.isEmpty) {
            _returnItems.addAll(sale.items.map((item) => _ReturnItemData(
              productId: item.productId,
              productName: item.productName,
              productSku: item.productSku,
              soldQuantity: item.quantity,
              price: item.sellingPrice,
            )));
          }
          return _buildContent(context, sale);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _returnItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
              ),
              child: FilledButton(
                onPressed: _isSaving ? null : _processReturn,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Process Return'),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, sale) {
    final currency = NumberFormat('#,##,##0.00');
    final totalReturnAmount = _returnItems.fold(0.0, (sum, item) => sum + item.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOriginalInvoiceHeader(context, sale),
          const SizedBox(height: 16),
          _buildDatePicker(context),
          const SizedBox(height: 16),
          Text('Items', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._returnItems.map((item) => _buildReturnItemCard(context, item, currency)),
          const SizedBox(height: 16),
          _buildTotalRow('Total Return Amount', totalReturnAmount, currency),
          const SizedBox(height: 16),
          _buildLabel('Refund Amount'),
          const SizedBox(height: 6),
          TextField(
            controller: _refundController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Enter refund amount'),
          ),
          const SizedBox(height: 16),
          _buildLabel('Reason (Optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: _inputDecoration('Enter reason for return'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOriginalInvoiceHeader(BuildContext context, sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Original Invoice', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Customer: ${sale.customer?.name ?? 'Walk-in'}', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('Return Date', style: TextStyle(color: AppColors.onSurfaceVariant)),
            const Spacer(),
            Text(DateFormat('dd MMM yyyy').format(_returnDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItemCard(BuildContext context, _ReturnItemData item, NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('SKU: ${item.productSku ?? 'N/A'} | Sold: ${item.soldQuantity}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Text('₹ ${currency.format(item.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() => item.returnQuantity = (item.returnQuantity - 1).clamp(0, item.soldQuantity)),
              ),
              Text('${item.returnQuantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => item.returnQuantity = (item.returnQuantity + 1).clamp(0, item.soldQuantity)),
              ),
              const Spacer(),
              Text('₹ ${currency.format(item.price)} / unit', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, NumberFormat currency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text('₹ ${currency.format(value)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _returnDate = picked);
  }

  Future<void> _processReturn() async {
    final items = _returnItems
        .where((item) => item.returnQuantity > 0)
        .map((item) => {
              'productId': item.productId,
              'quantity': item.returnQuantity,
              'price': item.price,
            })
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select items to return')));
      return;
    }

    final refundAmount = double.tryParse(_refundController.text.trim()) ?? 0;

    final data = {
      'saleId': widget.saleId,
      'returnDate': _returnDate.toIso8601String(),
      'refundAmount': refundAmount,
      'reason': _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      'items': items,
    };

    setState(() => _isSaving = true);
    final saleReturn = await ref.read(saleNotifierProvider.notifier).createSaleReturn(data);
    setState(() => _isSaving = false);

    if (saleReturn == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ref.read(saleNotifierProvider).error}'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!mounted) return;
    ref.invalidate(saleReturnsProvider(SaleReturnFilter()));
    context.pushReplacement('${AppRoutes.saleReturnDetail}/${saleReturn.id}');
  }
}
