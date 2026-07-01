import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/super_admin_providers.dart';

class AddEditPlanScreen extends ConsumerStatefulWidget {
  final String? planId;

  const AddEditPlanScreen({super.key, this.planId});

  @override
  ConsumerState<AddEditPlanScreen> createState() => _AddEditPlanScreenState();
}

class _AddEditPlanScreenState extends ConsumerState<AddEditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _yearlyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.planId != null;
    if (_isEdit) _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    final repository = ref.read(superAdminRepositoryProvider);
    final result = await repository.getPlans();
    result.fold(
      (failure) {},
      (plans) {
        final plan = plans.firstWhere((p) => p.id == widget.planId);
        setState(() {
          _nameController.text = plan.name;
          _monthlyController.text = plan.monthlyPrice.toString();
          _yearlyController.text = plan.yearlyPrice.toString();
          _descriptionController.text = plan.description ?? '';
        });
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isEdit) {
      final plan = await ref.read(superAdminNotifierProvider.notifier).updatePlan(
        widget.planId!,
        {
          'name': _nameController.text.trim(),
          'monthlyPrice': double.parse(_monthlyController.text.trim()),
          'yearlyPrice': double.parse(_yearlyController.text.trim()),
          'description': _descriptionController.text.trim(),
        },
      );
      setState(() => _isLoading = false);
      if (plan != null && mounted) {
        ref.invalidate(plansProvider);
        context.pop();
      }
    } else {
      final plan = await ref.read(superAdminNotifierProvider.notifier).createPlan(
        name: _nameController.text.trim(),
        monthlyPrice: double.parse(_monthlyController.text.trim()),
        yearlyPrice: double.parse(_yearlyController.text.trim()),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      );
      setState(() => _isLoading = false);
      if (plan != null && mounted) {
        ref.invalidate(plansProvider);
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
        title: Text(_isEdit ? 'Edit Plan' : 'Add Plan'),
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
                      _buildSectionTitle('Plan Details'),
                      const SizedBox(height: 12),
                      _buildTextField('Plan Name', _nameController, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Monthly Price', _monthlyController, keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('Yearly Price', _yearlyController, keyboardType: TextInputType.number, validator: (v) => v?.isEmpty == true ? 'Required' : null)),
                        ],
                      ),
                      _buildTextField('Description', _descriptionController, maxLines: 3),
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
                            : Text(_isEdit ? 'Update Plan' : 'Create Plan'),
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
