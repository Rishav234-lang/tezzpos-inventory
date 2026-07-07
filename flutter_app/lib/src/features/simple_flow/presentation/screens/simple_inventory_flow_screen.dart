import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../customer/domain/entities/customer.dart' as customer_entity;
import '../../../customer/presentation/providers/customer_providers.dart';
import '../../../product/domain/entities/product.dart' as product_entity;
import '../../../product/presentation/providers/product_providers.dart';
import '../../../purchase/presentation/providers/purchase_providers.dart';
import '../../../sale/presentation/providers/sale_providers.dart';
import '../../../vendor/domain/entities/vendor.dart' as vendor_entity;
import '../../../vendor/presentation/providers/vendor_providers.dart';

enum _SimpleFlowStep { choose, purchase, sell, suppliers }

class _Supplier {
  final String id;
  final String name;
  final String mobile;

  const _Supplier({required this.id, required this.name, required this.mobile});

  _Supplier copyWith({String? name, String? mobile}) {
    return _Supplier(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
    );
  }
}

class _Customer {
  final String id;
  final String name;
  final String mobile;

  const _Customer({required this.id, required this.name, required this.mobile});
}

class _CreatedProduct {
  final String name;
  final String unit;
  final double sellingPrice;
  final double gstRate;
  final int minStockLevel;
  final String? description;

  const _CreatedProduct({
    required this.name,
    required this.unit,
    required this.sellingPrice,
    required this.gstRate,
    required this.minStockLevel,
    this.description,
  });
}

class SimpleInventoryFlowScreen extends ConsumerStatefulWidget {
  final String? initialMode;

  const SimpleInventoryFlowScreen({super.key, this.initialMode});

  static const bg = Color(0xFFF6F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F242B);
  static const muted = Color(0xFF6B7280);
  static const primary = Color(0xFF343A40);
  static const primaryDark = Color(0xFF20242A);
  static const primarySoft = Color(0xFFECEEF2);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFE3F8E9);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFFF4D6);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFFE4E4);
  static const border = Color(0xFFE1E5EA);

  @override
  ConsumerState<SimpleInventoryFlowScreen> createState() =>
      _SimpleInventoryFlowScreenState();
}

