import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/super_admin_providers.dart';

class AddEditCompanyScreen extends ConsumerStatefulWidget {
  final String? companyId;

  const AddEditCompanyScreen({super.key, this.companyId});

  @override
  ConsumerState<AddEditCompanyScreen> createState() => _AddEditCompanyScreenState();
}

class _AddEditCompanyScreenState extends ConsumerState<AddEditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.companyId != null;
    if (_isEdit) _loadCompany();
  }

  Future<void> _loadCompany() async {
    setState(() => _isLoading = true);
    final repository = ref.read(superAdminRepositoryProvider);
    final result = await repository.getCompanyById(widget.companyId!);
    result.fold(
      (failure) {},
      (company) {
        setState(() {
          _nameController.text = company.name;
          _emailController.text = company.email;
          _phoneController.text = company.phone ?? '';
          _addressController.text = company.address ?? '';
          _gstController.text = company.gstNumber ?? '';
          if (company.owner != null) {
            _ownerNameController.text = company.owner!.name;
            _ownerEmailController.text = company.owner!.email;
          }
        });
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isEdit) {
      final company = await ref.read(superAdminNotifierProvider.notifier).updateCompany(
        widget.companyId!,
        {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'gstNumber': _gstController.text.trim(),
          if (_ownerNameController.text.trim().isNotEmpty) 'ownerName': _ownerNameController.text.trim(),
          if (_ownerEmailController.text.trim().isNotEmpty) 'ownerEmail': _ownerEmailController.text.trim(),
        },
      );
      setState(() => _isLoading = false);
      if (company != null && mounted) {
        ref.invalidate(companiesProvider(const CompanyFilter()));
        context.pop();
      }
    } else {
      final company = await ref.read(superAdminNotifierProvider.notifier).createCompany(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
        ownerName: _ownerNameController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim(),
        ownerPassword: _ownerPasswordController.text,
      );
      setState(() => _isLoading = false);
      if (company != null && mounted) {
        ref.invalidate(companiesProvider(const CompanyFilter()));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(superAdminNotifierProvider).isLoading || _isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: Text(_isEdit ? 'Edit Company' : 'Add Company'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Company Details'),
                      const SizedBox(height: 12),
                      _buildTextField('Company Name', _nameController, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                      _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress, validator: (v) => v?.contains('@') == true ? null : 'Valid email required'),
                      _buildTextField('Phone', _phoneController, keyboardType: TextInputType.phone, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                      _buildTextField('Address', _addressController, maxLines: 2),
                      _buildTextField('GST Number', _gstController),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Owner Details'),
                      const SizedBox(height: 12),
                      _buildTextField('Owner Name', _ownerNameController, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                      _buildTextField('Owner Email', _ownerEmailController, keyboardType: TextInputType.emailAddress, validator: (v) => v?.contains('@') == true ? null : 'Valid email required'),
                      if (!_isEdit)
                        _buildTextField('Owner Password', _ownerPasswordController, obscureText: true, validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters'),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_isEdit ? 'Update Company' : 'Create Company'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
