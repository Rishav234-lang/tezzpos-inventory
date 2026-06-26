import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/category_providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const AddEditCategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _status = 'ACTIVE';
  bool _isLoading = false;
  bool _controllersInitialized = false;

  bool get isEdit => widget.categoryId != null && widget.categoryId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      // Schedule loading after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategory());
    }
  }

  void _loadCategory() {
    final categoryAsync = ref.read(categoryDetailProvider(widget.categoryId!));
    categoryAsync.whenData((cat) {
      if (!_controllersInitialized && mounted) {
        setState(() {
          _nameController.text = cat.name;
          _descriptionController.text = cat.description ?? '';
          _imageUrlController.text = cat.imageUrl ?? '';
          _status = cat.status;
          _controllersInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(isEdit ? 'Edit Category' : 'Add Category'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image upload placeholder
                  Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                              image: _imageUrlController.text.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_imageUrlController.text),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageUrlController.text.isEmpty
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
                                          Icons.image,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Upload Category Image',
                                        style: context.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG up to 2MB',
                                        style: context.textTheme.labelSmall?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          if (_imageUrlController.text.isNotEmpty)
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
                  ),
                  const SizedBox(height: 24),
                  // Name
                  _buildLabel('Category Name', required: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Enter category name'),
                  ),
                  const SizedBox(height: 20),
                  // Description
                  _buildLabel('Description'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: _inputDecoration('Enter description (optional)'),
                  ),
                  const SizedBox(height: 20),
                  // Status
                  _buildLabel('Status', required: true),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusChip(
                        label: 'Active',
                        isSelected: _status == 'ACTIVE',
                        onTap: () => setState(() => _status = 'ACTIVE'),
                      ),
                      const SizedBox(width: 12),
                      _StatusChip(
                        label: 'Inactive',
                        isSelected: _status == 'INACTIVE',
                        onTap: () => setState(() => _status = 'INACTIVE'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Update Category' : 'Save Category',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
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
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (isEdit) {
      await ref.read(categoryNotifierProvider.notifier).updateCategory(
        id: widget.categoryId!,
        name: name,
        description: description.isNotEmpty ? description : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        status: _status,
      );
    } else {
      await ref.read(categoryNotifierProvider.notifier).createCategory(
        name: name,
        description: description.isNotEmpty ? description : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        status: _status,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    final notifierState = ref.read(categoryNotifierProvider);
    if (notifierState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${notifierState.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Category updated' : 'Category created')),
      );
      context.pop();
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 16),
            if (isSelected) const SizedBox(width: 6),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
