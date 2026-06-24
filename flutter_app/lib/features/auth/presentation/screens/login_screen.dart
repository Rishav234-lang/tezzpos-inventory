import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSuperAdmin = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    bool success;
    if (_isSuperAdmin) {
      success = await ref.read(authStateProvider.notifier).superAdminLogin(
        _emailController.text.trim(), _passwordController.text,
      );
    } else {
      success = await ref.read(authStateProvider.notifier).login(
        _emailController.text.trim(), _passwordController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/dashboard');
      } else {
        final authState = ref.read(authStateProvider);
        setState(() => _errorMessage = authState.hasError
            ? authState.error.toString()
            : 'Invalid email or password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left branding panel
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: _buildBranding(theme),
                      ),
                      const SizedBox(width: 64),
                      // Right form panel
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildLoginCard(theme),
                      ),
                    ],
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBrandingCompact(theme),
                        const SizedBox(height: 32),
                        _buildLoginCard(theme),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icons/app_logo.png', height: 80),
        const SizedBox(height: 24),
        Text('TezzPOS', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('Inventory & Billing\nManagement System', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700, height: 1.3)),
        const SizedBox(height: 24),
        _featureItem(Icons.inventory_2_outlined, 'Manage 10,000+ products effortlessly'),
        const SizedBox(height: 12),
        _featureItem(Icons.receipt_long_outlined, 'GST-compliant invoicing & billing'),
        const SizedBox(height: 12),
        _featureItem(Icons.bar_chart_outlined, 'Real-time reports & analytics'),
      ],
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
      ],
    );
  }

  Widget _buildBrandingCompact(ThemeData theme) {
    return Column(
      children: [
        Image.asset('assets/icons/app_icon.png', height: 64),
        const SizedBox(height: 12),
        Text('TezzPOS Inventory', textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Sign in to manage your business', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildLoginCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome back', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Enter your credentials to continue', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),

            // Role toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: _roleToggleButton('Company Owner', false)),
                  Expanded(child: _roleToggleButton('Super Admin', true)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleToggleButton(String label, bool isSuperAdmin) {
    final isSelected = _isSuperAdmin == isSuperAdmin;
    return GestureDetector(
      onTap: () => setState(() { _isSuperAdmin = isSuperAdmin; _errorMessage = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
