import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/providers/auth_provider.dart';

final _superAdminCompaniesListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.superAdminCompanies, queryParams: params);
  return response.data as Map<String, dynamic>;
});

final _superAdminPlansProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.superAdminPlans);
  return response.data as List<dynamic>;
});

class SuperAdminCompaniesScreen extends ConsumerStatefulWidget {
  const SuperAdminCompaniesScreen({super.key});
  @override
  ConsumerState<SuperAdminCompaniesScreen> createState() => _State();
}

class _State extends ConsumerState<SuperAdminCompaniesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _status = '';
  int _page = 1;
  Map<String, String> _params = {'page': '1', 'limit': '15'};
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() { super.initState(); _updateParams(); }
  @override
  void dispose() { _debounce?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  void _updateParams() {
    _params = {'page': '$_page', 'limit': '15', if (_search.isNotEmpty) 'search': _search, if (_status.isNotEmpty) 'status': _status};
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => setState(() { _search = v; _page = 1; _updateParams(); }));
  }

  Future<void> _statusAction(String id, String action, String name) async {
    final label = action == 'approve' ? 'approve' : action == 'suspend' ? 'suspend' : 'activate';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('${label[0].toUpperCase()}${label.substring(1)} Company'),
      content: Text('Are you sure you want to $label "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: action == 'suspend' ? AppColors.error : AppColors.success), onPressed: () => Navigator.pop(ctx, true), child: Text(label[0].toUpperCase() + label.substring(1))),
      ],
    ));
    if (ok != true || !mounted) return;
    try {
      setState(() => _loading = true);
      await ref.read(apiClientProvider).put(ApiConstants.superAdminCompanyAction(id, action));
      ref.invalidate(_superAdminCompaniesListProvider(_params));
      if (mounted) showSuccessToast( 'Company ${label}d successfully');
    } catch (e) {
      if (mounted) showErrorToast( parseApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final n = TextEditingController(), e = TextEditingController(), p = TextEditingController(), a = TextEditingController();
    final on = TextEditingController(), oe = TextEditingController(), op = TextEditingController();
    final fk = GlobalKey<FormState>();
    bool s = false;
    await showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: const Text('Create New Company'),
        content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Company Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          TextFormField(controller: n, decoration: const InputDecoration(labelText: 'Company Name *', prefixIcon: Icon(Icons.business_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: e, decoration: const InputDecoration(labelText: 'Company Email *', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: p, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 10),
          TextFormField(controller: a, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 16),
          Text('Owner Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          TextFormField(controller: on, decoration: const InputDecoration(labelText: 'Owner Name *', prefixIcon: Icon(Icons.person_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: oe, decoration: const InputDecoration(labelText: 'Owner Email *', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: op, obscureText: true, decoration: const InputDecoration(labelText: 'Owner Password *', prefixIcon: Icon(Icons.lock_outlined)), validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
        ])))),
        actions: [
          TextButton(onPressed: s ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: s ? null : () async {
            if (!fk.currentState!.validate()) return;
            ss(() => s = true);
            try {
              final api = ref.read(apiClientProvider);
              final oem = oe.text.trim();
              final opw = op.text;
              await api.post(ApiConstants.superAdminCompanies, data: {'name': n.text.trim(), 'email': e.text.trim(), 'phone': p.text.trim(), 'address': a.text.trim(), 'ownerName': on.text.trim(), 'ownerEmail': oem, 'ownerPassword': opw});
              ref.invalidate(_superAdminCompaniesListProvider(_params));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) { showSuccessToast( 'Company created successfully'); _showCreds(oem, opw); }
            } catch (ex) { ss(() => s = false); if (ctx.mounted) showErrorToast( parseApiError(ex)); }
          }, child: s ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create')),
        ],
      ),
    ));
  }

  Future<void> _showCreds(String email, String pw) async {
    await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.verified, color: AppColors.success), SizedBox(width: 8), Text('Company Created')]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.success.withOpacity(0.3))), child: const Row(children: [Icon(Icons.info_outline, color: AppColors.success, size: 16), SizedBox(width: 8), Expanded(child: Text('Save these credentials. They are shown only once.', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)))]))
        ,const SizedBox(height: 12),
        const Text('Owner Login Credentials:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CredRow(label: 'Email', value: email, showCopy: true),
          const SizedBox(height: 8),
          _CredRow(label: 'Password', value: pw, showCopy: true),
        ])),
        const SizedBox(height: 12),
        const Text('Use the "Company Owner" tab on the login screen.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('I have saved the credentials'))],
    ));
  }

  Future<void> _edit(Map<String, dynamic> c) async {
    final n = TextEditingController(text: c['name']?.toString() ?? ''), e = TextEditingController(text: c['email']?.toString() ?? '');
    final p = TextEditingController(text: c['phone']?.toString() ?? ''), a = TextEditingController(text: c['address']?.toString() ?? ''), g = TextEditingController(text: c['gstNumber']?.toString() ?? '');
    final o = c['owner'] as Map<String, dynamic>?;
    final on = TextEditingController(text: o?['name']?.toString() ?? ''), oe = TextEditingController(text: o?['email']?.toString() ?? '');
    final fk = GlobalKey<FormState>();
    bool s = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: const Text('Edit Company'),
        content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Company Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          TextFormField(controller: n, decoration: const InputDecoration(labelText: 'Company Name *', prefixIcon: Icon(Icons.business_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: e, decoration: const InputDecoration(labelText: 'Company Email *', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: p, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 10),
          TextFormField(controller: a, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 10),
          TextFormField(controller: g, decoration: const InputDecoration(labelText: 'GST Number', prefixIcon: Icon(Icons.numbers_outlined))),
          const SizedBox(height: 16),
          Text('Owner Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          TextFormField(controller: on, decoration: const InputDecoration(labelText: 'Owner Name', prefixIcon: Icon(Icons.person_outlined))),
          const SizedBox(height: 10),
          TextFormField(controller: oe, decoration: const InputDecoration(labelText: 'Owner Email', prefixIcon: Icon(Icons.email_outlined))),
        ])))),
        actions: [
          TextButton(onPressed: s ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: s ? null : () async {
            if (!fk.currentState!.validate()) return;
            ss(() => s = true);
            try {
              await ref.read(apiClientProvider).put(ApiConstants.superAdminCompanyDetail(c['id']), data: {'name': n.text.trim(), 'email': e.text.trim(), 'phone': p.text.trim(), 'address': a.text.trim(), 'gstNumber': g.text.trim(), 'ownerName': on.text.trim(), 'ownerEmail': oe.text.trim()});
              ref.invalidate(_superAdminCompaniesListProvider(_params));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) showSuccessToast( 'Company updated successfully');
            } catch (ex) { ss(() => s = false); if (ctx.mounted) showErrorToast( parseApiError(ex)); }
          }, child: s ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update')),
        ],
      ),
    ));
  }

  Future<void> _resetPw(String id, String name) async {
    final pw = TextEditingController();
    bool s = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: Text('Reset Password: $name'),
        content: TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_reset))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: s ? null : () async {
            if (pw.text.length < 6) { showWarningToast( 'Password must be at least 6 characters'); return; }
            ss(() => s = true);
            try {
              await ref.read(apiClientProvider).put(ApiConstants.superAdminCompanyResetPassword(id), data: {'newPassword': pw.text});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) showSuccessToast( 'Password reset successfully');
            } catch (ex) { ss(() => s = false); if (ctx.mounted) showErrorToast( parseApiError(ex)); }
          }, child: s ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Reset')),
        ],
      ),
    ));
  }

  Future<void> _loginAs(String id, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Login as Company'),
      content: Text('You will be logged in as the owner of "$name". Continue?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Login'))],
    ));
    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    final success = await ref.read(authStateProvider.notifier).loginAsCompany(id);
    if (mounted) {
      setState(() => _loading = false);
      if (!success) showErrorToast( ref.read(authStateProvider).error?.toString() ?? 'Login failed');
    }
  }

  Future<void> _changePlan(String id, String name) async {
    final plans = ref.read(_superAdminPlansProvider).valueOrNull ?? [];
    if (plans.isEmpty) { showWarningToast( 'No plans available. Create a plan first.'); return; }
    String? spid = (plans.first as Map<String, dynamic>)['id'] as String?;
    String bc = 'MONTHLY';
    final cp = TextEditingController();
    bool s = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: Text('Change Plan: $name'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: spid, decoration: const InputDecoration(labelText: 'Select Plan *'), items: plans.map<DropdownMenuItem<String>>((p) { final pl = p as Map<String, dynamic>; return DropdownMenuItem(value: pl['id'] as String?, child: Text('${pl['name']} (\u20b9${pl['monthlyPrice']}/mo)')); }).toList(), onChanged: (v) => ss(() => spid = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: bc, decoration: const InputDecoration(labelText: 'Billing Cycle'), items: const [DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')), DropdownMenuItem(value: 'YEARLY', child: Text('Yearly'))], onChanged: (v) => ss(() => bc = v!)),
          const SizedBox(height: 12),
          TextField(controller: cp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Custom Price (Optional)', prefixIcon: Icon(Icons.currency_rupee))),
        ])),
        actions: [
          TextButton(onPressed: s ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: s || spid == null ? null : () async {
            ss(() => s = true);
            try {
              final now = DateTime.now();
              final ed = bc == 'YEARLY' ? now.add(const Duration(days: 365)) : now.add(const Duration(days: 30));
              await ref.read(apiClientProvider).put(ApiConstants.superAdminCompanyPlan(id), data: {'planId': spid, 'billingCycle': bc, if (cp.text.isNotEmpty) 'customPrice': double.tryParse(cp.text), 'startDate': now.toIso8601String(), 'endDate': ed.toIso8601String()});
              ref.invalidate(_superAdminCompaniesListProvider(_params));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) showSuccessToast( 'Plan updated successfully');
            } catch (ex) { ss(() => s = false); if (ctx.mounted) showErrorToast( parseApiError(ex)); }
          }, child: s ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update')),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_superAdminCompaniesListProvider(_params));
    return Scaffold(
      appBar: AppBar(title: const Text('Companies'), actions: [FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add, size: 18), label: const Text('Add Company')), const SizedBox(width: 16)]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(children: [
          Expanded(child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Search companies...', prefixIcon: const Icon(Icons.search, size: 20), suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _onSearch(''); }) : null, isDense: true), onChanged: _onSearch)),
          const SizedBox(width: 10),
          _Filter(value: _status, onChanged: (v) => setState(() { _status = v; _page = 1; _updateParams(); })),
        ])),
        const SizedBox(height: 8),
        Expanded(child: async.when(
          loading: () => const AppLoading(),
          error: (err, _) => AppErrorWidget(message: parseApiError(err), onRetry: () => ref.invalidate(_superAdminCompaniesListProvider(_params))),
          data: (result) {
            final companies = result['data'] as List<dynamic>? ?? [];
            final pagination = result['pagination'] as Map<String, dynamic>?;
            if (companies.isEmpty) return AppEmptyState(message: _search.isNotEmpty ? 'No companies match "$_search"' : 'No companies yet', icon: Icons.business_outlined, actionLabel: 'Add Company', onAction: _create);
            return Column(children: [
              Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), itemCount: companies.length, separatorBuilder: (_, __) => const SizedBox(height: 6), itemBuilder: (context, index) {
                final c = companies[index];
                return _Card(
                  company: c,
                  onTap: () => context.go('/super-admin/companies/${c['id']}'),
                  onApprove: () => _statusAction(c['id'], 'approve', c['name']),
                  onSuspend: () => _statusAction(c['id'], 'suspend', c['name']),
                  onActivate: () => _statusAction(c['id'], 'activate', c['name']),
                  onReset: () => _resetPw(c['id'], c['name']),
                  onLogin: () => _loginAs(c['id'], c['name']),
                  onPlan: () => _changePlan(c['id'], c['name']),
                  onEdit: () => _edit(c),
                );
              })),
              if (pagination != null && (pagination['totalPages'] ?? 1) > 1)
                _Pagination(page: _page, totalPages: pagination['totalPages'] ?? 1, total: pagination['total'] ?? 0, onChange: (p) => setState(() { _page = p; _updateParams(); })),
            ]);
          },
        )),
      ]),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label, value;
  final bool showCopy;
  const _CredRow({required this.label, required this.value, this.showCopy = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                if (showCopy)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Copy',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      showSuccessToast('Copied to clipboard');
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _Filter({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)), child: DropdownButton<String>(value: value, isDense: true, items: const [DropdownMenuItem(value: '', child: Text('All Status', style: TextStyle(fontSize: 13))), DropdownMenuItem(value: 'ACTIVE', child: Text('Active', style: TextStyle(fontSize: 13))), DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended', style: TextStyle(fontSize: 13))), DropdownMenuItem(value: 'PENDING', child: Text('Pending', style: TextStyle(fontSize: 13)))], onChanged: (v) => onChanged(v ?? ''))));
}

class _Card extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback onTap, onApprove, onSuspend, onActivate, onReset, onLogin, onPlan, onEdit;
  const _Card({required this.company, required this.onTap, required this.onApprove, required this.onSuspend, required this.onActivate, required this.onReset, required this.onLogin, required this.onPlan, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final status = company['status'] as String? ?? 'UNKNOWN';
    final statusColor = _sc(status);
    final owner = company['owner'] as Map<String, dynamic>?;
    final sub = company['subscription'] as Map<String, dynamic>?;
    final plan = sub?['plan'] as Map<String, dynamic>?;
    return Card(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text((company['name'] as String? ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(company['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis), Text(company['email'] as String? ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
      ]),
      if (owner != null || plan != null) ...[const SizedBox(height: 10), Wrap(spacing: 16, children: [if (owner != null) _Chip(icon: Icons.person_outline, label: owner['name'] as String? ?? ''), if (owner != null) _Chip(icon: Icons.email_outlined, label: owner['email'] as String? ?? ''), if (plan != null) _Chip(icon: Icons.workspace_premium_outlined, label: plan['name'] as String? ?? 'No Plan'), if (sub != null) _Chip(icon: Icons.event_outlined, label: _fd(sub['endDate']?.toString()))])],
      const SizedBox(height: 10),
      Wrap(alignment: WrapAlignment.end, spacing: 4, runSpacing: 4, children: [
        if (status == 'PENDING') _AB(label: 'Approve', icon: Icons.check_circle_outline, color: AppColors.success, onTap: onApprove),
        if (status == 'ACTIVE') _AB(label: 'Suspend', icon: Icons.block_outlined, color: AppColors.error, onTap: onSuspend),
        if (status == 'SUSPENDED') _AB(label: 'Activate', icon: Icons.play_circle_outline, color: AppColors.success, onTap: onActivate),
        _AB(label: 'Edit', icon: Icons.edit_outlined, color: AppColors.primary, onTap: onEdit),
        _AB(label: 'Plan', icon: Icons.workspace_premium_outlined, color: AppColors.info, onTap: onPlan),
        _AB(label: 'Login', icon: Icons.login, color: Colors.blue, onTap: onLogin),
        _AB(label: 'Reset', icon: Icons.lock_reset, color: AppColors.warning, onTap: onReset),
      ]),
    ]))));
  }

  String _fd(String? d) { if (d == null || d.isEmpty) return 'No expiry'; return d.length >= 10 ? 'Until: ${d.substring(0, 10)}' : d; }
  Color _sc(String s) { switch (s) { case 'ACTIVE': return AppColors.success; case 'SUSPENDED': return AppColors.error; case 'PENDING': return AppColors.warning; default: return Colors.grey; } }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: Colors.grey.shade500), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))]);
}

class _AB extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AB({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton.icon(onPressed: onTap, icon: Icon(icon, size: 15, color: color), label: Text(label, style: TextStyle(fontSize: 12, color: color)), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), visualDensity: VisualDensity.compact));
}

class _Pagination extends StatelessWidget {
  final int page, totalPages, total;
  final ValueChanged<int> onChange;
  const _Pagination({required this.page, required this.totalPages, required this.total, required this.onChange});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))), child: Row(children: [
    Text('$total total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    const Spacer(),
    IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: page > 1 ? () => onChange(page - 1) : null),
    Text('Page $page of $totalPages', style: const TextStyle(fontSize: 13)),
    IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: page < totalPages ? () => onChange(page + 1) : null),
  ]));
}
