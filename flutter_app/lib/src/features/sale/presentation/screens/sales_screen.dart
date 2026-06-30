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
import '../providers/sale_providers.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _CartItem {
  final Product product;
  int quantity;

  _CartItem({required this.product, this.quantity = 1});

  double get taxableAmount => quantity * product.sellingPrice;

  double get taxAmount {
    final taxable = taxableAmount;
    if (taxable <= 0) return 0;
    return (taxable * product.gstRate) / 100;
  }

  double get totalAmount => taxableAmount + taxAmount;
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();
  var _search = '';
  Customer? _selectedCustomer;
  final List<_CartItem> _cart = [];
  final double _saleDiscount = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _removeFromCart(_CartItem item) {
    setState(() => _cart.remove(item));
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
    final productsAsync = ref.watch(productsProvider(ProductFilter(search: _search, limit: 20)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                data: (products) => ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(p.name.isNotEmpty ? p.name[0] : 'P', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(p.name),
                      subtitle: Text('SKU: ${p.sku ?? 'N/A'} | Stock: ${p.totalStock}'),
                      trailing: Text('₹ ${p.sellingPrice.toStringAsFixed(2)}'),
                      onTap: () {
                        _addToCart(p);
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.outline),
          const SizedBox(height: 12),
          Text('Cart is empty', style: context.textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Search products to add items', style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
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
                    Text('₹ ${item.product.sellingPrice.toStringAsFixed(2)} × ${item.quantity}', style: TextStyle(fontSize: 13, color: AppColors.onSurface)),
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
              Text('₹ ${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _proceedToPay() async {
    final items = _cart.map((item) => {
      'productId': item.product.id,
      'quantity': item.quantity,
      'sellingPrice': item.product.sellingPrice,
      'discount': 0,
    }).toList();

    final data = {
      'customerId': _selectedCustomer?.id,
      'paidAmount': _grandTotal,
      'paymentMethod': 'CASH',
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
    ref.invalidate(salesProvider(SaleFilter()));
    context.push('${AppRoutes.billInvoice}/${sale.id}');
  }
}
