import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const CustomerFormScreen({super.key, this.customerId});
  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool get _isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.customers}/${widget.customerId}');
    final c = response.data;
    _nameController.text = c['name'] ?? '';
    _mobileController.text = c['mobile'] ?? '';
    _emailController.text = c['email'] ?? '';
    _addressController.text = c['address'] ?? '';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      };
      if (_isEditing) {
        await api.put('${ApiConstants.customers}/${widget.customerId}', data: data);
      } else {
        await api.post(ApiConstants.customers, data: data);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer ${_isEditing ? 'updated' : 'created'}'))); context.go('/customers'); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Customer' : 'Add Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile'), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading ? null : _handleSubmit, child: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : Text(_isEditing ? 'Update Customer' : 'Create Customer')),
            ]),
          ),
        ),
      ),
    );
  }
}
