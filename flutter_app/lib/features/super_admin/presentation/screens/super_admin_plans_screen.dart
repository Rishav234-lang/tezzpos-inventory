import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/toast_utils.dart';

final superAdminPlansListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.superAdminPlans);
  return response.data as List<dynamic>;
});

class SuperAdminPlansScreen extends ConsumerStatefulWidget {
  const SuperAdminPlansScreen({super.key});

  @override
  ConsumerState<SuperAdminPlansScreen> createState() => _SuperAdminPlansScreenState();
}

class _SuperAdminPlansScreenState extends ConsumerState<SuperAdminPlansScreen> {
  bool _isLoading = false;

  Future<void> _togglePlanStatus(String id, bool activate) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiConstants.superAdminPlans}/$id', data: {'status': activate ? 'ACTIVE' : 'INACTIVE'});
      ref.invalidate(superAdminPlansListProvider);
      if (mounted) showSuccessToast( activate ? 'Plan activated' : 'Plan deactivated');
    } catch (e) {
      if (mounted) showErrorToast( parseApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final isEdit = plan != null;
    final nameCtrl = TextEditingController(text: plan?['name']?.toString() ?? '');
    final monthlyCtrl = TextEditingController(text: plan?['monthlyPrice']?.toString() ?? '');
    final yearlyCtrl = TextEditingController(text: plan?['yearlyPrice']?.toString() ?? '');
    final descCtrl = TextEditingController(text: plan?['description']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Plan' : 'Create Plan'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Plan Name *', prefixIcon: Icon(Icons.label_outline)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: monthlyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly Price *', prefixIcon: Icon(Icons.currency_rupee)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: yearlyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Yearly Price *', prefixIcon: Icon(Icons.currency_rupee)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        final api = ref.read(apiClientProvider);
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'monthlyPrice': double.parse(monthlyCtrl.text.trim()),
                          'yearlyPrice': double.parse(yearlyCtrl.text.trim()),
                          'description': descCtrl.text.trim(),
                          'status': 'ACTIVE',
                        };
                        if (isEdit) {
                          await api.put('${ApiConstants.superAdminPlans}/${plan!['id']}', data: data);
                        } else {
                          await api.post(ApiConstants.superAdminPlans, data: data);
                        }
                        ref.invalidate(superAdminPlansListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) showSuccessToast( isEdit ? 'Plan updated' : 'Plan created');
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) showErrorToast( parseApiError(e));
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(superAdminPlansListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        actions: [
          FilledButton.icon(
            onPressed: _isLoading ? null : () => _showPlanDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Plan'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: plansAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorWidget(
          message: parseApiError(err),
          onRetry: () => ref.invalidate(superAdminPlansListProvider),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return AppEmptyState(
              message: 'No plans yet',
              icon: Icons.workspace_premium_outlined,
              actionLabel: 'Create Plan',
              onAction: () => _showPlanDialog(),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = plans[index] as Map<String, dynamic>;
              final status = p['status'] as String? ?? 'INACTIVE';
              final isActive = status == 'ACTIVE';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  p['description'] as String? ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.success : AppColors.error)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PriceChip(label: 'Monthly', value: '\u20b9${p['monthlyPrice'] ?? 0}'),
                          const SizedBox(width: 12),
                          _PriceChip(label: 'Yearly', value: '\u20b9${p['yearlyPrice'] ?? 0}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _ActionButton(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            onTap: _isLoading ? null : () => _showPlanDialog(plan: p),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: isActive ? 'Deactivate' : 'Activate',
                            icon: isActive ? Icons.block_outlined : Icons.check_circle_outline,
                            color: isActive ? AppColors.error : AppColors.success,
                            onTap: _isLoading ? null : () => _togglePlanStatus(p['id'] as String, !isActive),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  const _PriceChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
