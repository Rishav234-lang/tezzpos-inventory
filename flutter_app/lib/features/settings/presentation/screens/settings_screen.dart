import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';

import '../../../../core/network/api_client.dart';

import '../../../../core/constants/api_constants.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../../core/widgets/app_loading.dart';



final subscriptionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {

  try {

    final api = ref.read(apiClientProvider);

    final response = await api.get(ApiConstants.subscriptionMe);

    return response.data as Map<String, dynamic>;

  } catch (_) {

    return null;

  }

});



class SettingsScreen extends ConsumerStatefulWidget {

  const SettingsScreen({super.key});

  @override

  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();

}



class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  final _currentPasswordController = TextEditingController();

  final _newPasswordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;

  bool _obscureCurrent = true;

  bool _obscureNew = true;

  bool _obscureConfirm = true;



  @override

  void dispose() {

    _currentPasswordController.dispose();

    _newPasswordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();

  }



  Future<void> _changePassword() async {

    if (_newPasswordController.text.isEmpty || _currentPasswordController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));

      return;

    }

    if (_newPasswordController.text != _confirmPasswordController.text) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));

      return;

    }

    if (_newPasswordController.text.length < 6) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));

      return;

    }

    setState(() => _isChangingPassword = true);

    try {

      final api = ref.read(apiClientProvider);

      await api.post(ApiConstants.changePassword, data: {

        'currentPassword': _currentPasswordController.text,

        'newPassword': _newPasswordController.text,

      });

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully'), backgroundColor: AppColors.success));

        _currentPasswordController.clear();

        _newPasswordController.clear();

        _confirmPasswordController.clear();

      }

    } catch (e) {

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));

    } finally { if (mounted) setState(() => _isChangingPassword = false); }

  }



  @override

  Widget build(BuildContext context) {

    final authAsync = ref.watch(authStateProvider);

    final authUser = authAsync.valueOrNull;

    final subAsync = ref.watch(subscriptionProvider);



    return Scaffold(

      appBar: AppBar(title: const Text('Settings')),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Center(

          child: ConstrainedBox(

            constraints: const BoxConstraints(maxWidth: 600),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // Profile Section

                Card(

                  child: Padding(

                    padding: const EdgeInsets.all(16),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(

                          children: [

                            const Icon(Icons.person_outline, size: 20, color: AppColors.primary),

                            const SizedBox(width: 8),

                            Text('Profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),

                          ],

                        ),

                        const Divider(),

                        if (authUser != null) ...[

                          ListTile(leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(authUser.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))), title: Text(authUser.name, style: const TextStyle(fontWeight: FontWeight.w500)), subtitle: Text(authUser.email)),

                          ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Role'), subtitle: Text(authUser.role)),

                        ],

                      ],

                    ),

                  ),

                ),

                const SizedBox(height: 16),



                // Subscription Status

                subAsync.when(

                  loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: AppLoading())),

                  error: (_, __) => const SizedBox.shrink(),

                  data: (sub) {

                    if (sub == null) return const SizedBox.shrink();

                    final status = sub['status'] ?? 'UNKNOWN';

                    final plan = sub['plan']?['name'] ?? '';

                    final endDate = (sub['endDate'] ?? '').toString();

                    final endStr = endDate.length >= 10 ? endDate.substring(0, 10) : '';

                    final isActive = status == 'ACTIVE';

                    return Card(

                      color: isActive ? AppColors.success.withOpacity(0.05) : AppColors.warning.withOpacity(0.05),

                      child: Padding(

                        padding: const EdgeInsets.all(16),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Icon(Icons.card_membership, size: 20, color: isActive ? AppColors.success : AppColors.warning),

                                const SizedBox(width: 8),

                                Text('Subscription', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),

                                const Spacer(),

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

                            const Divider(),

                            if (plan.isNotEmpty) ListTile(dense: true, leading: const Icon(Icons.workspace_premium_outlined, size: 20), title: const Text('Plan'), subtitle: Text(plan)),

                            if (endStr.isNotEmpty) ListTile(dense: true, leading: const Icon(Icons.event_outlined, size: 20), title: const Text('Valid Until'), subtitle: Text(endStr)),

                          ],

                        ),

                      ),

                    );

                  },

                ),

                const SizedBox(height: 16),



                // Change Password

                Card(

                  child: Padding(

                    padding: const EdgeInsets.all(16),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(

                          children: [

                            const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),

                            const SizedBox(width: 8),

                            Text('Change Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),

                          ],

                        ),

                        const Divider(),

                        const SizedBox(height: 8),

                        TextField(

                          controller: _currentPasswordController,

                          obscureText: _obscureCurrent,

                          decoration: InputDecoration(

                            labelText: 'Current Password',

                            prefixIcon: const Icon(Icons.lock_outline),

                            suffixIcon: IconButton(icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent)),

                          ),

                        ),

                        const SizedBox(height: 12),

                        TextField(

                          controller: _newPasswordController,

                          obscureText: _obscureNew,

                          decoration: InputDecoration(

                            labelText: 'New Password',

                            prefixIcon: const Icon(Icons.lock_reset),

                            suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscureNew = !_obscureNew)),

                          ),

                        ),

                        const SizedBox(height: 12),

                        TextField(

                          controller: _confirmPasswordController,

                          obscureText: _obscureConfirm,

                          decoration: InputDecoration(

                            labelText: 'Confirm New Password',

                            prefixIcon: const Icon(Icons.lock_reset),

                            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),

                          ),

                        ),

                        const SizedBox(height: 16),

                        FilledButton.icon(

                          onPressed: _isChangingPassword ? null : _changePassword,

                          icon: _isChangingPassword ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),

                          label: const Text('Change Password'),

                        ),

                      ],

                    ),

                  ),

                ),

                const SizedBox(height: 16),



                // App Info

                Card(

                  child: Padding(

                    padding: const EdgeInsets.all(16),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(

                          children: [

                            const Icon(Icons.info_outline, size: 20, color: AppColors.primary),

                            const SizedBox(width: 8),

                            Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),

                          ],

                        ),

                        const Divider(),

                        const ListTile(dense: true, leading: Icon(Icons.info_outline), title: Text('Version'), subtitle: Text('1.0.0')),

                        const ListTile(dense: true, leading: Icon(Icons.business), title: Text('TezzPOS Inventory'), subtitle: Text('Inventory Management System')),

                      ],

                    ),

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}

