import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_providers.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _minStockController = TextEditingController(text: '10');
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String _unit = 'PCS';
  double _gstRate = 0;
  String _status = 'ACTIVE';
  String _imageUrl = '';
  File? _pickedImageFile;
  bool _isSaving = false;
  bool _controllersSet = false;

  bool get isEdit => widget.productId != null;

  final List<String> _units = ['PCS', 'KG', 'LTR', 'BOX', 'PACK', 'BOTTLE', 'DOZEN'];
  final List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _hsnCodeController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _setControllersFromProduct(Product product) {
    if (_controllersSet) return;
    _nameController.text = product.name;
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _costPriceController.text = product.costPrice.toStringAsFixed(2);
    _sellingPriceController.text = product.sellingPrice.toStringAsFixed(2);
    _hsnCodeController.text = product.hsnCode ?? '';
    _minStockController.text = product.minStockLevel.toString();
    _descriptionController.text = product.description ?? '';
    _selectedCategoryId = product.categoryId;
    _unit = product.unit;
    _gstRate = product.gstRate;
    _status = product.status;
    _imageUrl = product.imageUrl ?? '';
    _pickedImageFile = null;
    _controllersSet = true;
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      final productAsync = ref.watch(productDetailProvider(widget.productId!));
      productAsync.whenData((product) {
        if (mounted) _setControllersFromProduct(product);
      });
    }

    final categoriesAsync = ref.watch(categoriesProvider(''));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageArea(context),
            const SizedBox(height: 20),
            _buildLabel('Product Name', required: true),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Enter product name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('SKU / Barcode', required: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _skuController,
                        decoration: _inputDecoration('Enter SKU'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Barcode', required: false),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _barcodeController,
                        decoration: _inputDecoration('Scan or enter').copyWith(
                          suffixIcon: Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.primary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category', required: true),
                      const SizedBox(height: 6),
                      _buildCategoryDropdown(categoriesAsync),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Unit', required: true),
                      const SizedBox(height: 6),
                      _buildUnitDropdown(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Cost Price (₹)', required: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _costPriceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Selling Price (₹)', required: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0.00'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('HSN Code', required: false),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _hsnCodeController,
                        decoration: _inputDecoration('Enter HSN code'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tax (GST)', required: true),
                      const SizedBox(height: 6),
                      _buildGstDropdown(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Minimum Stock Level', required: false),
            const SizedBox(height: 6),
            TextField(
              controller: _minStockController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Enter minimum stock level'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Description', required: false),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              decoration: _inputDecoration('Enter description'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Status', required: true),
            const SizedBox(height: 6),
            _buildStatusToggle(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEdit ? 'Update Product' : 'Save Product'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    final hasPickedFile = _pickedImageFile != null;
    final hasImageUrl = _imageUrl.isNotEmpty;
    final hasImage = hasPickedFile || hasImageUrl;

    ImageProvider? imageProvider;
    if (hasPickedFile) {
      imageProvider = FileImage(_pickedImageFile!);
    } else if (hasImageUrl) {
      final url = _imageUrl.startsWith('http')
          ? _imageUrl
          : '${ApiConstants.baseUrl}$_imageUrl';
      imageProvider = NetworkImage(url);
    }

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
                image: imageProvider != null
                    ? DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.contain,
                        onError: (exception, stackTrace) {},
                      )
                    : null,
              ),
              child: !hasImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Upload Product Image',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG up to 2MB',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            if (hasImage)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path);
        _imageUrl = '';
      });
    }
  }

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              isExpanded: true,
              hint: const Text('Select category'),
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Text('Failed to load categories'),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unit,
          isExpanded: true,
          items: _units.map((u) {
            return DropdownMenuItem(value: u, child: Text(u));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _unit = value);
          },
        ),
      ),
    );
  }

  Widget _buildGstDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _gstRate,
          isExpanded: true,
          items: _gstRates.map((r) {
            return DropdownMenuItem(
              value: r,
              child: Text('${r.toStringAsFixed(0)}% GST'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _gstRate = value);
          },
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Active'),
            selected: _status == 'ACTIVE',
            onSelected: (_) => setState(() => _status = 'ACTIVE'),
            selectedColor: AppColors.successLight,
            labelStyle: TextStyle(
              color: _status == 'ACTIVE' ? AppColors.success : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Inactive'),
            selected: _status == 'INACTIVE',
            onSelected: (_) => setState(() => _status = 'INACTIVE'),
            selectedColor: AppColors.errorLight,
            labelStyle: TextStyle(
              color: _status == 'INACTIVE' ? AppColors.error : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name')),
      );
      return;
    }

    final sku = _skuController.text.trim();
    if (sku.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter SKU / Barcode')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final costPriceText = _costPriceController.text.trim();
    final sellingPriceText = _sellingPriceController.text.trim();
    if (costPriceText.isEmpty || sellingPriceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter cost and selling price')),
      );
      return;
    }

    final costPrice = double.tryParse(costPriceText);
    final sellingPrice = double.tryParse(sellingPriceText);
    if (costPrice == null || sellingPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid prices')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? imagePath;
    if (_pickedImageFile != null) {
      imagePath = await ref
          .read(productNotifierProvider.notifier)
          .uploadProductImage(_pickedImageFile!);
      if (imagePath == null) {
        if (!mounted) return;
        final notifierState = ref.read(productNotifierProvider);
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: ${notifierState.error}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else if (_imageUrl.isNotEmpty) {
      imagePath = _imageUrl;
    }

    if (!mounted) return;

    final description = _descriptionController.text.trim();
    final barcode = _barcodeController.text.trim();
    final hsnCode = _hsnCodeController.text.trim();
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 10;

    final data = {
      'name': name,
      'sku': sku,
      'barcode': barcode.isNotEmpty ? barcode : null,
      'categoryId': _selectedCategoryId,
      'imageUrl': imagePath,
      'unit': _unit,
      'hsnCode': hsnCode.isNotEmpty ? hsnCode : null,
      'gstRate': _gstRate,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'minStockLevel': minStock,
      'description': description.isNotEmpty ? description : null,
      'status': _status,
    };

    if (isEdit) {
      await ref
          .read(productNotifierProvider.notifier)
          .updateProduct(widget.productId!, data);
    } else {
      await ref.read(productNotifierProvider.notifier).createProduct(data);
    }

    if (!mounted) return;

    final notifierState = ref.read(productNotifierProvider);
    if (notifierState.hasError) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notifierState.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ref.invalidate(productsProvider(
          ProductFilter(search: null, page: 1, limit: 20)));
      if (isEdit) {
        ref.invalidate(productDetailProvider(widget.productId!));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Product updated' : 'Product created'),
        ),
      );
      context.pop();
    }
  }
}
