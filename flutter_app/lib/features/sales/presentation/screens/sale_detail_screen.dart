import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';

final saleDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.sales}/$id');
  return response.data as Map<String, dynamic>;
});

class SaleDetailScreen extends ConsumerStatefulWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _isUpdating = false;

  double _toDouble(dynamic val, {double fallback = 0}) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  Future<void> _recordPayment(double totalAmount, double currentPaid) async {
    final controller = TextEditingController(
      text: (totalAmount - currentPaid).toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: const Icon(Icons.currency_rupee),
            helperText: 'Balance: ₹${(totalAmount - currentPaid).toStringAsFixed(2)}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('${ApiConstants.sales}/${widget.saleId}', data: {
        'paidAmount': currentPaid + result,
      });
      ref.invalidate(saleDetailProvider(widget.saleId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStatus(String currentStatus) async {
    final statuses = ['UNPAID', 'PARTIAL', 'PAID'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Status'),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, s),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: _statusColor(s)),
              const SizedBox(width: 12),
              Text(s),
              if (s == currentStatus) ...[const SizedBox(width: 8), const Icon(Icons.check, size: 16, color: AppColors.success)],
            ],
          ),
        )).toList(),
      ),
    );
    if (selected == null || selected == currentStatus || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = selected == 'PAID'
          ? {'status': 'PAID', 'paidAmount': 0}
          : {'status': selected};
      await api.patch('${ApiConstants.sales}/${widget.saleId}', data: body);
      ref.invalidate(saleDetailProvider(widget.saleId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $selected'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showInvoiceDialog(Map<String, dynamic> sale) {
    final items = (sale['items'] as List<dynamic>?) ?? [];
    final customer = sale['customer'] as Map<String, dynamic>?;
    final invoiceNum = sale['invoiceNumber'] ?? 'N/A';
    final date = _fmtDate(sale['invoiceDate'] ?? sale['createdAt']);
    final total = _toDouble(sale['totalAmount']);
    final subtotal = _toDouble(sale['subtotal']);
    final discount = _toDouble(sale['discount']);
    final tax = _toDouble(sale['taxAmount']);
    final cgst = _toDouble(sale['cgstAmount']);
    final sgst = _toDouble(sale['sgstAmount']);
    final paid = _toDouble(sale['paidAmount']);
    final balance = _toDouble(sale['balanceAmount']);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Invoice Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INVOICE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text(invoiceNum, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text(sale['paymentMode'] ?? '', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              // Customer
              if (customer != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer['name'] ?? 'Walk-in', style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (customer['mobile'] != null) Text(customer['mobile'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            if (customer['gstNumber'] != null) Text('GST: ${customer['gstNumber']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              // Items Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                    const Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                    const Expanded(child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                    const Expanded(child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Items
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final product = item['product'] as Map<String, dynamic>?;
                    final qty = item['quantity'] ?? 0;
                    final price = _toDouble(item['sellingPrice']);
                    final itemTotal = _toDouble(item['totalAmount']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 13)),
                              Text(product?['sku'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          )),
                          Expanded(child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text('₹${price.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                          Expanded(child: Text('₹${itemTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Totals
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _invoiceRow('Subtotal', subtotal),
                    if (discount > 0) _invoiceRow('Discount', -discount),
                    if (cgst > 0) _invoiceRow('CGST', cgst),
                    if (sgst > 0) _invoiceRow('SGST', sgst),
                    if (tax > 0 && cgst == 0) _invoiceRow('Tax', tax),
                    const Divider(height: 12),
                    _invoiceRow('Total', total, isBold: true),
                    _invoiceRow('Paid', paid, color: AppColors.success),
                    _invoiceRow('Balance', balance, color: AppColors.error),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text = _buildInvoiceText(sale);
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInvoiceText(Map<String, dynamic> sale) {
    final items = (sale['items'] as List<dynamic>?) ?? [];
    final sb = StringBuffer();
    sb.writeln('Invoice: ${sale['invoiceNumber']}');
    sb.writeln('Date: ${_fmtDate(sale['invoiceDate'] ?? sale['createdAt'])}');
    sb.writeln('---');
    for (final item in items) {
      final p = item['product'] as Map<String, dynamic>?;
      sb.writeln('${p?['name'] ?? ''} x${item['quantity']} = ₹${_toDouble(item['totalAmount']).toStringAsFixed(2)}');
    }
    sb.writeln('---');
    sb.writeln('Total: ₹${_toDouble(sale['totalAmount']).toStringAsFixed(2)}');
    return sb.toString();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAID': return AppColors.success;
      case 'PARTIAL': return Colors.orange;
      default: return AppColors.error;
    }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(saleDetailProvider(widget.saleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Invoice',
            onPressed: () => detailAsync.whenData((s) => _showInvoiceDialog(s)),
          ),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: () => ref.invalidate(saleDetailProvider(widget.saleId))),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(saleDetailProvider(widget.saleId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        )),
        data: (s) {
          final status = s['status'] ?? 'UNPAID';
          final total = _toDouble(s['totalAmount']);
          final paid = _toDouble(s['paidAmount']);
          final balance = _toDouble(s['balanceAmount']);
          final subtotal = _toDouble(s['subtotal']);
          final discount = _toDouble(s['discount']);
          final tax = _toDouble(s['taxAmount']);
          final cgst = _toDouble(s['cgstAmount']);
          final sgst = _toDouble(s['sgstAmount']);
          final customer = s['customer'] as Map<String, dynamic>?;
          final items = (s['items'] as List<dynamic>?) ?? [];

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(s['invoiceNumber'] ?? 'N/A',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(status))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _infoRow('Customer', customer?['name'] ?? 'Walk-in'),
                            _infoRow('Date', _fmtDate(s['invoiceDate'] ?? s['createdAt'])),
                            _infoRow('Payment Mode', s['paymentMode'] ?? '-'),
                            _infoRow('Notes', s['notes'] ?? '-'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amounts
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _amountRow('Subtotal', subtotal),
                            if (discount > 0) _amountRow('Discount', discount),
                            if (cgst > 0) _amountRow('CGST', cgst),
                            if (sgst > 0) _amountRow('SGST', sgst),
                            if (tax > 0 && cgst == 0) _amountRow('Tax', tax),
                            const Divider(height: 16),
                            _amountRow('Total', total, isBold: true),
                            _amountRow('Paid', paid, color: AppColors.success),
                            _amountRow('Balance', balance, color: AppColors.error),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Items (${items.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ...items.map((item) {
                              final product = item['product'] as Map<String, dynamic>?;
                              final qty = item['quantity'] ?? 0;
                              final price = _toDouble(item['sellingPrice']);
                              final itemTotal = _toDouble(item['totalAmount']);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                          Text('SKU: ${product?['sku'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text('$qty x ₹${price.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                                    ),
                                    Expanded(
                                      child: Text('₹${itemTotal.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Actions
              if (status != 'PAID')
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isUpdating ? null : () => _recordPayment(total, paid),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Record Payment'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isUpdating ? null : () => _updateStatus(status),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Status'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.grey.shade700,
          )),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black,
          )),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 15 : 13,
            color: color,
          )),
        ],
      ),
    );
  }
}
