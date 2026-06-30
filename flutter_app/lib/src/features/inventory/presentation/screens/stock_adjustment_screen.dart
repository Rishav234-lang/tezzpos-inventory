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
  ConsumerState<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _adjustmentType = 'ADD';
  final _qtyController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedReason;
  bool _isSaving = false;

  final _addReasons = ['Purchase', 'Return from Customer', 'Damaged Stock Recovery', 'Stock Take', 'Other'];
  final _reduceReasons = ['Sale', 'Damaged / Expired', 'Loss / Theft', 'Stock Take', 'Other'];
  final _setReasons = ['Stock Take', 'Manual Correction', 'Opening Stock', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _selectedReason = null;
        _qtyController.clear();
        switch (_tabController.index) {
          case 0:
            _adjustmentType = 'ADD';
          case 1:
            _adjustmentType = 'REDUCE';
          case 2:
            _adjustmentType = 'SET';
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qtyController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _currentReasons {
    switch (_adjustmentType) {
      case 'ADD':
        return _addReasons;
      case 'REDUCE':
        return _reduceReasons;
      default:
        return _setReasons;
    }
  }

  int get _qty => int.tryParse(_qtyController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = widget.productId != null
        ? ref.watch(productDetailProvider(widget.productId!))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Stock Adjustment'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Add Stock'),
            Tab(text: 'Reduce Stock'),
            Tab(text: 'Set Stock'),
          ],
        ),
      ),
      body: productAsync == null
          ? _buildProductSearchView(context)
          : productAsync.when(
              data: (product) => _buildForm(context, product),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
      bottomNavigationBar: productAsync?.when(
              data: (product) => Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _submit(product),
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving...' : (_adjustmentType == 'ADD' ? 'Add Stock' : _adjustmentType == 'REDUCE' ? 'Reduce Stock' : 'Set Stock'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ),
              loading: () => null,
              error: (_, _) => null,
            ),
    );
  }

  Widget _buildProductSearchView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a product', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Please go to Inventory Detail and tap Stock Adjustment',
              style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, Product product) {
    final currentStock = product.totalStock;
    final adjustedQty = _qty;
    int newStock;
    switch (_adjustmentType) {
      case 'ADD':
        newStock = currentStock + adjustedQty;
      case 'REDUCE':
        newStock = (currentStock - adjustedQty).clamp(0, 999999);
      default:
        newStock = adjustedQty;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product card
          _buildProductCard(context, product),
          const SizedBox(height: 16),

          // Adjustment type (only for tab 0 = add)
          if (_adjustmentType != 'SET') ...[
            _label(context, 'Adjustment Type', required: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Add Stock',
                    icon: Icons.trending_up,
                    color: const Color(0xFF388E3C),
                    selected: _adjustmentType == 'ADD',
                    onTap: () => setState(() {
                      _adjustmentType = 'ADD';
                      _tabController.animateTo(0);
                      _selectedReason = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Reduce Stock',
                    icon: Icons.trending_down,
                    color: const Color(0xFFD32F2F),
                    selected: _adjustmentType == 'REDUCE',
                    onTap: () => setState(() {
                      _adjustmentType = 'REDUCE';
                      _tabController.animateTo(1);
                      _selectedReason = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Quantity
          _label(context, 'Quantity', required: true),
          const SizedBox(height: 8),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: _inputDec('Enter quantity', suffix: product.unit),
          ),
          const SizedBox(height: 16),

          // Reason
          _label(context, 'Reason', required: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedReason,
            decoration: _inputDec('Select reason'),
            items: _currentReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _selectedReason = v),
          ),
          const SizedBox(height: 16),

          // Reference
          _label(context, 'Reference (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceController,
            decoration: _inputDec('Enter reference / document no.'),
          ),
          const SizedBox(height: 16),

          // Notes
          _label(context, 'Notes (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: _inputDec('Enter notes'),
          ),
          const SizedBox(height: 20),

          // New stock preview
          _buildNewStockPreview(context, currentStock, adjustedQty, newStock),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        product.imageUrl!.startsWith('http')
                            ? product.imageUrl!
                            : '${ApiConstants.baseUrl}${product.imageUrl!}',
                      ),
                      fit: BoxFit.contain,
                      onError: (_, _) {},
                    )
                  : null,
            ),
            child: product.imageUrl == null || product.imageUrl!.isEmpty
                ? const Icon(Icons.inventory_2_outlined, color: AppColors.onSurfaceVariant, size: 22)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('SKU: ${product.sku ?? 'N/A'}  •  In Stock: ${product.totalStock} pcs',
                    style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Current Stock', style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
              Text('${product.totalStock} pcs',
                  style: context.textTheme.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewStockPreview(BuildContext context, int current, int adjustment, int newStock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Stock (After Adjustment)',
              style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF795548))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PreviewItem(value: '$current pcs', label: 'Current Stock'),
              Text(_adjustmentType == 'REDUCE' ? '−' : (_adjustmentType == 'SET' ? '=' : '+'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
              _PreviewItem(value: '$adjustment pcs', label: 'Adjustment'),
              const Text('=', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
              _PreviewItem(value: '$newStock pcs', label: 'New Stock', isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface),
        children: required
            ? [const TextSpan(text: ' *', style: TextStyle(color: AppColors.error))]
            : [],
      ),
    );
  }

  InputDecoration _inputDec(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5))),
    );
  }

  Future<void> _submit(Product product) async {
    if (_qtyController.text.trim().isEmpty || _qty <= 0) {
      _showSnack('Please enter a valid quantity');
      return;
    }
    if (_selectedReason == null) {
      _showSnack('Please select a reason');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider).dio;
      await dio.post(ApiConstants.inventoryAdjust, data: {
        'productId': product.id,
        'adjustmentType': _adjustmentType == 'ADD' ? 'INCREASE' : 'DECREASE',
        'quantity': _qty,
        'reason': _selectedReason,
      });

      if (!mounted) return;
      ref.invalidate(productDetailProvider(product.id));
      ref.invalidate(inventoryStatsProvider);
      _showSnack('Stock adjusted successfully');
      context.pop();
    } catch (e) {
      _showSnack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.outline.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isHighlight;

  const _PreviewItem({required this.value, required this.label, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary : AppColors.onSurface,
            fontSize: isHighlight ? 16 : 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
      ],
    );
  }
}
