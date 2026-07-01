import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_providers.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;
  bool _controllersSet = false;
  bool _isActive = true;

  bool get isEdit => widget.customerId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _setControllersFromCustomer(Customer customer) {
    if (_controllersSet) return;
    _nameController.text = customer.name;
    _mobileController.text = customer.mobile ?? '';
    _gstController.text = customer.gstNumber ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
    _isActive = customer.isActive;
    _controllersSet = true;
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      final customerAsync = ref.watch(customerDetailProvider(widget.customerId!));
      customerAsync.whenData((customer) {
        if (mounted) _setControllersFromCustomer(customer);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
            _buildAvatarArea(context),
            const SizedBox(height: 24),
            _buildLabel('Customer Name', required: true),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Enter customer name'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Mobile Number'),
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
                        decoration: _inputDecoration('Enter email address'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Address'),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: _inputDecoration('Enter complete address'),
            ),
            const SizedBox(height: 16),
            if (isEdit) ...[
              _buildLabel('Status'),
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
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Update Customer' : 'Save Customer'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarArea(BuildContext context) {
    final initials = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'C';
    return Center(
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: Text(
            initials,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
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
            Icon(Icons.check_circle, size: 16, color: AppColors.primary),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
        if (required)
          const Text(' *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name': name,
      'mobile': _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
      'gstNumber': _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
      'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      if (isEdit) 'status': _isActive ? 'ACTIVE' : 'INACTIVE',
    };

    if (isEdit) {
      await ref.read(customerNotifierProvider.notifier).updateCustomer(widget.customerId!, data);
    } else {
      await ref.read(customerNotifierProvider.notifier).createCustomer(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final notifierState = ref.read(customerNotifierProvider);
    if (notifierState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${notifierState.error}'), backgroundColor: AppColors.error),
      );
    } else {
      ref.invalidate(customersProvider(CustomerFilter()));
      if (isEdit) ref.invalidate(customerDetailProvider(widget.customerId!));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Customer updated' : 'Customer created')),
      );
    }
  }
}