class _SimpleInventoryFlowScreenState
    extends ConsumerState<SimpleInventoryFlowScreen> {
  static const _createSupplierValue = '__create_supplier__';
  static const _createProductValue = '__create_product__';
  static const _createCustomerValue = '__create_customer__';

  final _invoiceNoController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _purchaseQtyController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _sellQtyController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _sellPaidAmountController = TextEditingController();

  late _SimpleFlowStep _step;
  String? _selectedSupplierId;
  String? _selectedPurchaseProduct;
  String? _selectedSaleProduct;
  String? _selectedCustomerId;
  String _paymentType = 'Cash';
  int _supplierDropdownVersion = 0;
  int _productDropdownVersion = 0;
  int _customerDropdownVersion = 0;

  final List<_Supplier> _localSuppliers = [];
  final List<_Customer> _localCustomers = [];
  final Map<String, product_entity.Product> _productsByName = {};
  final Map<String, int> _stock = {};
  final Map<String, String> _productUnits = {};
  bool _isSaving = false;
  String _lastSuggestedPurchasePaidAmount = '';
  String _lastSuggestedSalePaidAmount = '';

  @override
  void initState() {
    super.initState();
    _step = switch (widget.initialMode) {
      'purchase' => _SimpleFlowStep.purchase,
      'sell' => _SimpleFlowStep.sell,
      _ => _SimpleFlowStep.choose,
    };
    _purchaseQtyController.addListener(_updatePurchasePaidAmount);
    _buyPriceController.addListener(_updatePurchasePaidAmount);
    _paidAmountController.addListener(_refreshPurchaseAmounts);
    _sellQtyController.addListener(_updateSalePaidAmount);
    _sellPriceController.addListener(_updateSalePaidAmount);
    _sellPaidAmountController.addListener(_refreshSaleAmounts);
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _expiryDateController.dispose();
    _purchaseQtyController.dispose();
    _buyPriceController.dispose();
    _paidAmountController.dispose();
    _sellQtyController.dispose();
    _sellPriceController.dispose();
    _sellPaidAmountController.dispose();
    super.dispose();
  }

  void _open(_SimpleFlowStep step) => setState(() => _step = step);

  Future<void> _handleSupplierChange(String? value) async {
    if (value == null) return;
    if (value == _createSupplierValue) {
      final supplier = await _showSupplierDialog();
      if (supplier == null) {
        setState(() => _supplierDropdownVersion++);
        return;
      }
      final saved = await _createSupplierOnServer(supplier);
      if (saved == null) return;
      setState(() {
        _localSuppliers.add(saved);
        _selectedSupplierId = saved.id;
        _supplierDropdownVersion++;
      });
      _showMessage('Supplier created and selected.');
      return;
    }
    setState(() => _selectedSupplierId = value);
  }

  Future<void> _handlePurchaseProductChange(String? value) async {
    if (value == null) return;
    if (value == _createProductValue) {
      final product = await _showProductDialog();
      if (product == null) {
        setState(() => _productDropdownVersion++);
        return;
      }
      final saved = await _createProductOnServer(product);
      if (saved == null) return;
      setState(() {
        _stock.putIfAbsent(saved.name, () => saved.totalStock);
        _productUnits[saved.name] = saved.unit;
        _productsByName[saved.name] = saved;
        _selectedPurchaseProduct = saved.name;
        _productDropdownVersion++;
      });
      _showMessage('Product created and selected.');
      return;
    }
    setState(() => _selectedPurchaseProduct = value);
  }

  Future<void> _pickSaleProduct() async {
    final product = await _showProductPicker();
    if (product == null) return;
    setState(() => _selectedSaleProduct = product);
  }

  void _updateSalePaidAmount() {
    final quantity = int.tryParse(_sellQtyController.text.trim()) ?? 0;
    final sellPrice = double.tryParse(_sellPriceController.text.trim()) ?? 0;
    final total = quantity * sellPrice;
    final nextText = total > 0 ? _formatMoneyText(total) : '';
    final currentText = _sellPaidAmountController.text.trim();
    final shouldReplace =
        currentText.isEmpty || currentText == _lastSuggestedSalePaidAmount;

    _lastSuggestedSalePaidAmount = nextText;
    if (shouldReplace && currentText != nextText) {
      _sellPaidAmountController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
    _refreshSaleAmounts();
  }

  void _updatePurchasePaidAmount() {
    final quantity = int.tryParse(_purchaseQtyController.text.trim()) ?? 0;
    final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0;
    final total = quantity * buyPrice;
    final nextText = total > 0 ? _formatMoneyText(total) : '';
    final currentText = _paidAmountController.text.trim();
    final shouldReplace =
        currentText.isEmpty || currentText == _lastSuggestedPurchasePaidAmount;

    _lastSuggestedPurchasePaidAmount = nextText;
    if (shouldReplace && currentText != nextText) {
      _paidAmountController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
    _refreshPurchaseAmounts();
  }

  void _refreshPurchaseAmounts() {
    if (!mounted) return;
    setState(() {});
  }

  void _refreshSaleAmounts() {
    if (!mounted) return;
    setState(() {});
  }

  String _formatMoneyText(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  double get _purchaseTotal {
    final quantity = int.tryParse(_purchaseQtyController.text.trim()) ?? 0;
    final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0;
    return quantity * buyPrice;
  }

  double get _purchaseDue {
    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? 0;
    return max(0, _purchaseTotal - paidAmount);
  }

  double get _saleTotal {
    final quantity = int.tryParse(_sellQtyController.text.trim()) ?? 0;
    final sellPrice = double.tryParse(_sellPriceController.text.trim()) ?? 0;
    return quantity * sellPrice;
  }

  double get _saleDue {
    final paidAmount =
        double.tryParse(_sellPaidAmountController.text.trim()) ?? 0;
    return max(0, _saleTotal - paidAmount);
  }

  Future<void> _handleCustomerChange(String? value) async {
    if (value == null) return;
    if (value == _createCustomerValue) {
      final customer = await _showCustomerDialog();
      if (customer == null) {
        setState(() => _customerDropdownVersion++);
        return;
      }
      final saved = await _createCustomerOnServer(customer);
      if (saved == null) return;
      setState(() {
        _localCustomers.add(saved);
        _selectedCustomerId = saved.id;
        _customerDropdownVersion++;
      });
      _showMessage('Customer created and selected.');
      return;
    }
    setState(() => _selectedCustomerId = value);
  }

  String get _selectedPurchaseUnit {
    final product = _selectedPurchaseProduct;
    if (product == null) return '';
    return _productUnits[product] ?? '';
  }

  Future<String?> _showProductPicker() async {
    final searchController = TextEditingController();
    var query = '';

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SimpleInventoryFlowScreen.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final products = _productNames
                .where(
                  (product) =>
                      product.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: _fieldDecoration(
                        label: 'Search product',
                        hint: 'Type product name',
                        icon: Icons.search,
                      ),
                      onChanged: (value) =>
                          setSheetState(() => query = value.trim()),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: products.isEmpty
                          ? const _PlainHelp(text: 'No product found.')
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: products.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final stock = _stock[product] ?? 0;
                                final unit = _productUnits[product] ?? '';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor:
                                        SimpleInventoryFlowScreen.primarySoft,
                                    foregroundColor:
                                        SimpleInventoryFlowScreen.primary,
                                    child: Icon(Icons.inventory_2_outlined),
                                  ),
                                  title: Text(product),
                                  subtitle: Text(
                                    unit.isEmpty
                                        ? 'Stock: $stock'
                                        : 'Stock: $stock $unit',
                                  ),
                                  onTap: () => Navigator.pop(context, product),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return selected;
  }

  Future<_Supplier?> _showSupplierDialog({_Supplier? supplier}) async {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final mobileController = TextEditingController(
      text: supplier?.mobile ?? '',
    );

    final saved = await showDialog<_Supplier>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(supplier == null ? 'Create Supplier' : 'Edit Supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Agency / Supplier name',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number optional',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  context,
                  _Supplier(
                    id:
                        supplier?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    mobile: mobileController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    mobileController.dispose();
    return saved;
  }

  Future<_Customer?> _showCustomerDialog() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    final saved = await showDialog<_Customer>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number optional',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  context,
                  _Customer(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    mobile: mobileController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    mobileController.dispose();
    return saved;
  }

  Future<_CreatedProduct?> _showProductDialog() async {
    final nameController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final minStockController = TextEditingController(text: '10');
    final descriptionController = TextEditingController();
    var unit = 'PCS';
    var gstRate = 0.0;

    final saved = await showDialog<_CreatedProduct>(
      context: context,
      builder: (context) {
        final dialogWidth = MediaQuery.sizeOf(context).width;
        return AlertDialog(
          title: const Text('Create Product'),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: dialogWidth > 700 ? 620 : dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogTextField(
                        controller: nameController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        icon: Icons.inventory_2_outlined,
                        autofocus: true,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: _fieldDecoration(
                          label: 'Unit',
                          icon: Icons.straighten,
                        ),
                        items:
                            const [
                                  'PCS',
                                  'KG',
                                  'LTR',
                                  'BOX',
                                  'PACK',
                                  'BOTTLE',
                                  'DOZEN',
                                ]
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => unit = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _DialogTextField(
                        controller: sellingPriceController,
                        label: 'Selling Price',
                        hint: '0.00',
                        icon: Icons.sell_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<double>(
                        initialValue: gstRate,
                        decoration: _fieldDecoration(
                          label: 'Tax (GST)',
                          icon: Icons.percent,
                        ),
                        items: const [0.0, 5.0, 12.0, 18.0, 28.0]
                            .map(
                              (rate) => DropdownMenuItem(
                                value: rate,
                                child: Text('${rate.toStringAsFixed(0)}%'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => gstRate = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _DialogTextField(
                        controller: minStockController,
                        label: 'Minimum Stock Level',
                        hint: '10',
                        icon: Icons.warning_amber_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _DialogTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Optional',
                        icon: Icons.notes_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final sellingPrice = sellingPriceController.text.trim();

                if (name.isEmpty || sellingPrice.isEmpty) {
                  return;
                }
                Navigator.pop(
                  context,
                  _CreatedProduct(
                    name: name,
                    unit: unit,
                    sellingPrice: double.tryParse(sellingPrice) ?? 0,
                    gstRate: gstRate,
                    minStockLevel:
                        int.tryParse(minStockController.text.trim()) ?? 10,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  ),
                );
              },
              child: const Text('Save Product'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    sellingPriceController.dispose();
    minStockController.dispose();
    descriptionController.dispose();
    return saved;
  }

  Future<void> _createSupplierFromList() async {
    final supplier = await _showSupplierDialog();
    if (supplier == null) return;
    final saved = await _createSupplierOnServer(supplier);
    if (saved == null) return;
    setState(() {
      _localSuppliers.add(saved);
      _selectedSupplierId ??= saved.id;
    });
    _showMessage('Supplier created.');
  }

  Future<void> _editSupplier(_Supplier supplier) async {
    final updated = await _showSupplierDialog(supplier: supplier);
    if (updated == null) return;
    try {
      final saved = await ref
          .read(vendorRemoteDataSourceProvider)
          .updateVendor(supplier.id, {
            'name': updated.name,
            'mobile': updated.mobile.isEmpty ? null : updated.mobile,
            'status': 'ACTIVE',
          });
      ref.invalidate(vendorsProvider(VendorFilter(limit: 200)));
      setState(() {
        final index = _localSuppliers.indexWhere(
          (item) => item.id == supplier.id,
        );
        if (index != -1) {
          _localSuppliers[index] = _Supplier(
            id: saved.id,
            name: saved.name,
            mobile: saved.mobile ?? '',
          );
        }
      });
      _showMessage('Supplier updated.');
    } catch (e) {
      _showMessage('Supplier not updated: $e');
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    _expiryDateController.text =
        '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
  }

  Future<_Supplier?> _createSupplierOnServer(_Supplier supplier) async {
    try {
      final vendor = await ref
          .read(vendorRemoteDataSourceProvider)
          .createVendor({
            'name': supplier.name,
            'mobile': supplier.mobile.isEmpty ? null : supplier.mobile,
            'status': 'ACTIVE',
          });
      ref.invalidate(vendorsProvider(VendorFilter(limit: 200)));
      return _Supplier(
        id: vendor.id,
        name: vendor.name,
        mobile: vendor.mobile ?? '',
      );
    } catch (e) {
      _showMessage('Supplier not saved: $e');
      return null;
    }
  }

  Future<_Customer?> _createCustomerOnServer(_Customer customer) async {
    try {
      final saved = await ref
          .read(customerRemoteDataSourceProvider)
          .createCustomer({
            'name': customer.name,
            'mobile': customer.mobile.isEmpty ? null : customer.mobile,
            'status': 'ACTIVE',
          });
      ref.invalidate(customersProvider(CustomerFilter(limit: 200)));
      return _Customer(
        id: saved.id,
        name: saved.name,
        mobile: saved.mobile ?? '',
      );
    } catch (e) {
      _showMessage('Customer not saved: $e');
      return null;
    }
  }

  Future<product_entity.Product?> _createProductOnServer(
    _CreatedProduct product,
  ) async {
    try {
      final saved = await ref
          .read(productRemoteDataSourceProvider)
          .createProduct({
            'name': product.name,
            'sku': null,
            'barcode': null,
            'categoryId': null,
            'imageUrl': null,
            'unit': product.unit,
            'hsnCode': null,
            'gstRate': product.gstRate,
            'costPrice': 0,
            'sellingPrice': product.sellingPrice,
            'minStockLevel': product.minStockLevel,
            'description': product.description,
            'status': 'ACTIVE',
          });
      ref.invalidate(productsProvider(ProductFilter(limit: 200)));
      return saved;
    } catch (e) {
      _showMessage('Product not saved: $e');
      return null;
    }
  }

  Future<void> _savePurchase() async {
    if (_isSaving) return;
    if (_selectedSupplierId == null) {
      _showMessage('Please select supplier.');
      return;
    }
    final product = _selectedPurchaseProduct;
    final invoiceNo = _invoiceNoController.text.trim();
    final quantity = int.tryParse(_purchaseQtyController.text.trim()) ?? 0;
    final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? 0;

    if (invoiceNo.isEmpty ||
        product == null ||
        quantity <= 0 ||
        buyPrice <= 0) {
      _showMessage('Please enter invoice no, product, quantity and buy price.');
      return;
    }

    final selectedProduct = _productsByName[product];
    if (selectedProduct == null) {
      _showMessage('Please select a valid product from list.');
      return;
    }

    final oldStock = selectedProduct.totalStock;
    final total = quantity * buyPrice;
    final due = max(0, total - paidAmount);
    DateTime? expiryDate;
    final expiryText = _expiryDateController.text.trim();
    if (expiryText.isNotEmpty) {
      final parts = expiryText.split('-');
      if (parts.length == 3) {
        expiryDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
    }

    setState(() => _isSaving = true);
    final data = {
      'vendorId': _selectedSupplierId,
      'invoiceNumber': invoiceNo,
      'purchaseDate': DateTime.now().toIso8601String(),
      'paidAmount': paidAmount,
      'notes': null,
      'items': [
        {
          'productId': selectedProduct.id,
          'quantity': quantity,
          'purchasePrice': buyPrice,
          'mrp': selectedProduct.sellingPrice > 0
              ? selectedProduct.sellingPrice
              : buyPrice,
          'expiryDate': expiryDate?.toIso8601String(),
        },
      ],
    };

    await ref.read(purchaseNotifierProvider.notifier).createPurchase(data);
    if (!mounted) return;
    setState(() => _isSaving = false);
    final purchaseState = ref.read(purchaseNotifierProvider);
    if (purchaseState.hasError) {
      _showMessage('${purchaseState.error}');
      return;
    }

    final newStock = oldStock + quantity;
    ref.invalidate(productsProvider(ProductFilter(limit: 200)));
    ref.invalidate(purchasesProvider(const PurchaseFilter()));

    setState(() {
      _stock[product] = newStock;
      final current = _productsByName[product];
      if (current != null) {
        _productsByName[product] = product_entity.Product(
          id: current.id,
          name: current.name,
          description: current.description,
          sku: current.sku,
          barcode: current.barcode,
          imageUrl: current.imageUrl,
          categoryId: current.categoryId,
          categoryName: current.categoryName,
          unit: current.unit,
          hsnCode: current.hsnCode,
          gstRate: current.gstRate,
          costPrice: current.costPrice,
          sellingPrice: current.sellingPrice,
          minStockLevel: current.minStockLevel,
          totalStock: newStock,
          stockValue: current.stockValue,
          stockValueMrp: current.stockValueMrp,
          status: current.status,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          firstBatchNumber: current.firstBatchNumber,
          firstExpiryDate: current.firstExpiryDate,
          firstMrp: current.firstMrp,
        );
      }
    });
    _invoiceNoController.clear();
    _expiryDateController.clear();
    _purchaseQtyController.clear();
    _buyPriceController.clear();
    _paidAmountController.clear();
    _lastSuggestedPurchasePaidAmount = '';

    final dueText = due > 0 ? ' Supplier due: ${due.toStringAsFixed(0)}.' : '';
    _showMessage('Purchase saved. Stock: $oldStock to $newStock.$dueText');
  }

  Future<void> _saveSale() async {
    if (_isSaving) return;
    final product = _selectedSaleProduct;
    final quantity = int.tryParse(_sellQtyController.text.trim()) ?? 0;
    final sellPrice = double.tryParse(_sellPriceController.text.trim()) ?? 0;
    final paidAmount =
        double.tryParse(_sellPaidAmountController.text.trim()) ?? 0;

    if (product == null || quantity <= 0 || sellPrice <= 0) {
      _showMessage('Please enter product, quantity and sell price.');
      return;
    }

    final available = _stock[product] ?? 0;
    if (available < quantity) {
      _showMessage('Only $available items available.');
      return;
    }

    final selectedProduct = _productsByName[product];
    if (selectedProduct == null) {
      _showMessage('Please select a valid product from list.');
      return;
    }

    final newStock = available - quantity;
    final total = quantity * sellPrice;
    final due = max(0, total - paidAmount);
    final paymentMethod = _paymentType.toUpperCase();
    setState(() => _isSaving = true);
    final sale = await ref.read(saleNotifierProvider.notifier).createSale({
      'customerId': _selectedCustomerId,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod == 'CARD'
          ? 'CARD'
          : paymentMethod == 'CREDIT'
          ? 'CASH'
          : paymentMethod,
      'discount': 0,
      'items': [
        {
          'productId': selectedProduct.id,
          'quantity': quantity,
          'sellingPrice': sellPrice,
          'discount': 0,
        },
      ],
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (sale == null) {
      _showMessage('${ref.read(saleNotifierProvider).error}');
      return;
    }

    ref.invalidate(productsProvider(ProductFilter(limit: 200)));
    ref.invalidate(salesProvider(SaleFilter()));
    setState(() {
      _stock[product] = newStock;
      _selectedSaleProduct = null;
      _selectedCustomerId = null;
      _customerDropdownVersion++;
    });
    _sellQtyController.clear();
    _sellPriceController.clear();
    _sellPaidAmountController.clear();
    _lastSuggestedSalePaidAmount = '';

    final dueText = due > 0 ? ' Customer due: ${due.toStringAsFixed(0)}.' : '';
    _showMessage(
      'Sale saved. Stock: $available to $newStock. Paid: ${paidAmount.toStringAsFixed(0)}.$dueText',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider(ProductFilter(limit: 200)),
    );
    final suppliersAsync = ref.watch(vendorsProvider(VendorFilter(limit: 200)));
    final customersAsync = ref.watch(
      customersProvider(CustomerFilter(limit: 200)),
    );
    final backendProducts =
        productsAsync.valueOrNull ?? const <product_entity.Product>[];
    final backendSuppliers =
        suppliersAsync.valueOrNull ?? const <vendor_entity.Vendor>[];
    final backendCustomers =
        customersAsync.valueOrNull ?? const <customer_entity.Customer>[];
    _syncBackendData(
      products: backendProducts,
      suppliers: backendSuppliers,
      customers: backendCustomers,
    );
    final suppliers = _combinedSuppliers(backendSuppliers);
    final customers = _combinedCustomers(backendCustomers);
    final loadError =
        productsAsync.error ?? suppliersAsync.error ?? customersAsync.error;
    final isLoading =
        productsAsync.isLoading ||
        suppliersAsync.isLoading ||
        customersAsync.isLoading;
    final canGoBackInside = _step != _SimpleFlowStep.choose;

    return Scaffold(
      backgroundColor: SimpleInventoryFlowScreen.bg,
      appBar: AppBar(
        backgroundColor: SimpleInventoryFlowScreen.bg,
        surfaceTintColor: SimpleInventoryFlowScreen.bg,
        leading: IconButton(
          onPressed: canGoBackInside
              ? () => _open(_SimpleFlowStep.choose)
              : () => context.go(AppRoutes.dashboard),
          icon: Icon(canGoBackInside ? Icons.arrow_back : Icons.close),
        ),
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Suppliers',
            onPressed: () => _open(_SimpleFlowStep.suppliers),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: loadError != null
            ? _LoadFailedView(
                message: 'Unable to load backend data.\n$loadError',
                onRetry: () {
                  ref.invalidate(productsProvider(ProductFilter(limit: 200)));
                  ref.invalidate(vendorsProvider(VendorFilter(limit: 200)));
                  ref.invalidate(customersProvider(CustomerFilter(limit: 200)));
                },
              )
            : isLoading && _step != _SimpleFlowStep.choose
            ? const Center(child: CircularProgressIndicator())
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_step) {
                  _SimpleFlowStep.choose => _ChooseWorkScreen(
                    onPurchase: () => _open(_SimpleFlowStep.purchase),
                    onSell: () => _open(_SimpleFlowStep.sell),
                  ),
                  _SimpleFlowStep.purchase => _PurchaseForm(
                    suppliers: suppliers,
                    products: _productNames,
                    selectedSupplierId: _selectedSupplierId,
                    supplierDropdownVersion: _supplierDropdownVersion,
                    selectedProduct: _selectedPurchaseProduct,
                    selectedProductUnit: _selectedPurchaseUnit,
                    productDropdownVersion: _productDropdownVersion,
                    onSupplierChanged: _handleSupplierChange,
                    onProductChanged: _handlePurchaseProductChange,
                    invoiceNoController: _invoiceNoController,
                    expiryDateController: _expiryDateController,
                    quantityController: _purchaseQtyController,
                    buyPriceController: _buyPriceController,
                    paidAmountController: _paidAmountController,
                    purchaseTotal: _purchaseTotal,
                    purchaseDue: _purchaseDue,
                    onPickExpiryDate: _pickExpiryDate,
                    onSave: _savePurchase,
                    isSaving: _isSaving,
                  ),
                  _SimpleFlowStep.sell => _SellForm(
                    products: _productNames,
                    customers: customers,
                    selectedProduct: _selectedSaleProduct,
                    selectedCustomerId: _selectedCustomerId,
                    customerDropdownVersion: _customerDropdownVersion,
                    onPickProduct: _pickSaleProduct,
                    onCustomerChanged: _handleCustomerChange,
                    quantityController: _sellQtyController,
                    sellPriceController: _sellPriceController,
                    paidAmountController: _sellPaidAmountController,
                    saleTotal: _saleTotal,
                    saleDue: _saleDue,
                    paymentType: _paymentType,
                    onPaymentChanged: (value) =>
                        setState(() => _paymentType = value),
                    onSave: _saveSale,
                    isSaving: _isSaving,
                  ),
                  _SimpleFlowStep.suppliers => _SupplierListScreen(
                    suppliers: suppliers,
                    onCreate: _createSupplierFromList,
                    onEdit: _editSupplier,
                  ),
                },
              ),
      ),
    );
  }

  void _syncBackendData({
    required List<product_entity.Product> products,
    required List<vendor_entity.Vendor> suppliers,
    required List<customer_entity.Customer> customers,
  }) {
    for (final product in products) {
      _productsByName[product.name] = product;
      _stock[product.name] = product.totalStock;
      _productUnits[product.name] = product.unit;
    }
    for (final supplier in suppliers) {
      if (_localSuppliers.every((item) => item.id != supplier.id)) {
        _localSuppliers.add(
          _Supplier(
            id: supplier.id,
            name: supplier.name,
            mobile: supplier.mobile ?? '',
          ),
        );
      }
    }
    for (final customer in customers) {
      if (_localCustomers.every((item) => item.id != customer.id)) {
        _localCustomers.add(
          _Customer(
            id: customer.id,
            name: customer.name,
            mobile: customer.mobile ?? '',
          ),
        );
      }
    }
  }

  List<_Supplier> _combinedSuppliers(List<vendor_entity.Vendor> suppliers) {
    if (suppliers.isEmpty) return List<_Supplier>.from(_localSuppliers);
    return suppliers
        .map(
          (supplier) => _Supplier(
            id: supplier.id,
            name: supplier.name,
            mobile: supplier.mobile ?? '',
          ),
        )
        .toList();
  }

  List<_Customer> _combinedCustomers(List<customer_entity.Customer> customers) {
    if (customers.isEmpty) return List<_Customer>.from(_localCustomers);
    return customers
        .map(
          (customer) => _Customer(
            id: customer.id,
            name: customer.name,
            mobile: customer.mobile ?? '',
          ),
        )
        .toList();
  }

  List<String> get _productNames {
    final names = _stock.keys.toList();
    names.sort();
    return names;
  }
}

class _ChooseWorkScreen extends StatelessWidget {
  final VoidCallback onPurchase;
  final VoidCallback onSell;

  const _ChooseWorkScreen({required this.onPurchase, required this.onSell});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'What do you want to do?',
          style: context.textTheme.headlineSmall?.copyWith(
            color: SimpleInventoryFlowScreen.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose only one work. Stock will be managed automatically.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: SimpleInventoryFlowScreen.muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _WorkButton(
                title: 'Purchase',
                subtitle: 'Goods came in',
                icon: Icons.add_shopping_cart,
                color: SimpleInventoryFlowScreen.green,
                softColor: SimpleInventoryFlowScreen.greenSoft,
                onTap: onPurchase,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WorkButton(
                title: 'Sell',
                subtitle: 'Customer buys',
                icon: Icons.point_of_sale,
                color: SimpleInventoryFlowScreen.primary,
                softColor: SimpleInventoryFlowScreen.primarySoft,
                onTap: onSell,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PurchaseForm extends StatelessWidget {
  final List<_Supplier> suppliers;
  final List<String> products;
  final String? selectedSupplierId;
  final int supplierDropdownVersion;
  final String? selectedProduct;
  final String selectedProductUnit;
  final int productDropdownVersion;
  final ValueChanged<String?> onSupplierChanged;
  final ValueChanged<String?> onProductChanged;
  final TextEditingController invoiceNoController;
  final TextEditingController expiryDateController;
  final TextEditingController quantityController;
  final TextEditingController buyPriceController;
  final TextEditingController paidAmountController;
  final double purchaseTotal;
  final double purchaseDue;
  final VoidCallback onPickExpiryDate;
  final Future<void> Function() onSave;
  final bool isSaving;

  const _PurchaseForm({
    required this.suppliers,
    required this.products,
    required this.selectedSupplierId,
    required this.supplierDropdownVersion,
    required this.selectedProduct,
    required this.selectedProductUnit,
    required this.productDropdownVersion,
    required this.onSupplierChanged,
    required this.onProductChanged,
    required this.invoiceNoController,
    required this.expiryDateController,
    required this.quantityController,
    required this.buyPriceController,
    required this.paidAmountController,
    required this.purchaseTotal,
    required this.purchaseDue,
    required this.onPickExpiryDate,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('purchase'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const _FlowHeader(
          title: 'New Purchase',
          subtitle: 'Add stock from supplier bill.',
          color: SimpleInventoryFlowScreen.green,
          softColor: SimpleInventoryFlowScreen.greenSoft,
          icon: Icons.add_shopping_cart,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'supplier-dropdown-$supplierDropdownVersion-$selectedSupplierId',
          ),
          initialValue: selectedSupplierId,
          decoration: _fieldDecoration(
            label: 'Supplier / Agency',
            icon: Icons.local_shipping_outlined,
          ),
          items: [
            const DropdownMenuItem(
              value: _SimpleInventoryFlowScreenState._createSupplierValue,
              child: _CreateDropdownOption(
                label: '+ Create New Supplier',
                icon: Icons.add_business_outlined,
                color: SimpleInventoryFlowScreen.amber,
                softColor: SimpleInventoryFlowScreen.amberSoft,
              ),
            ),
            ...suppliers.map(
              (supplier) => DropdownMenuItem(
                value: supplier.id,
                child: Text(supplier.name),
              ),
            ),
          ],
          onChanged: onSupplierChanged,
        ),
        const SizedBox(height: 10),
        _SimpleField(
          controller: invoiceNoController,
          label: 'Invoice no',
          hint: 'Example: INV-1024',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'product-dropdown-$productDropdownVersion-$selectedProduct',
          ),
          initialValue: selectedProduct,
          decoration: _fieldDecoration(
            label: 'Product name',
            icon: Icons.inventory_2_outlined,
          ),
          items: [
            const DropdownMenuItem(
              value: _SimpleInventoryFlowScreenState._createProductValue,
              child: _CreateDropdownOption(
                label: '+ Create New Product',
                icon: Icons.add_box_outlined,
                color: SimpleInventoryFlowScreen.green,
                softColor: SimpleInventoryFlowScreen.greenSoft,
              ),
            ),
            ...products.map(
              (product) =>
                  DropdownMenuItem(value: product, child: Text(product)),
            ),
          ],
          onChanged: onProductChanged,
        ),
        const SizedBox(height: 10),
        _SimpleField(
          controller: expiryDateController,
          label: 'Expiry date',
          hint: 'Optional',
          icon: Icons.event_outlined,
          readOnly: true,
          onTap: onPickExpiryDate,
        ),
        const SizedBox(height: 10),
        _TwoColumnFields(
          left: _SimpleField(
            controller: quantityController,
            label: 'Quantity',
            hint: '10',
            icon: Icons.tag,
            suffixText: selectedProductUnit,
            keyboardType: TextInputType.number,
          ),
          right: _SimpleField(
            controller: buyPriceController,
            label: 'Buy price',
            hint: '450',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 10),
        _SimpleField(
          controller: paidAmountController,
          label: 'Paid amount',
          hint: 'Auto-filled from total, editable for partial pay',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        _AmountSummaryCard(
          total: purchaseTotal,
          due: purchaseDue,
          accent: SimpleInventoryFlowScreen.green,
          softColor: SimpleInventoryFlowScreen.greenSoft,
        ),
        const SizedBox(height: 16),
        const _PlainHelp(
          text:
              'Purchase adds stock. If paid amount is less than total, supplier due is created.',
        ),
        const SizedBox(height: 16),
        _SaveButton(
          label: isSaving ? 'Saving...' : 'Save Purchase',
          color: SimpleInventoryFlowScreen.green,
          onPressed: isSaving ? null : () => onSave(),
        ),
      ],
    );
  }
}

class _SellForm extends StatelessWidget {
  final List<String> products;
  final List<_Customer> customers;
  final String? selectedProduct;
  final String? selectedCustomerId;
  final int customerDropdownVersion;
  final VoidCallback onPickProduct;
  final ValueChanged<String?> onCustomerChanged;
  final TextEditingController quantityController;
  final TextEditingController sellPriceController;
  final TextEditingController paidAmountController;
  final double saleTotal;
  final double saleDue;
  final String paymentType;
  final ValueChanged<String> onPaymentChanged;
  final Future<void> Function() onSave;
  final bool isSaving;

  const _SellForm({
    required this.products,
    required this.customers,
    required this.selectedProduct,
    required this.selectedCustomerId,
    required this.customerDropdownVersion,
    required this.onPickProduct,
    required this.onCustomerChanged,
    required this.quantityController,
    required this.sellPriceController,
    required this.paidAmountController,
    required this.saleTotal,
    required this.saleDue,
    required this.paymentType,
    required this.onPaymentChanged,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('sell'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const _FlowHeader(
          title: 'New Sale',
          subtitle: 'Reduce stock and save payment.',
          color: SimpleInventoryFlowScreen.primary,
          softColor: SimpleInventoryFlowScreen.primarySoft,
          icon: Icons.point_of_sale,
        ),
        const SizedBox(height: 14),
        _SelectButtonField(
          label: 'Product name',
          value: selectedProduct,
          hint: products.isEmpty ? 'No product available' : 'Search product',
          icon: Icons.search,
          onTap: products.isEmpty ? null : onPickProduct,
        ),
        const SizedBox(height: 10),
        _TwoColumnFields(
          left: _SimpleField(
            controller: quantityController,
            label: 'Quantity',
            hint: '1',
            icon: Icons.tag,
            keyboardType: TextInputType.number,
          ),
          right: _SimpleField(
            controller: sellPriceController,
            label: 'Sell price',
            hint: '120',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'customer-dropdown-$customerDropdownVersion-$selectedCustomerId',
          ),
          initialValue: selectedCustomerId,
          decoration: _fieldDecoration(
            label: 'Customer',
            icon: Icons.person_outline,
          ),
          items: [
            const DropdownMenuItem(
              value: _SimpleInventoryFlowScreenState._createCustomerValue,
              child: _CreateDropdownOption(
                label: '+ Create New Customer',
                icon: Icons.person_add_alt_1_outlined,
                color: SimpleInventoryFlowScreen.primary,
                softColor: SimpleInventoryFlowScreen.primarySoft,
              ),
            ),
            ...customers.map(
              (customer) => DropdownMenuItem(
                value: customer.id,
                child: Text(
                  customer.mobile.isEmpty
                      ? customer.name
                      : '${customer.name} - ${customer.mobile}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onCustomerChanged,
        ),
        const SizedBox(height: 14),
        _PaymentChoices(selected: paymentType, onChanged: onPaymentChanged),
        const SizedBox(height: 10),
        _SimpleField(
          controller: paidAmountController,
          label: 'Paid amount',
          hint: 'Customer paying now',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _AmountSummaryCard(
          total: saleTotal,
          due: saleDue,
          accent: SimpleInventoryFlowScreen.primary,
          softColor: SimpleInventoryFlowScreen.primarySoft,
        ),
        const SizedBox(height: 16),
        const _PlainHelp(
          text:
              'Sell reduces stock. If paid amount is less than total, customer due is created.',
        ),
        const SizedBox(height: 16),
        _SaveButton(
          label: isSaving ? 'Saving...' : 'Save Sale',
          color: SimpleInventoryFlowScreen.primary,
          onPressed: isSaving ? null : () => onSave(),
        ),
      ],
    );
  }
}

class _SupplierListScreen extends StatelessWidget {
  final List<_Supplier> suppliers;
  final VoidCallback onCreate;
  final ValueChanged<_Supplier> onEdit;

  const _SupplierListScreen({
    required this.suppliers,
    required this.onCreate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('suppliers'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const _FlowHeader(
          title: 'Suppliers',
          subtitle: 'Create and update simple supplier details.',
          color: SimpleInventoryFlowScreen.amber,
          softColor: SimpleInventoryFlowScreen.amberSoft,
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 14),
        _SaveButton(
          label: '+ Create New Supplier',
          color: SimpleInventoryFlowScreen.amber,
          onPressed: onCreate,
        ),
        const SizedBox(height: 14),
        if (suppliers.isEmpty)
          const _PlainHelp(text: 'No suppliers created yet.')
        else
          for (final supplier in suppliers)
            _SupplierTile(supplier: supplier, onEdit: () => onEdit(supplier)),
      ],
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final _Supplier supplier;
  final VoidCallback onEdit;

  const _SupplierTile({required this.supplier, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SimpleInventoryFlowScreen.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SimpleInventoryFlowScreen.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: SimpleInventoryFlowScreen.amberSoft,
            foregroundColor: SimpleInventoryFlowScreen.amber,
            child: Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: SimpleInventoryFlowScreen.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  supplier.mobile.isEmpty
                      ? 'Mobile not added'
                      : supplier.mobile,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: SimpleInventoryFlowScreen.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _CreateDropdownOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color softColor;

  const _CreateDropdownOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;

  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.words,
      decoration: _fieldDecoration(label: label, hint: hint, icon: icon),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  String? hint,
  String? suffixText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffixText?.isEmpty ?? true ? null : suffixText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: SimpleInventoryFlowScreen.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SimpleInventoryFlowScreen.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SimpleInventoryFlowScreen.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: SimpleInventoryFlowScreen.primary,
        width: 1.4,
      ),
    ),
  );
}

class _WorkButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  const _WorkButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SimpleInventoryFlowScreen.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SimpleInventoryFlowScreen.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  color: SimpleInventoryFlowScreen.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: SimpleInventoryFlowScreen.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color softColor;
  final IconData icon;

  const _FlowHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SimpleInventoryFlowScreen.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: SimpleInventoryFlowScreen.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: SimpleInventoryFlowScreen.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? suffixText;
  final bool readOnly;
  final VoidCallback? onTap;

  const _SimpleField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.suffixText,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: TextCapitalization.words,
      decoration: _fieldDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixText: suffixText,
      ),
    );
  }
}

class _SelectButtonField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  const _SelectButtonField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _fieldDecoration(label: label, icon: icon),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: hasValue
                      ? SimpleInventoryFlowScreen.ink
                      : SimpleInventoryFlowScreen.muted,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: onTap == null
                  ? SimpleInventoryFlowScreen.muted.withValues(alpha: 0.45)
                  : SimpleInventoryFlowScreen.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _TwoColumnFields({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [left, const SizedBox(height: 10), right]);
        }
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _PaymentChoices extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentChoices({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in const ['Cash', 'UPI', 'Card', 'Credit'])
          ChoiceChip(
            selected: selected == value,
            label: Text(value),
            onSelected: (_) => onChanged(value),
            selectedColor: SimpleInventoryFlowScreen.primary,
            backgroundColor: SimpleInventoryFlowScreen.surface,
            side: const BorderSide(color: SimpleInventoryFlowScreen.border),
            labelStyle: TextStyle(
              color: selected == value
                  ? Colors.white
                  : SimpleInventoryFlowScreen.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _PlainHelp extends StatelessWidget {
  final String text;

  const _PlainHelp({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SimpleInventoryFlowScreen.amberSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SimpleInventoryFlowScreen.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: SimpleInventoryFlowScreen.amber,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: SimpleInventoryFlowScreen.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountSummaryCard extends StatelessWidget {
  final double total;
  final double due;
  final Color accent;
  final Color softColor;

  const _AmountSummaryCard({
    required this.total,
    required this.due,
    required this.accent,
    required this.softColor,
  });

  String _money(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SimpleInventoryFlowScreen.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AmountCell(
              label: 'Total amount',
              value: total > 0 ? 'Rs ${_money(total)}' : 'Rs 0',
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AmountCell(
              label: 'Due amount',
              value: due > 0 ? 'Rs ${_money(due)}' : 'No due',
              color: due > 0
                  ? SimpleInventoryFlowScreen.red
                  : SimpleInventoryFlowScreen.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: SimpleInventoryFlowScreen.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LoadFailedView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailedView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: SimpleInventoryFlowScreen.red,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: SimpleInventoryFlowScreen.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _SaveButton(
              label: 'Retry',
              color: SimpleInventoryFlowScreen.primary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _SaveButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label),
    );
  }
}
