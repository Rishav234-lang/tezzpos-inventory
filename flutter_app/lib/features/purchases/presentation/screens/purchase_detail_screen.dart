import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';

final purchaseDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiConstants.purchases}/$id');
  return response.data as Map<String, dynamic>;
});

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final String purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen> {
  bool _isUpdating = false;

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
      await api.patch('${ApiConstants.purchases}/${widget.purchaseId}', data: {
        'paidAmount': currentPaid + result,
      });
      ref.invalidate(purchaseDetailProvider(widget.purchaseId));
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
              if (s == currentStatus) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 16, color: AppColors.success),
              ],
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
      await api.patch('${ApiConstants.purchases}/${widget.purchaseId}', data: body);
      ref.invalidate(purchaseDetailProvider(widget.purchaseId));
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

  Color _statusColor(String s) {
    switch (s) {
      case 'PAID': return AppColors.success;
      case 'PARTIAL': return Colors.orange;
      default: return AppColors.error;
    }
  }

  double _toDouble(dynamic val, {double fallback = 0}) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
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
    final detailAsync = ref.watch(purchaseDetailProvider(widget.purchaseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: () => ref.invalidate(purchaseDetailProvider(widget.purchaseId))),
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
              onPressed: () => ref.invalidate(purchaseDetailProvider(widget.purchaseId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        )),
        data: (p) {
          final status = p['status'] ?? 'UNPAID';
          final total = _toDouble(p['totalAmount']);
          final paid = _toDouble(p['paidAmount']);
          final balance = _toDouble(p['balanceAmount'], fallback: total - paid);
          final vendor = p['vendor'] as Map<String, dynamic>?;
          final items = (p['items'] as List<dynamic>?) ?? [];

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(p['invoiceNumber'] ?? 'N/A',
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
                            _infoRow('Vendor', vendor?['name'] ?? 'Unknown'),
                            _infoRow('Date', _fmtDate(p['purchaseDate'])),
                            _infoRow('Notes', p['notes'] ?? '-'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amounts Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _amountRow('Total Amount', total, isBold: true),
                            const Divider(height: 16),
                            _amountRow('Paid Amount', paid, color: AppColors.success),
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
                                      child: Text('${item['quantity']} x ₹${item['purchasePrice']}',
                                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                                    ),
                                    Expanded(
                                      child: Text('₹${_toDouble(item['totalAmount'], fallback: _toDouble(item['quantity']) * _toDouble(item['purchasePrice'])).toStringAsFixed(2)}',
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

              // Bottom Action Bar
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
}
