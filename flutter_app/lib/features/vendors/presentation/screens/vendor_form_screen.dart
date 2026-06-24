import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  const VendorFormScreen({super.key, this.vendorId});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.vendorId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadVendor();
  }

  Future<void> _loadVendor() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.vendors}/${widget.vendorId}');
    final vendor = response.data;
    _nameController.text = vendor['name'] ?? '';
    _mobileController.text = vendor['mobile'] ?? '';
    _gstController.text = vendor['gstNumber'] ?? '';
    _emailController.text = vendor['email'] ?? '';
    _addressController.text = vendor['address'] ?? '';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        'gstNumber': _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      };

      if (_isEditing) {
        await api.put('${ApiConstants.vendors}/${widget.vendorId}', data: data);
      } else {
        await api.post(ApiConstants.vendors, data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor ${_isEditing ? 'updated' : 'created'} successfully')),
        );
        context.go('/vendors');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Vendor' : 'Add Vendor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Vendor Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gstController,
                  decoration: const InputDecoration(labelText: 'GST Number'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(_isEditing ? 'Update Vendor' : 'Create Vendor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
