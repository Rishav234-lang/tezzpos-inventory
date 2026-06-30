import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../vendor/domain/entities/vendor.dart';
import '../providers/purchase_providers.dart';
import '../widgets/purchase_pickers.dart';

class PurchaseItemForm {
  String productId;
  String name;
  String? sku;
  String? imageUrl;
  int quantity;
  double purchasePrice;
  double mrp;
  DateTime? expiryDate;
  String unit;
  late final TextEditingController qtyController;
  late final TextEditingController priceController;
  late final TextEditingController mrpController;

  PurchaseItemForm({
    required this.productId,
    required this.name,
    this.sku,
    this.imageUrl,
    this.quantity = 1,
    this.purchasePrice = 0,
    this.mrp = 0,
    this.expiryDate,
    this.unit = 'PCS',
  }) {
    qtyController = TextEditingController(text: quantity.toString());
    priceController = TextEditingController(text: purchasePrice.toStringAsFixed(2));
    mrpController = TextEditingController(text: mrp.toStringAsFixed(2));
  }

  double get total => quantity * purchasePrice;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    mrpController.dispose();
  }

  void updateControllers() {
    qtyController.text = quantity.toString();
    priceController.text = purchasePrice.toStringAsFixed(2);
    mrpController.text = mrp.toStringAsFixed(2);
  }
}

class CreatePurchaseScreen extends ConsumerStatefulWidget {
  final String? purchaseId;
  final String? duplicatePurchaseId;

  const CreatePurchaseScreen({super.key, this.purchaseId, this.duplicatePurchaseId});

  @override
  ConsumerState<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  final _invoiceController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  Vendor? _selectedVendor;
  DateTime _purchaseDate = DateTime.now();
  final List<PurchaseItemForm> _items = [];
  String _paymentMethod = 'Cash';
  bool _isSaving = false;
  bool _isLoading = false;

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _currencyFormat = NumberFormat('#,##,##0.00');

  bool get _isEditing => widget.purchaseId != null;
  bool get _isDuplicating => widget.duplicatePurchaseId != null;
  String? get _loadId => widget.purchaseId ?? widget.duplicatePurchaseId;

  double get _totalAmount => _items.fold(0, (s, i) => s + i.total);
  int get _totalQuantity => _items.fold(0, (s, i) => s + i.quantity);
  int get _totalItems => _items.length;

  double get _paidAmount {
    final val = double.tryParse(_paidAmountController.text) ?? 0;
    return val;
  }

  double get _balanceAmount => _totalAmount - _paidAmount;

  String get _status {
    if (_paidAmount >= _totalAmount) return 'PAID';
    if (_paidAmount > 0) return 'PARTIAL';
    return 'UNPAID';
  }

  String get _statusLabel {
    switch (_status) {
      case 'PAID': return 'Paid';
      case 'PARTIAL': return 'Partial Paid';
      default: return 'Unpaid';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case 'PAID': return AppColors.success;
      case 'PARTIAL': return AppColors.warning;
      default: return AppColors.error;
    }
  }

  Color get _statusBg {
    switch (_status) {
      case 'PAID': return AppColors.successLight;
      case 'PARTIAL': return AppColors.warningLight;
      default: return AppColors.errorLight;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_loadId != null) {
      _loadPurchase();
    }
  }

