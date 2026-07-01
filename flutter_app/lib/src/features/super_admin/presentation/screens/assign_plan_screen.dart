import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/super_admin_providers.dart';

class AssignPlanScreen extends ConsumerStatefulWidget {
  final String companyId;

  const AssignPlanScreen({super.key, required this.companyId});

  @override
  ConsumerState<AssignPlanScreen> createState() => _AssignPlanScreenState();
}

class _AssignPlanScreenState extends ConsumerState<AssignPlanScreen> {
  String? _selectedPlanId;
  String _billingCycle = 'MONTHLY';
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final companyAsync = ref.watch(companyDetailProvider(widget.companyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Assign Plan'),
      ),
      body: companyAsync.when(
        data: (company) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(companyDetailProvider(widget.companyId));
            ref.invalidate(plansProvider);
          },
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Company', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(company.email, style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
              const SizedBox(height: 16),
              Text('Select Plan', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) return const Text('No plans available');
                  return Column(
                    children: plans.where((p) => p.isActive).map((plan) {
                      final isSelected = _selectedPlanId == plan.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedPlanId = plan.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.outline.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Monthly: Rs. ${plan.monthlyPrice} | Yearly: Rs. ${plan.yearlyPrice}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              Text('Billing Cycle', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCycleChip('MONTHLY', 'Monthly'),
                  const SizedBox(width: 8),
                  _buildCycleChip('YEARLY', 'Yearly'),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('End Date', style: TextStyle(color: AppColors.onSurfaceVariant)),
                      const Spacer(),
                      Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _selectedPlanId == null || _isSaving ? null : _assignPlan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Assign Plan'),
              ),
              const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCycleChip(String value, String label) {
    final isSelected = _billingCycle == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _billingCycle = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w600),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3))),
      showCheckmark: false,
    );
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _assignPlan() async {
    if (_selectedPlanId == null) return;

    setState(() => _isSaving = true);
    final ok = await ref.read(superAdminNotifierProvider.notifier).assignPlan(
      widget.companyId,
      planId: _selectedPlanId!,
      billingCycle: _billingCycle,
      endDate: _endDate,
    );
    setState(() => _isSaving = false);

    if (ok && mounted) {
      ref.invalidate(companyDetailProvider(widget.companyId));
      ref.invalidate(companiesProvider(const CompanyFilter()));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan assigned successfully')));
    }
  }
}
