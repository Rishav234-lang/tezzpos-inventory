import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_providers.dart';

class ReceivePaymentScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const ReceivePaymentScreen({super.key, this.customerId});

  @override
  ConsumerState<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'UPI';
  Customer? _selectedCustomer;
  bool _isSaving = false;
  bool _controllersSet = false;

  final _paymentMethods = ['CASH', 'UPI', 'CARD', 'BANK_TRANSFER'];

  bool get hasPreselectedCustomer => widget.customerId != null;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setCustomer(Customer customer) {
    if (_controllersSet) return;
    _selectedCustomer = customer;
    _controllersSet = true;
  }

  @override
  Widget build(BuildContext context) {
    if (hasPreselectedCustomer) {
      final customerAsync = ref.watch(customerDetailProvider(widget.customerId!));
      customerAsync.whenData((customer) {
        if (mounted) _setCustomer(customer);
      });
    }

    final currency = NumberFormat('#,##,##0.00');
    final pendingAmount = _selectedCustomer?.outstandingBalance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Receive Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSelector(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending Amount', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '₹ ${currency.format(pendingAmount)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: pendingAmount > 0 ? AppColors.error : const Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Payment Amount *'),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Enter payment amount'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Payment Method *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: _inputDecoration('Select payment method'),
              items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 16),
            _buildLabel('Reference Number'),
            const SizedBox(height: 6),
            TextField(
              controller: _referenceController,
              decoration: _inputDecoration('Enter reference number'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Payment Date *'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _inputDecoration('Select payment date'),
                child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Notes'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: _inputDecoration('Enter notes (optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving || _selectedCustomer == null ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Payment'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    if (hasPreselectedCustomer) {
      return _selectedCustomer == null
          ? const Center(child: CircularProgressIndicator())
          : _buildCustomerTile(_selectedCustomer!);
    }

    final customersAsync = ref.watch(customersProvider(CustomerFilter()));
    return customersAsync.when(
      data: (customers) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Customer *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<Customer>(
              decoration: _inputDecoration('Select customer'),
              items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (c) => setState(() => _selectedCustomer = c),
              initialValue: _selectedCustomer,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(customer.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(customer.mobile ?? '', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface));
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter payment amount')));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'customerId': _selectedCustomer!.id,
      'amount': amount,
      'paymentDate': _paymentDate.toIso8601String(),
      'paymentMethod': _paymentMethod,
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    };

    await ref.read(customerNotifierProvider.notifier).receivePayment(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final notifierState = ref.read(customerNotifierProvider);
    if (notifierState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${notifierState.error}'), backgroundColor: AppColors.error),
      );
    } else {
      ref.invalidate(customersProvider(CustomerFilter()));
      ref.invalidate(customerLedgerProvider(_selectedCustomer!.id));
      ref.invalidate(customerDetailProvider(_selectedCustomer!.id));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment saved')));
    }
  }
}