  Future<void> _loadPurchase() async {
    setState(() => _isLoading = true);
    final repository = ref.read(purchaseRepositoryProvider);
    final result = await repository.getPurchaseById(_loadId!);
    result.fold(
      (failure) => _showError(failure.message),
      (purchase) {
        setState(() {
          if (purchase.vendor != null) {
            final v = purchase.vendor!;
            _selectedVendor = Vendor(
              id: v.id,
              name: v.name,
              mobile: v.mobile,
              gstNumber: v.gstNumber,
              email: v.email,
              address: v.address,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          if (_isDuplicating) {
            _invoiceController.text = '${purchase.invoiceNumber}-COPY';
            _paidAmountController.text = '0';
          } else {
            _invoiceController.text = purchase.invoiceNumber;
            _paidAmountController.text = purchase.paidAmount.toStringAsFixed(2);
          }
          _purchaseDate = DateTime.now();
          _notesController.text = purchase.notes ?? '';
          for (final item in purchase.items) {
            _items.add(PurchaseItemForm(
              productId: item.productId,
              name: item.productName,
              sku: item.sku,
              quantity: item.quantity,
              purchasePrice: item.purchasePrice,
              mrp: item.mrp,
              expiryDate: item.expiryDate,
            ));
          }
        });
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _paidAmountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required void Function(DateTime) onPicked}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onPicked(picked);
  }

  void _showVendorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => VendorPicker(
        onSelected: (vendor) {
          setState(() => _selectedVendor = vendor);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ProductPicker(
        onSelected: (product) {
          setState(() {
            _items.add(PurchaseItemForm(
              productId: product.id,
              name: product.name,
              sku: product.sku,
              imageUrl: product.imageUrl,
              unit: product.unit,
              purchasePrice: product.costPrice,
              mrp: product.sellingPrice,
            ));
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (_selectedVendor == null) {
      _showError('Please select a vendor');
      return;
    }
    if (_invoiceController.text.trim().isEmpty) {
      _showError('Please enter invoice number');
      return;
    }
    if (_items.isEmpty) {
      _showError('Please add at least one product');
      return;
    }
    for (final item in _items) {
      if (item.quantity <= 0) {
        _showError('Quantity must be greater than 0 for ${item.name}');
        return;
      }
      if (item.purchasePrice <= 0) {
        _showError('Purchase price must be greater than 0 for ${item.name}');
        return;
      }
      if (item.mrp <= 0) {
        _showError('MRP must be greater than 0 for ${item.name}');
        return;
      }
    }

    setState(() => _isSaving = true);

    final data = {
      'vendorId': _selectedVendor!.id,
      'invoiceNumber': _invoiceController.text.trim(),
      'purchaseDate': _purchaseDate.toIso8601String(),
      'paidAmount': _paidAmount,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      'items': _items.map((i) => {
        'productId': i.productId,
        'quantity': i.quantity,
        'purchasePrice': i.purchasePrice,
        'mrp': i.mrp,
        'expiryDate': i.expiryDate?.toIso8601String(),
      }).toList(),
    };

    final notifier = ref.read(purchaseNotifierProvider.notifier);
    if (_isEditing) {
      await notifier.updatePurchase(widget.purchaseId!, data);
    } else {
      await notifier.createPurchase(data);
    }

    if (!mounted) return;

    final state = ref.read(purchaseNotifierProvider);
    state.whenOrNull(
      data: (_) {
        final msg = _isEditing
            ? 'Purchase updated successfully'
            : _isDuplicating
                ? 'Purchase duplicated successfully'
                : 'Purchase created successfully';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        context.pop();
      },
      error: (err, _) => _showError(err.toString()),
    );

    setState(() => _isSaving = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            _isEditing ? 'Edit Purchase' : 'Create Purchase',
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          _isEditing
              ? 'Edit Purchase'
              : _isDuplicating
                  ? 'Duplicate Purchase'
                  : 'Create Purchase',
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.description_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1', 'Purchase Info'),
            _buildPurchaseInfo(),
            const SizedBox(height: 24),
            _buildSectionHeader('2', 'Products'),
            _buildProductsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('3', 'Payment Details'),
            _buildPaymentSection(),
            const SizedBox(height: 24),
            _buildNotes(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildSectionHeader(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 300;
          return isWide ? _buildWidePurchaseInfo() : _buildNarrowPurchaseInfo();
        },
      ),
    );
  }

  Widget _buildWidePurchaseInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Vendor', required: true),
              const SizedBox(height: 6),
              _buildVendorPickerField(),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Invoice No.', required: true),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _invoiceController,
                hint: 'INV-00125',
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Purchase Date', required: true),
              const SizedBox(height: 6),
              _buildDatePickerField(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowPurchaseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Vendor', required: true),
                  const SizedBox(height: 6),
                  _buildVendorPickerField(),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Invoice No.', required: true),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _invoiceController,
                    hint: 'INV-00125',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Purchase Date', required: true),
            const SizedBox(height: 6),
            _buildDatePickerField(),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorPickerField() {
    return InkWell(
      onTap: _showVendorPicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedVendor?.name ?? 'Select Vendor',
                style: TextStyle(
                  color: _selectedVendor != null ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () => _pickDate(context, onPicked: (d) => setState(() => _purchaseDate = d)),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              _dateFormat.format(_purchaseDate),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showProductPicker,
            icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
            label: const Text('Add Product', style: TextStyle(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 4),
        ..._items.asMap().entries.map((entry) {
          return _buildProductCard(entry.key, entry.value);
        }),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSummaryRow(),
        ],
      ],
    );
  }

  Widget _buildProductCard(int index, PurchaseItemForm item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          errorBuilder: (_, _, _) => _productPlaceholder(),
                        ),
                      )
                    : _productPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (item.sku != null && item.sku!.isNotEmpty)
                      Text(
                        'SKU: ${item.sku}',
                        style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _items[index].dispose();
                  _items.removeAt(index);
                }),
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: _buildSmallField(
                  label: 'Qty',
                  required: true,
                  controller: item.qtyController,
                  suffix: Text(item.unit, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  onChanged: (v) {
                    final val = int.tryParse(v) ?? 0;
                    if (val > 0) setState(() => item.quantity = val);
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallField(
                  label: 'Purchase Price',
                  required: true,
                  controller: item.priceController,
                  prefix: const Text('₹ ', style: TextStyle(fontSize: 13)),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? 0;
                    if (val >= 0) setState(() => item.purchasePrice = val);
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallField(
                  label: 'MRP',
                  controller: item.mrpController,
                  prefix: const Text('₹ ', style: TextStyle(fontSize: 13)),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? 0;
                    if (val >= 0) setState(() => item.mrp = val);
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Expiry Date'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _pickDate(context, onPicked: (d) => setState(() => item.expiryDate = d)),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              item.expiryDate != null ? _dateFormat.format(item.expiryDate!) : 'Select',
                              style: TextStyle(
                                fontSize: 13,
                                color: item.expiryDate != null ? AppColors.onSurface : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ₹ ${_currencyFormat.format(item.total)}',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return const Center(
      child: Icon(Icons.image, color: AppColors.onSurfaceVariant, size: 20),
    );
  }

  Widget _buildSummaryRow() {
    final totalSavings = _items.fold(0.0, (s, i) => s + (i.mrp - i.purchasePrice) * i.quantity);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            label: 'Total Items',
            value: _totalItems.toString(),
            subValue: null,
            icon: Icons.layers_outlined,
            iconColor: AppColors.info,
            bgColor: const Color(0xFFEEF2FF),
          ),
          _buildSummaryItem(
            label: 'Total Quantity',
            value: '$_totalQuantity',
            subValue: _totalItems > 0 ? _items.first.unit.toLowerCase() : 'pcs',
            icon: Icons.format_list_numbered,
            iconColor: AppColors.success,
            bgColor: const Color(0xFFD1FAE5),
          ),
          _buildSummaryItem(
            label: 'Total Amount',
            value: '₹ ${_currencyFormat.format(_totalAmount)}',
            subValue: null,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.primary,
            bgColor: const Color(0xFFDBEAFE),
          ),
          _buildSummaryItem(
            label: 'Total Savings',
            value: '₹ ${_currencyFormat.format(totalSavings)}',
            subValue: null,
            icon: Icons.savings_outlined,
            iconColor: AppColors.success,
            bgColor: const Color(0xFFD1FAE5),
            showInfo: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    bool showInfo = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subValue != null)
            Text(
              subValue,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              if (showInfo) ...[
                const SizedBox(width: 2),
                Icon(Icons.info_outline, size: 12, color: AppColors.onSurfaceVariant),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSmallField(
                  label: 'Paid Amount',
                  controller: _paidAmountController,
                  prefix: const Text('₹ ', style: TextStyle(fontSize: 13)),
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Payment Method'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentMethod,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          items: ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Card']
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Row(
                                      children: [
                                        Icon(
                                          m == 'Cash' ? Icons.account_balance_wallet_outlined : Icons.payment_outlined,
                                          size: 16,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(m, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallField(
                  label: 'Reference No. (Optional)',
                  controller: _referenceController,
                  hint: 'Enter refer...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaymentInfoCard(
                  label: 'Balance Amount',
                  value: '₹ ${_currencyFormat.format(_balanceAmount)}',
                  valueColor: _balanceAmount > 0 ? AppColors.error : AppColors.success,
                  showBg: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPaymentInfoCard(
                  label: 'Status',
                  value: _statusLabel,
                  valueColor: _statusColor,
                  valueBg: _statusBg,
                  isPill: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPaymentInfoCard(
                  label: 'Payment Due',
                  value: '₹ ${_currencyFormat.format(_balanceAmount)}',
                  valueColor: _balanceAmount > 0 ? AppColors.primary : AppColors.success,
                  showBg: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard({
    required String label,
    required String value,
    required Color valueColor,
    Color? valueBg,
    bool showBg = true,
    bool isPill = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPill
            ? (valueBg ?? AppColors.surfaceVariant.withValues(alpha: 0.5))
            : (showBg ? (valueBg ?? AppColors.surfaceVariant.withValues(alpha: 0.5)) : Colors.transparent),
        borderRadius: BorderRadius.circular(isPill ? 20 : 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Notes (Optional)'),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Enter any notes here...',
            hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.surface,
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
            contentPadding: const EdgeInsets.all(14),
            counterStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePurchase,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : (_isEditing
                      ? 'Update Purchase'
                      : _isDuplicating
                          ? 'Save Duplicate'
                          : 'Save Purchase'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
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
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        children: [
          TextSpan(text: label),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    Widget? prefix,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
        prefixIcon: prefix != null
            ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix)
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }

  Widget _buildSmallField({
    required String label,
    bool required = false,
    required TextEditingController controller,
    String? hint,
    Widget? prefix,
    Widget? suffix,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            prefixIcon: prefix != null
                ? Padding(padding: const EdgeInsets.only(left: 8), child: prefix)
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix != null
                ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
