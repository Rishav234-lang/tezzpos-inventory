import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../config/providers.dart';
import '../../domain/entities/purchase.dart';
import '../providers/purchase_providers.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final String purchaseId;

  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(widget.purchaseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _buildAppBar(context),
            ),
            SliverToBoxAdapter(
              child: purchaseAsync.when(
                data: (purchase) => _buildHeader(purchase),
                loading: () => _buildHeaderShimmer(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: purchaseAsync.when(
                data: (purchase) => _buildSummaryCards(purchase),
                loading: () => _buildSummaryShimmer(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),
          ],
          body: purchaseAsync.when(
            data: (purchase) => TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(purchase: purchase),
                _ProductsTab(purchase: purchase),
                _PaymentsTab(purchase: purchase),
                _BatchesTab(purchase: purchase),
                _InvoiceTab(purchase: purchase),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $error', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: purchaseAsync.when(
        data: (purchase) => _buildBottomActions(purchase),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          ),
          Expanded(
            child: Text(
              'Purchase Details',
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: AppColors.onSurface),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Purchase purchase) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final statusColor = _statusColor(purchase.status);
    final statusBg = _statusBg(purchase.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      purchase.invoiceNumber,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(purchase.status),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  purchase.vendor?.name ?? 'Unknown Vendor',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (purchase.vendor?.mobile != null && purchase.vendor!.mobile!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          purchase.vendor!.mobile!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(purchase.purchaseDate),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created by',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                'Owner',
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Purchase purchase) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Total Amount',
            value: '₹ ${_currencyFormat(purchase.totalAmount)}',
            valueColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _SummaryItem(
            label: 'Paid Amount',
            value: '₹ ${_currencyFormat(purchase.paidAmount)}',
            valueColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          _SummaryItem(
            label: 'Balance Due',
            value: '₹ ${_currencyFormat(purchase.balanceAmount)}',
            valueColor: AppColors.error,
          ),
          const SizedBox(width: 8),
          _SummaryItem(
            label: 'Status',
            value: _statusLabel(purchase.status),
            valueColor: _statusColor(purchase.status),
            isPill: true,
            pillBg: _statusBg(purchase.status),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Row(
          children: List.generate(4, (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: context.textTheme.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
          Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Products'),
          Tab(icon: Icon(Icons.payment_outlined, size: 18), text: 'Payments'),
          Tab(icon: Icon(Icons.layers_outlined, size: 18), text: 'Batches'),
          Tab(icon: Icon(Icons.receipt_outlined, size: 18), text: 'Invoice'),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Purchase purchase) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => context.push('${AppRoutes.editPurchase}/${purchase.id}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle_outline,
                label: 'Record Payment',
                color: AppColors.primary,
                onTap: () => _showRecordPaymentSheet(context, purchase),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share Invoice',
                onTap: () => _showShareInvoiceSheet(context, purchase),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.more_horiz,
                label: 'More',
                onTap: () => _showMoreOptionsSheet(purchase),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context, Purchase purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(purchase: purchase),
    );
  }

  void _showShareInvoiceSheet(BuildContext context, Purchase purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareInvoiceSheet(purchase: purchase),
    );
  }

  void _showMoreOptionsSheet(Purchase purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MoreOptionsSheet(
        purchase: purchase,
        onDuplicate: () {
          Navigator.pop(ctx);
          context.push('${AppRoutes.duplicatePurchase}/${purchase.id}');
        },
        onAddNotes: () {
          Navigator.pop(ctx);
          _showAddNotesDialog(purchase);
        },
        onViewLedger: () {
          Navigator.pop(ctx);
          if (purchase.vendor != null) {
            context.push('${AppRoutes.vendorDetail}/${purchase.vendor!.id}');
          }
        },
        onViewBatches: () {
          Navigator.pop(ctx);
          _tabController.animateTo(3);
        },
        onMarkPaid: () async {
          Navigator.pop(ctx);
          final notifier = ref.read(purchaseNotifierProvider.notifier);
          await notifier.updatePurchase(purchase.id, {
            'paidAmount': purchase.totalAmount,
            'status': 'PAID',
          });
          if (!mounted) return;
          ref.invalidate(purchaseDetailProvider(purchase.id));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as paid')),
          );
        },
        onArchive: () async {
          Navigator.pop(ctx);
          final notifier = ref.read(purchaseNotifierProvider.notifier);
          await notifier.deletePurchase(purchase.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase archived')),
          );
        },
        onReturn: () {
          Navigator.pop(ctx);
          context.push('${AppRoutes.purchaseReturn}/${purchase.id}');
        },
      ),
    );
  }

  void _showAddNotesDialog(Purchase purchase) {
    final controller = TextEditingController(text: purchase.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(purchaseNotifierProvider.notifier);
              await notifier.updatePurchase(purchase.id, {'notes': controller.text.trim()});
              if (!mounted) return;
              ref.invalidate(purchaseDetailProvider(purchase.id));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notes saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _currencyFormat(double amount) {
    return NumberFormat('#,##,##0.00').format(amount);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFF2E7D32);
      case 'PARTIAL':
        return const Color(0xFFF9A825);
      case 'UNPAID':
        return const Color(0xFFC62828);
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFFE8F5E9);
      case 'PARTIAL':
        return const Color(0xFFFFFDE7);
      case 'UNPAID':
        return const Color(0xFFFFEBEE);
      default:
        return AppColors.surfaceVariant;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'PARTIAL':
        return 'Partial Paid';
      case 'UNPAID':
        return 'Unpaid';
      default:
        return status;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isPill;
  final Color? pillBg;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isPill = false,
    this.pillBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isPill ? (pillBg ?? AppColors.surfaceVariant.withValues(alpha: 0.5)) : Colors.transparent,
          borderRadius: BorderRadius.circular(isPill ? 20 : 10),
          border: isPill ? null : Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: btnColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: btnColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Widgets ──

class _OverviewTab extends StatelessWidget {
  final Purchase purchase;

  const _OverviewTab({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currency = NumberFormat('#,##,##0.00');

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Purchase Information'),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _InfoRow(label: 'Vendor', value: purchase.vendor?.name ?? '—'),
              _InfoRow(label: 'Invoice No.', value: purchase.invoiceNumber),
              _InfoRow(label: 'Purchase Date', value: dateFormat.format(purchase.purchaseDate)),
              _InfoRow(label: 'Reference No.', value: '—'),
              _InfoRow(label: 'Payment Method', value: '—'),
              _InfoRow(label: 'Created By', value: 'Owner'),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSectionTitle('Payment Summary'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Record Payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  textStyle: context.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _PaymentRow(
                dotColor: AppColors.success,
                date: dateFormat.format(purchase.purchaseDate),
                time: DateFormat('hh:mm a').format(purchase.purchaseDate),
                amount: '₹ ${currency.format(purchase.paidAmount)}',
                method: 'Cash',
                by: 'By Owner',
                isPending: false,
              ),
              if (purchase.balanceAmount > 0) ...[
                const SizedBox(height: 8),
                _PaymentRow(
                  dotColor: AppColors.error,
                  date: 'Pending Amount',
                  time: '',
                  amount: '₹ ${currency.format(purchase.balanceAmount)}',
                  method: 'Balance Due',
                  by: '',
                  isPending: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Notes'),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              if (purchase.notes != null && purchase.notes!.isNotEmpty)
                Text(purchase.notes!, style: context.textTheme.bodyMedium)
              else
                Text(
                  'No notes available',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _SummaryIconItem(
                  icon: Icons.layers_outlined,
                  iconColor: AppColors.info,
                  bgColor: const Color(0xFFEEF2FF),
                  label: 'Total Items',
                  value: purchase.items.length.toString(),
                ),
                _SummaryIconItem(
                  icon: Icons.format_list_numbered,
                  iconColor: AppColors.success,
                  bgColor: const Color(0xFFD1FAE5),
                  label: 'Total Quantity',
                  value: '${purchase.items.fold<int>(0, (s, i) => s + i.quantity)} pcs',
                ),
                _SummaryIconItem(
                  icon: Icons.savings_outlined,
                  iconColor: AppColors.success,
                  bgColor: const Color(0xFFFFFDE7),
                  label: 'Total Savings',
                  value: '₹ ${currency.format(purchase.items.fold(0.0, (s, i) => s + i.savings))}',
                ),
                _SummaryIconItem(
                  icon: Icons.scale_outlined,
                  iconColor: AppColors.onSurfaceVariant,
                  bgColor: AppColors.surfaceVariant,
                  label: 'Total Weight',
                  value: '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Color dotColor;
  final String date;
  final String time;
  final String amount;
  final String method;
  final String by;
  final bool isPending;

  const _PaymentRow({
    required this.dotColor,
    required this.date,
    required this.time,
    required this.amount,
    required this.method,
    required this.by,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isPending)
              Container(width: 2, height: 30, color: AppColors.outline.withValues(alpha: 0.3)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    date,
                    style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                method,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPending ? AppColors.error : AppColors.onSurface,
              ),
            ),
            if (by.isNotEmpty)
              Text(
                by,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SummaryIconItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _SummaryIconItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final Purchase purchase;

  const _ProductsTab({required this.purchase});

  @override
  Widget build(BuildContext context) {
    if (purchase.items.isEmpty) {
      return _buildEmpty('No products in this purchase');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchase.items.length,
      itemBuilder: (context, index) {
        final item = purchase.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (item.sku != null && item.sku!.isNotEmpty)
                Text(
                  'SKU: ${item.sku}',
                  style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ProductMeta(label: 'Qty', value: '${item.quantity}'),
                  const SizedBox(width: 16),
                  _ProductMeta(label: 'Purchase Price', value: '₹ ${item.purchasePrice.toStringAsFixed(2)}'),
                  const SizedBox(width: 16),
                  _ProductMeta(label: 'MRP', value: '₹ ${item.mrp.toStringAsFixed(2)}'),
                ],
              ),
              if (item.expiryDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Expiry: ${DateFormat('dd MMM yyyy').format(item.expiryDate!)}',
                  style: context.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ₹ ${item.totalAmount.toStringAsFixed(2)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductMeta extends StatelessWidget {
  final String label;
  final String value;

  const _ProductMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final Purchase purchase;

  const _PaymentsTab({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            children: [
              _InfoRow(label: 'Total Amount', value: '₹ ${currency.format(purchase.totalAmount)}'),
              _InfoRow(label: 'Paid Amount', value: '₹ ${currency.format(purchase.paidAmount)}'),
              _InfoRow(label: 'Balance Due', value: '₹ ${currency.format(purchase.balanceAmount)}'),
              _InfoRow(label: 'Payment Status', value: _statusLabel(purchase.status)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _PaymentRow(
                dotColor: AppColors.success,
                date: dateFormat.format(purchase.purchaseDate),
                time: DateFormat('hh:mm a').format(purchase.purchaseDate),
                amount: '₹ ${currency.format(purchase.paidAmount)}',
                method: 'Initial Payment',
                by: 'By Owner',
                isPending: false,
              ),
              if (purchase.balanceAmount > 0) ...[
                const SizedBox(height: 8),
                _PaymentRow(
                  dotColor: AppColors.error,
                  date: 'Pending Amount',
                  time: '',
                  amount: '₹ ${currency.format(purchase.balanceAmount)}',
                  method: 'Balance Due',
                  by: '',
                  isPending: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'PARTIAL':
        return 'Partial Paid';
      case 'UNPAID':
        return 'Unpaid';
      default:
        return status;
    }
  }
}

class _BatchesTab extends StatelessWidget {
  final Purchase purchase;

  const _BatchesTab({required this.purchase});

  @override
  Widget build(BuildContext context) {
    if (purchase.batches.isEmpty) {
      return _buildEmpty('No batches for this purchase');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchase.batches.length,
      itemBuilder: (context, index) {
        final batch = purchase.batches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      batch.batchNumber,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: batch.status == 'ACTIVE'
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      batch.status,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: batch.status == 'ACTIVE'
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ProductMeta(
                    label: 'Purchased',
                    value: '${batch.purchasedQuantity}',
                  ),
                  const SizedBox(width: 20),
                  _ProductMeta(
                    label: 'Available',
                    value: '${batch.availableQuantity}',
                  ),
                  const SizedBox(width: 20),
                  _ProductMeta(
                    label: 'Price',
                    value: '₹ ${batch.purchasePrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
              if (batch.expiryDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Expiry: ${DateFormat('dd MMM yyyy').format(batch.expiryDate!)}',
                  style: context.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InvoiceTab extends ConsumerWidget {
  final Purchase purchase;

  const _InvoiceTab({required this.purchase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currency = NumberFormat('#,##,##0.00');
    final authState = ref.watch(authStateProvider).value;
    final companyName = authState?.user?.companyName ?? 'TezzPOS Retail';

    final statusColor = purchase.status == 'PAID'
        ? const Color(0xFF2E7D32)
        : purchase.status == 'PARTIAL'
            ? const Color(0xFFF9A825)
            : const Color(0xFFC62828);
    final statusBg = purchase.status == 'PAID'
        ? const Color(0xFFE8F5E9)
        : purchase.status == 'PARTIAL'
            ? const Color(0xFFFFFDE7)
            : const Color(0xFFFFEBEE);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(companyName,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Smart Inventory, Easy Business',
                  style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('123, Business Street, City - 400001',
                  style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                Text('GSTIN: 24ABCDE1234F1Z5',
                  style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 16),
                Center(
                  child: Text('PURCHASE INVOICE',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vendor Details',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Text(purchase.vendor?.name ?? 'Unknown',
                            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          if (purchase.vendor?.gstNumber != null)
                            Text('GSTIN: ${purchase.vendor!.gstNumber}',
                              style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                          if (purchase.vendor?.mobile != null)
                            Text('Phone: ${purchase.vendor!.mobile}',
                              style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Invoice No.',
                          style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(purchase.invoiceNumber,
                          style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Date',
                          style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(dateFormat.format(purchase.purchaseDate),
                          style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 28,
                        child: Text('#', style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(flex: 3,
                        child: Text('Product', style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(
                        child: Text('Qty', textAlign: TextAlign.center,
                          style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(
                        child: Text('Price', textAlign: TextAlign.right,
                          style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
                      Expanded(
                        child: Text('Amount', textAlign: TextAlign.right,
                          style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                ...purchase.items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 28,
                          child: Text('$index', style: context.textTheme.labelSmall)),
                        Expanded(flex: 3,
                          child: Text(item.productName, style: context.textTheme.bodySmall)),
                        Expanded(
                          child: Text('${item.quantity}', textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall)),
                        Expanded(
                          child: Text('₹ ${item.purchasePrice.toStringAsFixed(2)}', textAlign: TextAlign.right,
                            style: context.textTheme.bodySmall)),
                        Expanded(
                          child: Text('₹ ${currency.format(item.totalAmount)}', textAlign: TextAlign.right,
                            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Items: ${purchase.items.length}',
                          style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        Text('Total Qty: ${purchase.items.fold<int>(0, (s, i) => s + i.quantity)}',
                          style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _InvoiceTotalRow(label: 'Sub Total', value: '₹ ${currency.format(purchase.totalAmount)}'),
                        _InvoiceTotalRow(label: 'Other Charges', value: '₹ 0'),
                        const Divider(height: 12, indent: 80),
                        _InvoiceTotalRow(
                          label: 'Grand Total',
                          value: '₹ ${currency.format(purchase.totalAmount)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InvoiceSummaryCard(
                  label: 'Paid Amount',
                  value: '₹ ${currency.format(purchase.paidAmount)}',
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InvoiceSummaryCard(
                  label: 'Balance',
                  value: '₹ ${currency.format(purchase.balanceAmount)}',
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InvoiceSummaryCard(
                  label: 'Status',
                  value: purchase.status == 'PAID' ? 'Paid' : purchase.status == 'PARTIAL' ? 'Partial' : 'Unpaid',
                  valueColor: statusColor,
                  isPill: true,
                  pillBg: statusBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _InvoiceTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InvoiceTotalRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
            style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 16),
          Text(value,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isPill;
  final Color? pillBg;

  const _InvoiceSummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isPill = false,
    this.pillBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isPill ? (pillBg ?? AppColors.surfaceVariant) : AppColors.surface,
        borderRadius: BorderRadius.circular(isPill ? 20 : 10),
        border: isPill ? null : Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label,
            style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final Purchase purchase;

  const _RecordPaymentSheet({required this.purchase});

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;
  String _paymentMethod = 'UPI';
  DateTime _paymentDate = DateTime.now();

  final _methods = ['CASH', 'UPI', 'CARD', 'BANK_TRANSFER'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.purchase.balanceAmount > 0
          ? widget.purchase.balanceAmount.toStringAsFixed(2)
          : '',
    );
    _referenceController = TextEditingController();
    _notesController = TextEditingController(
      text: 'Payment for invoice ${widget.purchase.invoiceNumber}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');
    final statusColor = widget.purchase.status == 'PAID'
        ? const Color(0xFF2E7D32)
        : widget.purchase.status == 'PARTIAL'
            ? const Color(0xFFF9A825)
            : const Color(0xFFC62828);
    final statusBg = widget.purchase.status == 'PAID'
        ? const Color(0xFFE8F5E9)
        : widget.purchase.status == 'PARTIAL'
            ? const Color(0xFFFFFDE7)
            : const Color(0xFFFFEBEE);

    final notifierState = ref.watch(purchaseNotifierProvider);

    ref.listen(purchaseNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment recorded successfully')),
          );
        },
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error),
          );
        },
      );
    });

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payment, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.purchase.invoiceNumber,
                            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(widget.purchase.vendor?.name ?? 'Unknown Vendor',
                            style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.purchase.status == 'PAID' ? 'Paid' : widget.purchase.status == 'PARTIAL' ? 'Partial' : 'Unpaid',
                        style: context.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentSummaryItem(
                        label: 'Total Amount',
                        value: '₹ ${currency.format(widget.purchase.totalAmount)}',
                      ),
                    ),
                    Expanded(
                      child: _PaymentSummaryItem(
                        label: 'Paid',
                        value: '₹ ${currency.format(widget.purchase.paidAmount)}',
                      ),
                    ),
                    Expanded(
                      child: _PaymentSummaryItem(
                        label: 'Balance',
                        value: '₹ ${currency.format(widget.purchase.balanceAmount)}',
                        valueColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildLabel('Payment Amount'),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: context.textTheme.bodyMedium,
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Payment Method'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _paymentMethod,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _methods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Row(
                            children: [
                              Icon(_methodIcon(method), size: 18, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 10),
                              Text(method.replaceAll('_', ' ')),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Reference No. (Optional)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    hintText: 'e.g. UTR123456789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Payment Date'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _paymentDate = picked);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(dateFormat.format(_paymentDate), style: context.textTheme.bodyMedium),
                        const Spacer(),
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Notes (Optional)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: notifierState.isLoading
                        ? null
                        : () {
                            final amount = double.tryParse(_amountController.text) ?? 0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid amount')),
                              );
                              return;
                            }
                            ref.read(purchaseNotifierProvider.notifier).recordPayment({
                              'vendorId': widget.purchase.vendorId,
                              'purchaseId': widget.purchase.id,
                              'amount': amount,
                              'paymentDate': _paymentDate.toIso8601String(),
                              'paymentMethod': _paymentMethod,
                              'referenceNo': _referenceController.text.isEmpty ? null : _referenceController.text,
                              'notes': _notesController.text.isEmpty ? null : _notesController.text,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: notifierState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : const Text('Save Payment', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500));
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.money;
      case 'UPI':
        return Icons.qr_code;
      case 'CARD':
        return Icons.credit_card;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}

class _PaymentSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PaymentSummaryItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: context.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.onSurface,
          )),
      ],
    );
  }
}

class _ShareInvoiceSheet extends StatelessWidget {
  final Purchase purchase;

  const _ShareInvoiceSheet({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final options = [
      _ShareOption(icon: Icons.chat_bubble, color: const Color(0xFF25D366), label: 'WhatsApp'),
      _ShareOption(icon: Icons.email, color: const Color(0xFFEA4335), label: 'Email'),
      _ShareOption(icon: Icons.picture_as_pdf, color: const Color(0xFFDC2626), label: 'Save as PDF'),
      _ShareOption(icon: Icons.print, color: const Color(0xFF2563EB), label: 'Print'),
      _ShareOption(icon: Icons.link, color: const Color(0xFF7C3AED), label: 'Copy Link'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Share Invoice',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(purchase.invoiceNumber,
              style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: options.map((opt) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: opt.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(opt.icon, color: opt.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(opt.label, style: context.textTheme.labelSmall),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ShareOption {
  final IconData icon;
  final Color color;
  final String label;

  const _ShareOption({required this.icon, required this.color, required this.label});
}

class _MoreOptionsSheet extends StatelessWidget {
  final Purchase purchase;
  final VoidCallback onDuplicate;
  final VoidCallback onAddNotes;
  final VoidCallback onViewLedger;
  final VoidCallback onViewBatches;
  final VoidCallback onMarkPaid;
  final VoidCallback onArchive;
  final VoidCallback onReturn;

  const _MoreOptionsSheet({
    required this.purchase,
    required this.onDuplicate,
    required this.onAddNotes,
    required this.onViewLedger,
    required this.onViewBatches,
    required this.onMarkPaid,
    required this.onArchive,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _MoreOption(icon: Icons.content_copy_outlined, label: 'Duplicate Purchase', onTap: onDuplicate),
      _MoreOption(icon: Icons.edit_note_outlined, label: 'Add Notes', onTap: onAddNotes),
      _MoreOption(icon: Icons.account_balance_wallet_outlined, label: 'View Vendor Ledger', onTap: onViewLedger),
      _MoreOption(icon: Icons.inventory_2_outlined, label: 'View Stock Batches', onTap: onViewBatches),
      _MoreOption(icon: Icons.check_circle_outlined, label: 'Mark as Paid', onTap: onMarkPaid),
      _MoreOption(icon: Icons.assignment_return_outlined, label: 'Purchase Return', onTap: onReturn, color: AppColors.error),
      _MoreOption(icon: Icons.delete_outline, label: 'Archive Purchase', onTap: onArchive, color: AppColors.error),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'More Options',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...options.map((opt) => ListTile(
                leading: Icon(opt.icon, color: opt.color ?? AppColors.onSurface),
                title: Text(opt.label, style: TextStyle(color: opt.color ?? AppColors.onSurface)),
                onTap: opt.onTap,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MoreOption({required this.icon, required this.label, required this.onTap, this.color});
}

Widget _buildEmpty(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
