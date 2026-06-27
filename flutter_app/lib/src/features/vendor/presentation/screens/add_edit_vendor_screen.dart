import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';

class AddEditVendorScreen extends ConsumerStatefulWidget {
  final String? vendorId;

  const AddEditVendorScreen({super.key, this.vendorId});

  @override
  ConsumerState<AddEditVendorScreen> createState() => _AddEditVendorScreenState();
}

class _AddEditVendorScreenState extends ConsumerState<AddEditVendorScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;
  bool _controllersSet = false;
  bool _isActive = true;

  bool get isEdit => widget.vendorId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _setControllersFromVendor(Vendor vendor) {
    if (_controllersSet) return;
    _nameController.text = vendor.name;
    _mobileController.text = vendor.mobile ?? '';
    _gstController.text = vendor.gstNumber ?? '';
    _emailController.text = vendor.email ?? '';
    _addressController.text = vendor.address ?? '';
    _isActive = vendor.isActive;
    _controllersSet = true;
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId!));
      vendorAsync.whenData((vendor) {
        if (mounted) _setControllersFromVendor(vendor);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Vendor' : 'Add Vendor'),
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
            _buildLogoArea(context),
            const SizedBox(height: 24),
            _buildLabel('Vendor Name', required: true),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Enter vendor name'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Mobile Number', required: true),
            const SizedBox(height: 6),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Enter mobile number'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('GST Number'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _gstController,
                        decoration: _inputDecoration('Enter GST number'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Email'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Enter email'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Address', required: true),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: _inputDecoration('Enter full address'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Status', required: true),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isActive = true),
                    child: _buildStatusChip('Active', _isActive),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isActive = false),
                    child: _buildStatusChip('Inactive', !_isActive),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                    : Text(isEdit ? 'Update Vendor' : 'Save Vendor'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoArea(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
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
                'Upload Vendor Logo',
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE3F2FD) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.check_circle,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
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
        const SnackBar(content: Text('Please enter vendor name')),
      );
      return;
    }

    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter mobile number')),
      );
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter address')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name': name,
      'mobile': mobile,
      'gstNumber': _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
      'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      'address': address,
      'status': _isActive ? 'ACTIVE' : 'INACTIVE',
    };

    if (isEdit) {
      await ref.read(vendorNotifierProvider.notifier).updateVendor(
            widget.vendorId!,
            data,
          );
    } else {
      await ref.read(vendorNotifierProvider.notifier).createVendor(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final notifierState = ref.read(vendorNotifierProvider);
    if (notifierState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notifierState.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ref.invalidate(vendorsProvider(
          VendorFilter(search: null, page: 1, limit: 20)));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Vendor updated' : 'Vendor created'),
        ),
      );
    }
  }
}
