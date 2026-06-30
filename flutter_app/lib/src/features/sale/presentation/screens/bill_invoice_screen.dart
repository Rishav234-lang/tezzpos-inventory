import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/sale_providers.dart';

class BillInvoiceScreen extends ConsumerWidget {
  final String saleId;

  const BillInvoiceScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final currency = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Bill / Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context),
          ),
        ],
      ),
      body: saleAsync.when(
        data: (sale) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, sale),
              const SizedBox(height: 16),
              _buildItemsTable(context, sale, currency),
              const SizedBox(height: 16),
              _buildTotals(context, sale, currency),
              const SizedBox(height: 16),
              _buildPaymentInfo(context, sale),
              const SizedBox(height: 100),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _downloadPdf(context),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print / Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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

  Widget _buildHeader(BuildContext context, sale) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TezzPOS Retail', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('GSTIN: 27ABCDE1234F1Z5', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Invoice No.', sale.invoiceNumber ?? 'N/A'),
          _buildInfoRow('Date', sale.invoiceDate != null ? dateFormat.format(sale.invoiceDate) : 'N/A'),
          _buildInfoRow('Payment Type', sale.paymentMethod ?? 'CASH'),
          _buildInfoRow('Bill To', sale.customer?.name ?? 'Walk-in Customer'),
          if (sale.customer?.mobile != null) _buildInfoRow('Mobile', sale.customer!.mobile),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, sale, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items (${sale.items.length})', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sale.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('SKU: ${item.productSku ?? 'N/A'} | ${item.quantity} × ₹ ${currency.format(item.sellingPrice)}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text('₹ ${currency.format(item.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context, sale, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', sale.subtotal, currency),
          _buildTotalRow('Discount', sale.discount, currency),
          _buildTotalRow('Tax (GST ${sale.isInterState ? 'IGST' : 'CGST+SGST'})', sale.taxAmount, currency),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹ ${currency.format(sale.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTotalRow('Paid Amount', sale.paidAmount, currency),
          _buildTotalRow('Balance Amount', sale.balanceAmount, currency, isNegative: true),
          const SizedBox(height: 8),
          Text(
            'Amount in Words: ${NumberToWords.convert(sale.totalAmount)} Rupees Only',
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, NumberFormat currency, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          Text('₹ ${currency.format(value)}', style: TextStyle(fontSize: 13, color: isNegative ? AppColors.error : AppColors.onSurface)),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context, sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Information', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInfoRow('Status', sale.status),
          _buildInfoRow('Method', sale.paymentMethod ?? 'CASH'),
          _buildInfoRow('Paid', '₹ ${sale.paidAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  void _shareInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share coming soon')));
  }

  void _downloadPdf(BuildContext context) {
    final url = '${ApiConstants.baseUrl}${ApiConstants.invoices}/sales/$saleId/preview';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF: $url')));
  }
}

class NumberToWords {
  static final _units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
  static final _teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
  static final _tens = ['', 'Ten', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  static String convert(double value) {
    final rupees = value.toInt();
    final paise = ((value - rupees) * 100).round();
    final rupeeWords = _convertNumber(rupees);
    final paiseWords = paise > 0 ? '${_convertNumber(paise)} Paise' : '';
    if (rupeeWords.isEmpty && paiseWords.isEmpty) return 'Zero';
    if (rupeeWords.isEmpty) return paiseWords;
    if (paiseWords.isEmpty) return rupeeWords;
    return '$rupeeWords and $paiseWords';
  }

  static String _convertNumber(int number) {
    if (number == 0) return '';
    if (number < 10) return _units[number];
    if (number < 20) return _teens[number - 10];
    if (number < 100) return _tens[number ~/ 10] + (number % 10 != 0 ? ' ${_units[number % 10]}' : '');
    if (number < 1000) return '${_units[number ~/ 100]} Hundred${number % 100 != 0 ? ' and ${_convertNumber(number % 100)}' : ''}';
    if (number < 100000) return '${_convertNumber(number ~/ 1000)} Thousand${number % 1000 != 0 ? ' ${_convertNumber(number % 1000)}' : ''}';
    if (number < 10000000) return '${_convertNumber(number ~/ 100000)} Lakh${number % 100000 != 0 ? ' ${_convertNumber(number % 100000)}' : ''}';
    return '${_convertNumber(number ~/ 10000000)} Crore${number % 10000000 != 0 ? ' ${_convertNumber(number % 10000000)}' : ''}';
  }
}
