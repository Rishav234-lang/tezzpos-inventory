import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/sale_providers.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _CartItem {
  final Product product;
  int quantity;
  double customSellingPrice;
  final TextEditingController priceController;

  _CartItem({required this.product, this.quantity = 1, double? customPrice})
      : customSellingPrice = customPrice ?? product.sellingPrice,
        priceController = TextEditingController(text: (customPrice ?? product.sellingPrice).toStringAsFixed(2));

  double get effectivePrice => customSellingPrice;

  double get taxableAmount => quantity * effectivePrice;

  double get taxAmount {
    final taxable = taxableAmount;
    if (taxable <= 0) return 0;
    return (taxable * product.gstRate) / 100;
  }

  double get totalAmount => taxableAmount + taxAmount;

  void dispose() => priceController.dispose();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();
  var _search = '';
  Customer? _selectedCustomer;
  final List<_CartItem> _cart = [];
  final double _saleDiscount = 0;
  String _paymentMethod = 'CASH';
  bool _isSaving = false;


  void _addToCart(Product product) {
    final existing = _cart.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => _CartItem(product: product, quantity: 0),
    );
    setState(() {
      if (existing.quantity == 0) {
        _cart.add(_CartItem(product: product));
      } else {
        existing.quantity++;
      }
    });
  }

  void _updateItemPrice(_CartItem item, double newPrice) {
    setState(() {
      item.customSellingPrice = newPrice;
    });
  }

  void _removeFromCart(_CartItem item) {
    item.dispose();
    setState(() => _cart.remove(item));
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final item in _cart) {
      item.dispose();
    }
    super.dispose();
  }

  void _updateQuantity(_CartItem item, int delta) {
    setState(() {
      item.quantity = (item.quantity + delta).clamp(1, 9999);
    });
  }

  double get _subtotal => _cart.fold(0.0, (sum, item) => sum + item.taxableAmount + item.taxAmount);
  double get _totalDiscount => _saleDiscount;
  double get _grandTotal => _cart.fold(0.0, (sum, item) => sum + item.totalAmount) - _saleDiscount;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productPickerProvider(_search.isEmpty ? null : _search));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.go(AppRoutes.dashboard), icon: const Icon(Icons.arrow_back)),
        title: const Text('New Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sales History',
            onPressed: () => context.push(AppRoutes.salesHistory),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCustomerBar(),
          _buildSearchBar(productsAsync),
          Expanded(
            child: _cart.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(),
          ),
          _buildTotalsPanel(),
        ],
      ),
    );
  }

  Widget _buildCustomerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Walk-in'),
            selected: _selectedCustomer == null,
            onSelected: (_) => setState(() => _selectedCustomer = null),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: _selectedCustomer == null ? Colors.white : AppColors.onSurface),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(_selectedCustomer?.name ?? 'Select Customer'),
            selected: _selectedCustomer != null,
            onSelected: (_) => _selectCustomer(),
            selectedColor: const Color(0xFFE3F2FD),
            labelStyle: TextStyle(color: _selectedCustomer != null ? AppColors.primary : AppColors.onSurface),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.addCustomer),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomer() async {
    final customer = await context.push<Customer>(AppRoutes.selectSaleCustomer);
    if (customer != null) setState(() => _selectedCustomer = customer);
  }

  Widget _buildSearchBar(AsyncValue<List<Product>> productsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search product by name, SKU or barcode',
              hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
              prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_search.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) return const Center(child: Text('No matching products'));
                  return ListView.builder(
                    itemCount: products.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Material(
                        color: AppColors.surface,
                        child: InkWell(
                          onTap: () {
                            _addToCart(p);
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.1))),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(child: Text(
                                    p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('SKU: ${p.sku ?? 'N/A'}  •  Stock: ${p.totalStock}',
                                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                Text('₹ ${NumberFormat('#,##,##0.00').format(p.sellingPrice)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e', style: TextStyle(color: AppColors.error)))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.shopping_cart_outlined, color: AppColors.primary.withValues(alpha: 0.5), size: 40),
            ),
            const SizedBox(height: 20),
            Text('Cart is Empty', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Search products above to add items to the cart.',
                style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('SKU: ${item.product.sku ?? 'N/A'}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 28,
                          child: TextField(
                            controller: item.priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (value) {
                              final parsed = double.tryParse(value) ?? item.product.sellingPrice;
                              final clamped = parsed < 0 ? item.product.sellingPrice : parsed;
                              _updateItemPrice(item, clamped);
                              item.priceController.text = clamped.toStringAsFixed(2);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('× ${item.quantity}', style: TextStyle(fontSize: 13, color: AppColors.onSurface)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => item.quantity > 1 ? _updateQuantity(item, -1) : _removeFromCart(item),
                  ),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _updateQuantity(item, 1),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text('₹ ${NumberFormat('#,##,##0.00').format(item.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalsPanel() {
    final currency = NumberFormat('#,##,##0.00');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Items', style: TextStyle(color: AppColors.onSurfaceVariant)),
              Text('${_cart.length}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Qty', style: TextStyle(color: AppColors.onSurfaceVariant)),
              Text('${_cart.fold(0, (sum, i) => sum + i.quantity)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: AppColors.onSurfaceVariant)),
              Text('₹ ${currency.format(_subtotal)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discount', style: TextStyle(color: AppColors.onSurfaceVariant)),
              Text('₹ ${currency.format(_totalDiscount)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Method', style: TextStyle(color: AppColors.onSurfaceVariant)),
              GestureDetector(
                onTap: _showPaymentMethodPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_paymentMethodLabel(_paymentMethod), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹ ${currency.format(_grandTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _cart.isEmpty || _isSaving ? null : _proceedToPay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Proceed to Pay'),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'UPI': return 'UPI';
      case 'CARD': return 'Card';
      case 'BANK_TRANSFER': return 'Bank Transfer';
      case 'CASH':
      default: return 'Cash';
    }
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const methods = ['CASH', 'UPI', 'CARD', 'BANK_TRANSFER'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...methods.map((m) => ListTile(
                  leading: Icon(_paymentMethodIcon(m), color: _paymentMethod == m ? AppColors.primary : AppColors.onSurfaceVariant),
                  title: Text(_paymentMethodLabel(m)),
                  trailing: _paymentMethod == m ? Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _paymentMethod = m);
                    context.pop();
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'UPI': return Icons.account_balance_wallet_outlined;
      case 'CARD': return Icons.credit_card_outlined;
      case 'BANK_TRANSFER': return Icons.account_balance_outlined;
      case 'CASH':
      default: return Icons.payments_outlined;
    }
  }

  Future<void> _proceedToPay() async {
    final items = _cart.map((item) => {
      'productId': item.product.id,
      'quantity': item.quantity,
      'sellingPrice': item.effectivePrice,
      'discount': 0,
    }).toList();

    final data = {
      'customerId': _selectedCustomer?.id,
      'paidAmount': _grandTotal,
      'paymentMethod': _paymentMethod,
      'discount': _saleDiscount,
      'items': items,
    };

    setState(() => _isSaving = true);
    final sale = await ref.read(saleNotifierProvider.notifier).createSale(data);
    setState(() => _isSaving = false);

    if (sale == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ref.read(saleNotifierProvider).error}'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!mounted) return;
    ref.invalidate(salesProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(dashboardStatsProvider);
    context.go(AppRoutes.inventory);
  }
}
