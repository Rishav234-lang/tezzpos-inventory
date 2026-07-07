import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/category_providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const AddEditCategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _imageUrl = '';
  File? _pickedImageFile;
  String _status = 'ACTIVE';
  bool _isSaving = false;
  bool _controllersSet = false;

  bool get isEdit => widget.categoryId != null && widget.categoryId!.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _setControllersFromCategory(dynamic cat) {
    if (_controllersSet) return;
    _nameController.text = cat.name;
    _descriptionController.text = cat.description ?? '';
    _imageUrl = cat.imageUrl ?? '';
    _pickedImageFile = null;
    _status = cat.status;
    _controllersSet = true;
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      final categoryAsync = ref.watch(
        categoryDetailProvider(widget.categoryId!),
      );
      categoryAsync.whenData(_setControllersFromCategory);
    }

    final isLoading = _isSaving || (isEdit && !_controllersSet);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(isEdit ? 'Edit Category' : 'Create Category'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageArea(context),
                  const SizedBox(height: 24),
                  _buildSimpleHeader(
                    icon: Icons.category_outlined,
                    title: 'Category Details',
                    subtitle:
                        'Use a clear group name like Grocery, Medicine or Snacks.',
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Category Name', required: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Enter category name'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Note'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: _inputDecoration('Optional'),
                  ),
                  const SizedBox(height: 20),
                  if (isEdit) ...[
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
                  ] else
                    const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Category' : 'Create Category',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
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
              width: 140,
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
                        fit: BoxFit.cover,
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
                            Icons.image,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Category Photo',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Optional',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
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

  Widget _buildSimpleHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      hintStyle: TextStyle(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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

    setState(() => _isSaving = true);

    String? imagePath;
    if (_pickedImageFile != null) {
      imagePath = await ref
          .read(categoryNotifierProvider.notifier)
          .uploadCategoryImage(_pickedImageFile!);
      if (imagePath == null) {
        if (!mounted) return;
        final notifierState = ref.read(categoryNotifierProvider);
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

    if (isEdit) {
      await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(
            id: widget.categoryId!,
            name: name,
            description: description.isNotEmpty ? description : null,
            imageUrl: imagePath,
            status: _status,
          );
    } else {
      await ref
          .read(categoryNotifierProvider.notifier)
          .createCategory(
            name: name,
            description: description.isNotEmpty ? description : null,
            imageUrl: imagePath,
            status: _status,
          );
    }

    if (!mounted) return;

    final notifierState = ref.read(categoryNotifierProvider);
    if (notifierState.hasError) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notifierState.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ref.invalidate(categoriesProvider(''));
      if (isEdit) ref.invalidate(categoryDetailProvider(widget.categoryId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Category updated' : 'Category created'),
        ),
      );
      context.pop();
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.3),
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
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
