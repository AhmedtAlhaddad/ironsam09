import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/utils/hex_color.dart';
import '../data/models/order.dart';
import '../features/cart/cart_state.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/safe_product_image.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

const canvasColor = AdminColors.background;
const inkColor = AdminColors.primary;
const surfaceColor = AdminColors.background;
const lineColor = AdminColors.border;
const accentColor = AdminColors.accent;
const adminDiscountRefreshFailureMessage =
    'تم تنفيذ العملية، لكن تعذر تحديث القائمة. حاول إعادة التحميل.';
const adminDiscountWriteFailureMessage = 'تعذر تنفيذ العملية.';
const _temporaryProductImageBackfillEnabled = bool.fromEnvironment(
  'ENABLE_PRODUCT_IMAGE_BACKFILL',
);

class AdminPanel extends StatefulWidget {
  const AdminPanel({required this.store, required this.service, super.key});
  final StoreState store;
  final AdminService service;

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int index = 0;
  int refreshKey = 0;
  AdminOrderScope ordersScope = AdminOrderScope.active;
  String ordersQuery = '';
  static const titles = [
    'لوحة التحكم',
    'المنتجات',
    'التصنيفات',
    'المخزون',
    'الطلبات',
    'الرموز الرياضية',
  ];
  void refresh() => setState(() => refreshKey++);

  void _goToDashboard() => setState(() {
    index = 0;
    ordersScope = AdminOrderScope.active;
    ordersQuery = '';
  });

  void _leaveAdmin() => Navigator.of(context).maybePop();

  void _handleBack() {
    if (index == 0) {
      _leaveAdmin();
    } else {
      _goToDashboard();
    }
  }

  void _selectSection(int value) {
    setState(() {
      index = value;
      if (value == 4) {
        ordersScope = AdminOrderScope.active;
        ordersQuery = '';
      }
    });
  }

  void _openOrders(AdminOrderScope scope, [String query = '']) {
    setState(() {
      index = 4;
      ordersScope = scope;
      ordersQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardView(
        service: widget.service,
        onOpenOrders: _openOrders,
        onOpenSportsCodes: () => setState(() => index = 5),
        key: ValueKey(refreshKey),
      ),
      _Products(
        service: widget.service,
        onChanged: refresh,
        key: ValueKey(refreshKey),
      ),
      _Categories(
        service: widget.service,
        onChanged: refresh,
        key: ValueKey(refreshKey),
      ),
      _Inventory(
        service: widget.service,
        onChanged: refresh,
        key: ValueKey(refreshKey),
      ),
      AdminOrdersView(
        service: widget.service,
        onChanged: refresh,
        initialScope: ordersScope,
        initialQuery: ordersQuery,
        key: ValueKey('orders-$refreshKey-${ordersScope.name}-$ordersQuery'),
      ),
      AdminDiscountsView(service: widget.service, key: ValueKey(refreshKey)),
    ];
    return Theme(
      data: adminTheme(Theme.of(context)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 760;
            return PopScope<void>(
              canPop: index == 0,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                _handleBack();
              },
              child: Scaffold(
                drawer: mobile
                    ? Drawer(
                        child: _AdminNavigation(
                          index: index,
                          onSelected: (value) {
                            Navigator.pop(context);
                            _selectSection(value);
                          },
                        ),
                      )
                    : null,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    key: const ValueKey('admin-back-button'),
                    tooltip: 'رجوع',
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  title: Text(
                    titles[index],
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  actions: [
                    if (mobile)
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: 'فتح القائمة',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu),
                        ),
                      ),
                    IconButton(
                      tooltip: 'تحديث',
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => widget.service.client.auth.signOut(),
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                body: Row(
                  children: [
                    if (!mobile)
                      _AdminNavigation(
                        index: index,
                        onSelected: _selectSection,
                      ),
                    Expanded(child: pages[index]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({required this.index, required this.onSelected});
  final int index;
  final ValueChanged<int> onSelected;
  static const labels = [
    'لوحة التحكم',
    'المنتجات',
    'التصنيفات',
    'المخزون',
    'الطلبات',
    'الرموز الرياضية',
  ];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.category_outlined,
    Icons.stacked_bar_chart,
    Icons.receipt_long_outlined,
    Icons.discount_outlined,
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    color: AdminColors.sidebar,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(start: 12, bottom: 24),
          child: IronSamLogo(width: 132, height: 76),
        ),
        ...List.generate(
          labels.length,
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: item == index
                  ? AdminColors.sidebarSelected
                  : Colors.transparent,
              child: ListTile(
                key: ValueKey('admin-nav-$item'),
                leading: Icon(
                  icons[item],
                  color: item == index ? Colors.white : AdminColors.sidebarText,
                ),
                title: Text(
                  labels[item],
                  style: TextStyle(
                    color: item == index
                        ? Colors.white
                        : AdminColors.sidebarText,
                    fontWeight: item == index
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
                selected: item == index,
                selectedTileColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                onTap: () => onSelected(item),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: child,
        ),
      ),
    ),
  );
}

enum AdminOrderScope { active, delivered, cancelled, all }

enum AdminOrderDateRange { all, today, last7Days, last30Days }

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({
    required this.service,
    required this.onOpenOrders,
    required this.onOpenSportsCodes,
    super.key,
  });

  final AdminOperationsService service;
  final void Function(AdminOrderScope scope, String query) onOpenOrders;
  final VoidCallback onOpenSportsCodes;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.service.dashboard();
  }

  void _reload() => setState(() {
    _dashboardFuture = widget.service.dashboard();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _dashboardFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _AdminLoadingState(
          key: ValueKey('admin-dashboard-loading'),
          label: 'جارٍ تجهيز لوحة التحكم...',
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return _ErrorState(
          message: 'تعذر تحميل لوحة التحكم. تحقق من الاتصال وحاول مجددًا.',
          onRetry: _reload,
        );
      }

      final data = snapshot.data!;
      final rawActiveOrders = data['active_orders'];
      final activeOrders = rawActiveOrders is List
          ? rawActiveOrders
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[];
      final activeCount =
          (data['active_orders_count'] as num?)?.toInt() ?? activeOrders.length;
      final stockAlerts =
          ((data['low_stock'] as num?)?.toInt() ?? 0) +
          ((data['out_of_stock'] as num?)?.toInt() ?? 0);
      final approvedCommission =
          (data['approved_commissions'] as num?)?.toDouble() ?? 0;
      final metrics = [
        (
          'طلبات تحتاج متابعة',
          '$activeCount',
          'قيد الانتظار والتأكيد والتجهيز',
          Icons.assignment_late_outlined,
        ),
        (
          'طلبات اليوم',
          '${data['orders_today'] ?? 0}',
          'حسب تاريخ إنشاء الطلب',
          Icons.today_outlined,
        ),
        (
          'بانتظار التأكيد',
          '${data['pending'] ?? 0}',
          'لم يُخصم مخزونها بعد',
          Icons.schedule_outlined,
        ),
        (
          'تنبيهات المخزون',
          '$stockAlerts',
          'منخفض أو نافد',
          Icons.inventory_2_outlined,
        ),
      ];

      return _AdminContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'نظرة تشغيلية',
              style: TextStyle(
                color: AdminColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ما يحتاج انتباهك الآن، في مكان واحد.',
              style: TextStyle(color: AdminColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1040
                    ? 4
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final gap = 12.0;
                final width =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: width,
                          child: _Metric(
                            label: metric.$1,
                            value: metric.$2,
                            supportingText: metric.$3,
                            icon: metric.$4,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            AdminSectionCard(
              title: 'الطلبات التي تحتاج متابعة',
              subtitle: activeCount > activeOrders.length
                  ? 'أحدث ${activeOrders.length} طلبًا من أصل $activeCount'
                  : 'الطلبات قيد الانتظار أو التأكيد أو التجهيز',
              action: TextButton.icon(
                key: const ValueKey('admin-dashboard-view-all-orders'),
                onPressed: () => widget.onOpenOrders(AdminOrderScope.all, ''),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('عرض كل الطلبات'),
              ),
              child: activeOrders.isEmpty
                  ? const _EmptyState(
                      key: ValueKey('admin-dashboard-active-empty'),
                      message:
                          'لا توجد طلبات تحتاج متابعة حاليًا. كل العمليات مكتملة.',
                      positive: true,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < activeOrders.length; i++) ...[
                          _DashboardOrderRow(
                            row: activeOrders[i],
                            onOpen: () => widget.onOpenOrders(
                              AdminOrderScope.active,
                              '${activeOrders[i]['order_number'] ?? ''}',
                            ),
                          ),
                          if (i != activeOrders.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
            ),
            if (approvedCommission > 0) ...[
              const SizedBox(height: 14),
              _ActionAlert(
                key: const ValueKey('admin-dashboard-payable-alert'),
                amount: approvedCommission,
                onPressed: widget.onOpenSportsCodes,
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.supportingText,
    required this.icon,
  });

  final String label;
  final String value;
  final String supportingText;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value. $supportingText',
    child: Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AdminColors.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AdminColors.accent, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AdminColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  supportingText,
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 11,
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

class _DashboardOrderRow extends StatelessWidget {
  const _DashboardOrderRow({required this.row, required this.onOpen});

  final Map<String, dynamic> row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = orderStatusFromString(row['status'] as String? ?? 'pending');
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${row['order_number'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              '${row['customer_name'] ?? ''} · ${row['city'] ?? ''}',
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
        final statusBadge = AdminStatusBadge(
          label: orderStatusLabel(status),
          tone: _orderTone(status),
          icon: _orderIcon(status),
        );
        final details = TextButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('فتح'),
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    statusBadge,
                    Text(
                      _adminMoney(row['total_lyd']),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _formatAdminDate(row['created_at']),
                      style: const TextStyle(
                        color: AdminColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: details,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(flex: 3, child: identity),
              SizedBox(
                width: 200,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: statusBadge,
                ),
              ),
              Expanded(
                child: Text(
                  _adminMoney(row['total_lyd']),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  _formatAdminDate(row['created_at']),
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              details,
            ],
          ),
        );
      },
    );
  }
}

class _ActionAlert extends StatelessWidget {
  const _ActionAlert({
    required this.amount,
    required this.onPressed,
    super.key,
  });

  final double amount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
    decoration: BoxDecoration(
      color: AdminColors.successSoft,
      border: Border.all(color: AdminColors.success.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final message = Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AdminColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'عمولات مستحقة للدفع: ${amount.toStringAsFixed(0)} د.ل',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
        final action = TextButton.icon(
          key: const ValueKey('admin-dashboard-open-sports-codes'),
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('عرض الرموز'),
        );
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              message,
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: message),
            const SizedBox(width: 16),
            action,
          ],
        );
      },
    ),
  );
}

class _Products extends StatefulWidget {
  const _Products({required this.service, required this.onChanged, super.key});
  final AdminService service;
  final VoidCallback onChanged;
  @override
  State<_Products> createState() => _ProductsState();
}

class _ProductsState extends State<_Products> {
  String query = '';
  String filter = 'all';
  bool _backfillingProductImages = false;
  int _backfillCompleted = 0;
  int _backfillTotal = 0;
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.service.products();
  }

  Future<void> _refreshProductsAfterDelete() async {
    final nextProducts = widget.service.products();
    setState(() => _productsFuture = nextProducts);
    await nextProducts;
  }

  Future<void> _runTemporaryProductImageBackfill() async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'إنشاء مشتقات صور المنتجات',
      message:
          'سيتم إنشاء ملفات WebP المصغرة وملفات Hero المفقودة فقط. قد تستغرق العملية عدة دقائق.',
      confirmLabel: 'بدء العملية',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _backfillingProductImages = true;
      _backfillCompleted = 0;
      _backfillTotal = 0;
    });
    try {
      final result = await widget.service.backfillProductImageThumbnails(
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _backfillCompleted = completed;
            _backfillTotal = total;
          });
        },
      );
      if (!mounted) return;
      showAdminMessage(
        context,
        'اكتملت العملية: ${result.created} تم إنشاؤها، ${result.skipped} موجودة مسبقًا، ${result.failed} تعذّر إنشاؤها.',
        error: result.failed > 0,
      );
    } catch (_) {
      if (mounted) {
        showAdminMessage(
          context,
          'تعذّر إكمال إنشاء مشتقات الصور.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _backfillingProductImages = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _productsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const _ErrorState(message: 'تعذر تحميل المنتجات.');
      }
      final rows = snapshot.data!.where(_matches).toList();
      return _AdminContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'المنتجات',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة منتج'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 310,
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    onChanged: (value) => setState(() => query = value),
                    decoration: adminRtlInputDecoration(
                      const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'بحث بالاسم أو التصنيف',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    alignment: AlignmentDirectional.centerStart,
                    initialValue: filter,
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: adminRtlDropdownItem('كل المنتجات'),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: adminRtlDropdownItem('النشطة'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: adminRtlDropdownItem('المتوقفة'),
                      ),
                      DropdownMenuItem(
                        value: 'stock',
                        child: adminRtlDropdownItem('متوفرة'),
                      ),
                      DropdownMenuItem(
                        value: 'out',
                        child: adminRtlDropdownItem('نفدت'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => filter = value ?? 'all'),
                    decoration: adminRtlInputDecoration(
                      const InputDecoration(labelText: 'تصفية'),
                    ),
                  ),
                ),
                if (_temporaryProductImageBackfillEnabled)
                  OutlinedButton.icon(
                    onPressed: _backfillingProductImages
                        ? null
                        : _runTemporaryProductImageBackfill,
                    icon: _backfillingProductImages
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _backfillingProductImages && _backfillTotal > 0
                          ? '$_backfillCompleted / $_backfillTotal'
                          : 'إنشاء مشتقات صور المنتجات',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (rows.isEmpty)
              const _EmptyState(message: 'لا توجد منتجات مطابقة.')
            else
              ...rows.map(
                (row) => _ProductRow(
                  row: row,
                  service: widget.service,
                  onChanged: widget.onChanged,
                  onDeleted: _refreshProductsAfterDelete,
                  onEdit: () => _edit(row),
                ),
              ),
          ],
        ),
      );
    },
  );

  bool _matches(Map<String, dynamic> row) {
    final stock = _visibleProductStock(row);
    final category = row['categories'] is Map
        ? '${(row['categories'] as Map)['name_ar'] ?? ''}'
        : '';
    final text = '${row['name_ar'] ?? ''} $category'.toLowerCase();
    return (query.trim().isEmpty ||
            text.contains(query.trim().toLowerCase())) &&
        switch (filter) {
          'active' => row['active'] == true,
          'inactive' => row['active'] != true,
          'stock' => stock > 0,
          'out' => stock == 0,
          _ => true,
        };
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    try {
      final categories = await widget.service.categories();
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _ProductEditor(
          service: widget.service,
          categories: categories,
          existing: row,
          onSaved: widget.onChanged,
        ),
      );
      if (saved == true && mounted) {
        showAdminMessage(context, 'تم حفظ المنتج بنجاح.');
      }
    } catch (_) {
      if (mounted) {
        showAdminMessage(context, 'تعذر تحميل نموذج المنتج.', error: true);
      }
    }
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.row,
    required this.service,
    required this.onChanged,
    required this.onDeleted,
    required this.onEdit,
  });
  final Map<String, dynamic> row;
  final AdminService service;
  final Future<void> Function() onDeleted;
  final VoidCallback onChanged, onEdit;
  @override
  Widget build(BuildContext context) {
    final stock = _visibleProductStock(row);
    final image = _coverImage(row['product_images']);
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (image != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: SafeProductImage(
                url: image,
                width: 52,
                height: 62,
                fit: BoxFit.cover,
                fallback: const Icon(Icons.image_outlined),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['name_ar'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_category(row)}  ·  ${_gender(row['gender'] as String?)}  ·  ${row['price_lyd'] ?? 0} د.ل',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  children: [
                    AdminStatusBadge(
                      label: row['active'] == true ? 'نشط' : 'متوقف',
                      tone: row['active'] == true
                          ? AdminStatusTone.good
                          : AdminStatusTone.neutral,
                    ),
                    AdminStatusBadge(
                      label: 'المخزون: $stock',
                      tone: stock == 0
                          ? AdminStatusTone.danger
                          : stock <= 3
                          ? AdminStatusTone.warning
                          : AdminStatusTone.good,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل المنتج',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'تفعيل أو إيقاف',
            onPressed: () async {
              await service.setProductActive(
                row['id'] as String,
                row['active'] != true,
              );
              onChanged();
            },
            icon: const Icon(Icons.power_settings_new),
          ),
          IconButton(
            tooltip: 'حذف المنتج',
            onPressed: () async {
              final okay = await confirmAdminAction(
                context,
                title: 'حذف المنتج',
                message:
                    'سيتم حذف المنتج من المتجر والمخزون الحالي، مع الاحتفاظ بالطلبات السابقة وسجل المبيعات.',
                confirmLabel: 'حذف',
              );
              if (!context.mounted) return;
              if (okay) {
                try {
                  final deleteResult = await service.deleteProduct(
                    row['id'] as String,
                  );
                  if (!context.mounted) return;
                  try {
                    await onDeleted();
                    if (context.mounted) {
                      onChanged();
                      showAdminMessage(
                        context,
                        deleteResult.storageCleanupSucceeded
                            ? 'تم حذف المنتج.'
                            : 'تم حذف المنتج، لكن تعذر حذف بعض ملفات الصور من التخزين.',
                        error: !deleteResult.storageCleanupSucceeded,
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      showAdminMessage(
                        context,
                        'تم حذف المنتج، لكن تعذر تحديث القائمة. حاول إعادة التحميل.',
                        error: true,
                      );
                    }
                  }
                } on ProductHasActiveOrdersException {
                  if (context.mounted) {
                    showAdminMessage(
                      context,
                      'لا يمكن حذف المنتج لوجود طلبات نشطة قيد الانتظار أو التأكيد أو التجهيز. أكمل هذه الطلبات أو ألغها أولًا.',
                      error: true,
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    showAdminMessage(
                      context,
                      'تعذر حذف المنتج. لم يتم تغيير قائمة المنتجات.',
                      error: true,
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
          ),
        ],
      ),
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({
    required this.service,
    required this.categories,
    required this.existing,
    required this.onSaved,
  });
  final AdminService service;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ColorDraft {
  _ColorDraft({
    this.id,
    required this.name,
    this.hexCode = '',
    this.active = true,
    this.adoptLegacyVariants = false,
  });

  String? id;
  String name;
  String hexCode;
  bool active;
  bool adoptLegacyVariants;
  final existingImages = <Map<String, dynamic>>[];
  final pendingImages = <PlatformFile>[];
  final sizes = <String, int>{};
  final variantIds = <String, String?>{};
}

class _ProductEditorState extends State<_ProductEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, description, price, customSize;
  final sizes = <String, int>{};
  final variantIds = <String, String?>{};
  final colors = <_ColorDraft>[];
  final hexControllers = <_ColorDraft, TextEditingController>{};
  final images = <PlatformFile>[];
  final existingImages = <Map<String, dynamic>>[];
  String? categoryId;
  String gender = 'unisex';
  String badge = '';
  bool active = true, saving = false;
  static const allowedSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
  static const commonColorHexes = [
    '#000000',
    '#FFFFFF',
    '#808080',
    '#C62828',
    '#1565C0',
    '#2E7D32',
    '#F9A825',
    '#EF6C00',
    '#795548',
    '#D7CCC8',
    '#1A237E',
  ];

  @override
  void initState() {
    super.initState();
    final row = widget.existing;
    name = TextEditingController(text: row?['name_ar'] as String? ?? '');
    description = TextEditingController(
      text: row?['description_ar'] as String? ?? '',
    );
    price = TextEditingController(text: '${row?['price_lyd'] ?? ''}');
    customSize = TextEditingController();
    categoryId = row?['category_id'] as String?;
    gender = row?['gender'] as String? ?? 'unisex';
    badge = row?['badge'] as String? ?? '';
    active = row?['active'] as bool? ?? true;
    for (final raw in row?['product_colors'] as List<dynamic>? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      colors.add(
        _ColorDraft(
          id: item['id'] as String?,
          name: item['name_ar'] as String? ?? '',
          hexCode: item['hex_code'] as String? ?? '',
          active: item['active'] as bool? ?? true,
        ),
      );
    }
    for (final raw in row?['product_images'] as List<dynamic>? ?? []) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final colorId = item['color_id'] as String?;
      final color = colors.where((entry) => entry.id == colorId).firstOrNull;
      if (color != null) {
        color.existingImages.add(item);
      } else {
        existingImages.add(item);
      }
    }
    for (final raw in row?['product_variants'] as List<dynamic>? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      final size = item['size'] as String? ?? '';
      final colorId = item['color_id'] as String?;
      final color = colors.where((entry) => entry.id == colorId).firstOrNull;
      if (size.isNotEmpty && color != null) {
        color.sizes[size] = (item['stock_quantity'] as num?)?.toInt() ?? 0;
        color.variantIds[size] = item['id'] as String?;
      } else if (size.isNotEmpty) {
        sizes[size] = (item['stock_quantity'] as num?)?.toInt() ?? 0;
        variantIds[size] = item['id'] as String?;
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    customSize.dispose();
    for (final controller in hexControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      title: const AdminDialogHeader(title: 'معلومات المنتج'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminSectionCard(
                  title: 'بيانات المنتج',
                  framed: false,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(labelText: 'اسم المنتج *'),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'يرجى إدخال اسم المنتج.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: description,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 3,
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(labelText: 'الوصف'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: price,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(labelText: 'السعر بالدينار *'),
                        ),
                        validator: (value) =>
                            double.tryParse(value ?? '') == null ||
                                double.parse(value!) <= 0
                            ? 'يرجى إدخال سعر صحيح.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        alignment: AlignmentDirectional.centerStart,
                        initialValue:
                            widget.categories.any(
                              (item) => item['id'] == categoryId,
                            )
                            ? categoryId
                            : null,
                        items: widget.categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['id'] as String,
                                child: adminRtlDropdownItem(
                                  item['name_ar'] as String? ?? '',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => categoryId = value),
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(labelText: 'التصنيف *'),
                        ),
                        validator: (value) =>
                            value == null ? 'يرجى اختيار التصنيف.' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        alignment: AlignmentDirectional.centerStart,
                        initialValue: gender,
                        items: [
                          DropdownMenuItem(
                            value: 'men',
                            child: adminRtlDropdownItem('رجال'),
                          ),
                          DropdownMenuItem(
                            value: 'women',
                            child: adminRtlDropdownItem('نساء'),
                          ),
                          DropdownMenuItem(
                            value: 'unisex',
                            child: adminRtlDropdownItem('للجنسين'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => gender = value ?? 'unisex'),
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(labelText: 'الجنس'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        alignment: AlignmentDirectional.centerStart,
                        initialValue:
                            const ['', 'new', 'rare', 'limited'].contains(badge)
                            ? badge
                            : '',
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: adminRtlDropdownItem('تلقائي حسب المخزون'),
                          ),
                          DropdownMenuItem(
                            value: 'new',
                            child: adminRtlDropdownItem('جديد'),
                          ),
                          DropdownMenuItem(
                            value: 'rare',
                            child: adminRtlDropdownItem('نادر'),
                          ),
                          DropdownMenuItem(
                            value: 'limited',
                            child: adminRtlDropdownItem('كمية محدودة'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => badge = value ?? ''),
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(
                            labelText: 'العنوان الظاهر على الصورة',
                            helperText: 'اتركه تلقائيًا لعرض حالة المخزون.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (colors.isEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : _addColor,
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('تفعيل وإدارة الألوان'),
                    ),
                  ),
                if (colors.isNotEmpty) ...[
                  AdminSectionCard(
                    title: 'الألوان',
                    framed: false,
                    subtitle: 'كل لون يملك مخزوناً مستقلاً حسب المقاس.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...colors.asMap().entries.map(
                          (entry) => _colorCard(entry.key, entry.value),
                        ),
                        OutlinedButton.icon(
                          onPressed: saving ? null : _addColor,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة لون'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                AdminSectionCard(
                  title: 'الصور',
                  framed: false,
                  subtitle: 'الصورة الأولى ستكون صورة الغلاف.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: saving ? null : _pickImages,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          images.isEmpty
                              ? 'اختيار الصور'
                              : '${images.length} صور محددة',
                        ),
                      ),
                      if (existingImages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: existingImages.map((image) {
                            final url = image['url'] as String? ?? '';
                            return Stack(
                              children: [
                                SafeProductImage(
                                  url: url,
                                  width: 76,
                                  height: 86,
                                  fit: BoxFit.cover,
                                  fallback: const Icon(Icons.image_outlined),
                                ),
                                PositionedDirectional(
                                  top: 0,
                                  end: 0,
                                  child: IconButton(
                                    tooltip: 'حذف الصورة',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white70,
                                    ),
                                    onPressed: () =>
                                        _removeExistingImage(image),
                                    icon: const Icon(
                                      Icons.close,
                                      color: AdminColors.danger,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      if (images.isNotEmpty)
                        Text(
                          images.map((image) => image.name).join('، '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (colors.isEmpty)
                  AdminSectionCard(
                    title: 'المقاسات والمخزون',
                    framed: false,
                    subtitle:
                        'استخدم أزرار الزيادة والنقصان. المخزون لا ينزل عن صفر.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sizes.isEmpty)
                          const Text(
                            'أضف مقاسًا للبدء.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ...sizes.keys.map(_sizeRow),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                alignment: AlignmentDirectional.centerStart,
                                initialValue:
                                    allowedSizes.contains(customSize.text)
                                    ? customSize.text
                                    : null,
                                items: allowedSizes
                                    .map(
                                      (size) => DropdownMenuItem(
                                        value: size,
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: Text(
                                            size,
                                            textDirection: TextDirection.ltr,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(
                                  () => customSize.text = value ?? '',
                                ),
                                decoration: adminRtlInputDecoration(
                                  const InputDecoration(labelText: 'مقاس جديد'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _addSize,
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة مقاس'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                AdminSectionCard(
                  title: 'الحالة',
                  framed: false,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: saving
                        ? null
                        : (value) => setState(() => active = value),
                    title: Text(
                      active ? 'المنتج نشط ويظهر في المتجر' : 'المنتج متوقف',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
        ),
      ],
    ),
  );
  Widget _sizeRow(String size) {
    final value = sizes[size] ?? 0;
    final tone = value == 0
        ? AdminStatusTone.danger
        : value <= 3
        ? AdminStatusTone.warning
        : AdminStatusTone.good;
    return Container(
      color: canvasColor,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
      child: AdminVariantStockRow(
        sizeLabel: size,
        sizeLabelKey: ValueKey('admin-product-size-$size'),
        value: value,
        statusLabel: value == 0
            ? 'نفد المخزون'
            : value <= 3
            ? 'مخزون منخفض'
            : 'متوفر',
        statusTone: tone,
        onChanged: (next) => setState(() => sizes[size] = next),
        onRemove: () => _removeSize(size),
      ),
    );
  }

  Future<void> _removeExistingImage(
    Map<String, dynamic> image, [
    List<Map<String, dynamic>>? target,
  ]) async {
    final okay = await confirmAdminAction(
      context,
      title: 'حذف الصورة',
      message: 'هل تريد حذف هذه الصورة نهائيًا؟',
      confirmLabel: 'حذف',
    );
    if (!okay) return;
    try {
      await widget.service.removeProductImage(
        image['id'] as String,
        image['storage_path'] as String? ?? '',
        productId: widget.existing?['id'] as String,
      );
      if (mounted) setState(() => (target ?? existingImages).remove(image));
    } catch (_) {
      if (mounted) showAdminMessage(context, 'تعذر حذف الصورة.', error: true);
    }
  }

  Future<void> _pickImages([_ColorDraft? color]) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null && mounted) {
      setState(() {
        if (color == null) {
          images.addAll(result.files);
        } else {
          color.pendingImages.addAll(result.files);
        }
      });
    }
  }

  void _addSize() {
    final size = customSize.text.trim().toUpperCase();
    if (size.isEmpty) {
      showAdminMessage(context, 'اختر مقاسًا أولًا.', error: true);
      return;
    }
    if (sizes.containsKey(size)) {
      showAdminMessage(context, 'هذا المقاس موجود بالفعل.', error: true);
      return;
    }
    setState(() {
      sizes[size] = 0;
      variantIds[size] = null;
      customSize.clear();
    });
  }

  Future<void> _removeSize(String size) async {
    final value = sizes[size] ?? 0;
    if (value > 0 &&
        !await confirmAdminAction(
          context,
          title: 'إزالة المقاس $size',
          message: 'المخزون الحالي: $value. هل تريد الإزالة؟',
          confirmLabel: 'إزالة',
        )) {
      return;
    }
    setState(() {
      sizes.remove(size);
      variantIds.remove(size);
    });
  }

  Future<void> _addColor() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة لون'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.right,
            decoration: adminRtlInputDecoration(
              const InputDecoration(labelText: 'اسم اللون بالعربية'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    final draft = _ColorDraft(
      name: name,
      adoptLegacyVariants: colors.isEmpty && sizes.isNotEmpty,
    );
    if (colors.isEmpty && sizes.isNotEmpty) {
      draft.sizes.addAll(sizes);
      draft.variantIds.addAll(variantIds);
      sizes.clear();
      variantIds.clear();
    }
    setState(() => colors.add(draft));
  }

  Widget _colorCard(int index, _ColorDraft color) {
    final hexController = hexControllers.putIfAbsent(
      color,
      () => TextEditingController(text: color.hexCode),
    );
    final availableSizes = allowedSizes.where(
      (size) => !color.sizes.containsKey(size),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      color: canvasColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: color.name,
                  textAlign: TextAlign.right,
                  onChanged: (value) => color.name = value,
                  decoration: adminRtlInputDecoration(
                    const InputDecoration(labelText: 'اسم اللون *'),
                  ),
                ),
              ),
              Switch(
                value: color.active,
                onChanged: (value) => setState(() => color.active = value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: hexController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  onChanged: (value) => setState(() => color.hexCode = value),
                  validator: (value) {
                    final hex = value?.trim() ?? '';
                    return hex.isEmpty || isValidHexColor(hex)
                        ? null
                        : 'أدخل HEX بصيغة #RRGGBB.';
                  },
                  decoration: adminRtlInputDecoration(
                    const InputDecoration(labelText: 'اللون المرئي (HEX)'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _AdminColorPreview(hexCode: color.hexCode, size: 34),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: commonColorHexes.map((hex) {
              return Tooltip(
                message: hex,
                child: InkWell(
                  onTap: () => _setColorHex(color, hex),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: _AdminColorPreview(hexCode: hex, size: 24),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'صور اللون ${color.name}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (color.existingImages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: color.existingImages
                  .map((image) => _imageTile(image, color.existingImages))
                  .toList(),
            ),
          if (color.pendingImages.isNotEmpty)
            Text(
              color.pendingImages.map((image) => image.name).join('، '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          OutlinedButton.icon(
            onPressed: saving ? null : () => _pickImages(color),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('إضافة صورة للون'),
          ),
          const SizedBox(height: 8),
          ...color.sizes.keys.map((size) => _colorSizeRow(color, size)),
          if (availableSizes.isNotEmpty)
            DropdownButton<String>(
              hint: const Text('إضافة مقاس لهذا اللون'),
              items: availableSizes
                  .map(
                    (size) => DropdownMenuItem(
                      value: size,
                      child: Text(size, textDirection: TextDirection.ltr),
                    ),
                  )
                  .toList(),
              onChanged: (size) {
                if (size == null) return;
                setState(() {
                  color.sizes[size] = 0;
                  color.variantIds[size] = null;
                });
              },
            ),
          if (color.id == null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => colors.removeAt(index)),
                icon: const Icon(Icons.close, color: AdminColors.danger),
                label: const Text('إزالة اللون'),
              ),
            ),
        ],
      ),
    );
  }

  void _setColorHex(_ColorDraft color, String hex) {
    final controller = hexControllers.putIfAbsent(
      color,
      () => TextEditingController(text: color.hexCode),
    );
    controller.value = TextEditingValue(
      text: hex,
      selection: TextSelection.collapsed(offset: hex.length),
    );
    setState(() => color.hexCode = hex);
  }

  Widget _imageTile(
    Map<String, dynamic> image,
    List<Map<String, dynamic>> target,
  ) {
    final url = image['url'] as String? ?? '';
    return Stack(
      children: [
        SafeProductImage(
          url: url,
          width: 76,
          height: 86,
          fit: BoxFit.cover,
          fallback: const Icon(Icons.image_outlined),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: IconButton(
            tooltip: 'حذف الصورة',
            style: IconButton.styleFrom(backgroundColor: Colors.white70),
            onPressed: () => _removeExistingImage(image, target),
            icon: const Icon(Icons.close, color: AdminColors.danger, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _colorSizeRow(_ColorDraft color, String size) {
    final value = color.sizes[size] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AdminVariantStockRow(
        sizeLabel: size,
        sizeLabelKey: ValueKey('admin-color-${color.name}-size-$size'),
        value: value,
        onChanged: (next) => setState(() => color.sizes[size] = next),
        onRemove: () => setState(() {
          color.sizes.remove(size);
          color.variantIds.remove(size);
        }),
      ),
    );
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (sizes.isEmpty && colors.isEmpty) {
      showAdminMessage(context, 'أضف مقاسًا واحدًا على الأقل.', error: true);
      return;
    }
    if (colors.any((color) => color.name.trim().isEmpty)) {
      showAdminMessage(context, 'يجب إدخال اسم كل لون.', error: true);
      return;
    }
    setState(() => saving = true);
    try {
      final variants = colors.isEmpty
          ? sizes.entries
                .map(
                  (entry) => {
                    'id': variantIds[entry.key],
                    'size': entry.key,
                    'stock_quantity': entry.value,
                    'active': true,
                  },
                )
                .toList()
          : [
              for (var colorIndex = 0; colorIndex < colors.length; colorIndex++)
                for (final entry in colors[colorIndex].sizes.entries)
                  {
                    'id': colors[colorIndex].variantIds[entry.key],
                    'color_id': colors[colorIndex].id,
                    'color_index': colorIndex,
                    'size': entry.key,
                    'stock_quantity': entry.value,
                    'active': colors[colorIndex].active,
                  },
            ];
      final colorPayload = colors
          .asMap()
          .entries
          .map(
            (entry) => {
              'id': entry.value.id,
              'name_ar': entry.value.name.trim(),
              'hex_code': entry.value.hexCode.trim().isEmpty
                  ? null
                  : entry.value.hexCode.trim().toUpperCase(),
              'active': entry.value.active,
              'adopt_legacy_variants': entry.value.adoptLegacyVariants,
            },
          )
          .where((color) => (color['name_ar'] as String).isNotEmpty)
          .toList();
      final id = await widget.service.saveProduct(
        id: widget.existing?['id'] as String?,
        nameAr: name.text.trim(),
        descriptionAr: description.text.trim(),
        price: double.parse(price.text),
        categoryId: categoryId,
        gender: gender,
        badge: badge,
        active: active,
        variants: variants,
        colors: colorPayload,
      );
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        if (image.bytes != null) {
          await widget.service.uploadProductImage(
            id,
            image.bytes!,
            image.name,
            cover: i == 0,
            sortOrder: i,
          );
        }
      }
      for (var colorIndex = 0; colorIndex < colors.length; colorIndex++) {
        final colorId = colorPayload[colorIndex]['id'] as String?;
        if (colorId == null) continue;
        final pendingImages = colors[colorIndex].pendingImages;
        for (
          var imageIndex = 0;
          imageIndex < pendingImages.length;
          imageIndex++
        ) {
          final image = pendingImages[imageIndex];
          if (image.bytes != null) {
            await widget.service.uploadProductImage(
              id,
              image.bytes!,
              image.name,
              colorId: colorId,
              sortOrder: imageIndex,
            );
          }
        }
      }
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        showAdminMessage(context, 'حدث خطأ أثناء حفظ المنتج.', error: true);
      }
    }
  }
}

class _AdminColorPreview extends StatelessWidget {
  const _AdminColorPreview({required this.hexCode, this.size = 32});

  final String hexCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hexCode);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? canvasColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: color == null || color.computeLuminance() > .82
              ? lineColor
              : Colors.black12,
        ),
      ),
      child: color == null
          ? const Icon(Icons.palette_outlined, size: 16, color: Colors.black45)
          : null,
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({
    required this.service,
    required this.onChanged,
    super.key,
  });
  final AdminService service;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: service.categories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ErrorState(message: 'تعذر تحميل التصنيفات.');
          }
          final rows = snapshot.data!;
          return _AdminContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'التصنيفات',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة تصنيف'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (rows.isEmpty)
                  const _EmptyState(message: 'لا توجد تصنيفات بعد.')
                else
                  ...rows.map((row) => _row(context, row)),
              ],
            ),
          );
        },
      );
  Widget _row(BuildContext context, Map<String, dynamic> row) => Container(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    child: InkWell(
      onTap: () => _edit(context, row),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['name_ar'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${row['slug'] ?? ''}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          if (row.containsKey('customer_discount_percent'))
            Text(
              'خصم ${(row['customer_discount_percent'] as num?)?.toStringAsFixed(0) ?? '5'}%  ·  عمولة ${(row['athlete_commission_percent'] as num?)?.toStringAsFixed(0) ?? '5'}%',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          const SizedBox(width: 12),
          AdminStatusBadge(
            label: row['active'] == true ? 'نشط' : 'متوقف',
            tone: row['active'] == true
                ? AdminStatusTone.good
                : AdminStatusTone.neutral,
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: () => _edit(context, row),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'تفعيل أو إيقاف',
            onPressed: () async {
              await service.saveCategory(
                id: row['id'] as String,
                nameAr: row['name_ar'] as String,
                slug: row['slug'] as String,
                active: row['active'] != true,
              );
              onChanged();
            },
            icon: const Icon(Icons.power_settings_new),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: () async {
              final okay = await confirmAdminAction(
                context,
                title: 'حذف التصنيف',
                message: 'لا يمكن حذف تصنيف مرتبط بمنتجات.',
                confirmLabel: 'حذف',
              );
              if (!context.mounted) return;
              if (okay) {
                try {
                  await service.deleteCategory(row['id'] as String);
                  if (!context.mounted) return;
                  onChanged();
                } catch (_) {
                  showAdminMessage(
                    context,
                    'تعذر حذف التصنيف المستخدم.',
                    error: true,
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
          ),
        ],
      ),
    ),
  );
  Future<void> _edit(BuildContext context, [Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?['name_ar'] as String? ?? '');
    final slug = TextEditingController(text: row?['slug'] as String? ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: AdminDialogHeader(
            title: row == null ? 'إضافة تصنيف' : 'تعديل التصنيف',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: adminRtlInputDecoration(
                  const InputDecoration(labelText: 'اسم التصنيف'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: slug,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: adminRtlInputDecoration(
                  const InputDecoration(labelText: 'المعرّف'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await service.saveCategory(
                  id: row?['id'] as String?,
                  nameAr: name.text.trim(),
                  slug: slug.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                onChanged();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    slug.dispose();
  }
}

class _Inventory extends StatefulWidget {
  const _Inventory({required this.service, required this.onChanged, super.key});
  final AdminService service;
  final VoidCallback onChanged;
  @override
  State<_Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<_Inventory> {
  String query = '';
  String filter = 'all';
  late Future<List<Map<String, dynamic>>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = widget.service.inventory();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ErrorState(message: 'تعذر تحميل المخزون.');
          }
          final rows = snapshot.data!.where(_matches).toList();
          return _AdminContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'المخزون',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        onChanged: (value) => setState(() => query = value),
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'بحث بالمنتج',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        alignment: AlignmentDirectional.centerStart,
                        initialValue: filter,
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: adminRtlDropdownItem('كل الحالات'),
                          ),
                          DropdownMenuItem(
                            value: 'in',
                            child: adminRtlDropdownItem('متوفر'),
                          ),
                          DropdownMenuItem(
                            value: 'low',
                            child: adminRtlDropdownItem('مخزون منخفض'),
                          ),
                          DropdownMenuItem(
                            value: 'out',
                            child: adminRtlDropdownItem('نفد المخزون'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => filter = value ?? 'all'),
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(labelText: 'تصفية'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (rows.isEmpty)
                  const _EmptyState(message: 'لا توجد نتائج.')
                else
                  ...rows.map(_inventoryRow),
              ],
            ),
          );
        },
      );
  bool _matches(Map<String, dynamic> row) {
    final product = row['products'] is Map ? row['products'] as Map : {};
    final name = '${product['name_ar'] ?? ''}'.toLowerCase();
    final stock = (row['stock_quantity'] as num?)?.toInt() ?? 0;
    return (query.isEmpty || name.contains(query.toLowerCase())) &&
        switch (filter) {
          'in' => stock > 3,
          'low' => stock > 0 && stock <= 3,
          'out' => stock == 0,
          _ => true,
        };
  }

  Widget _inventoryRow(Map<String, dynamic> row) {
    final product = row['products'] is Map ? row['products'] as Map : {};
    final stock = (row['stock_quantity'] as num?)?.toInt() ?? 0;
    final image = _coverImage(product['product_images']);
    final tone = stock == 0
        ? AdminStatusTone.danger
        : stock <= 3
        ? AdminStatusTone.warning
        : AdminStatusTone.good;
    final statusLabel = stock == 0
        ? 'نفد المخزون'
        : stock <= 3
        ? 'مخزون منخفض'
        : 'متوفر';
    final color = row['product_colors'] as Map?;
    final colorName = color?['name_ar'] as String?;
    final productName = '${product['name_ar'] ?? 'منتج'}';
    final sizeKey = ValueKey('admin-inventory-size-${row['id']}');

    Widget details({required bool includeStatus}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          colorName == null ? productName : '$productName  ·  اللون $colorName',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'المقاس: ${row['size'] ?? ''}',
          key: sizeKey,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (includeStatus) ...[
          const SizedBox(height: 6),
          AdminStatusBadge(label: statusLabel, tone: tone),
        ],
      ],
    );

    final stepper = StockStepper(
      value: stock,
      compact: true,
      onChanged: (value) async {
        try {
          await widget.service.setStock(row['id'] as String, value);
          if (mounted) {
            setState(() => row['stock_quantity'] = value);
            showAdminMessage(context, 'تم تحديث المخزون.');
          }
        } catch (_) {
          if (mounted) {
            showAdminMessage(context, 'تعذر تحديث المخزون.', error: true);
          }
        }
      },
    );

    Widget? thumbnail;
    if (image != null) {
      thumbnail = Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: SafeProductImage(
          url: image,
          width: 48,
          height: 56,
          fit: BoxFit.cover,
          fallback: const Icon(Icons.image_outlined),
        ),
      );
    }

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?thumbnail,
                    Expanded(child: details(includeStatus: false)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AdminStatusBadge(label: statusLabel, tone: tone),
                    const Spacer(),
                    stepper,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              ?thumbnail,
              Expanded(child: details(includeStatus: true)),
              const SizedBox(width: 12),
              stepper,
            ],
          );
        },
      ),
    );
  }
}

List<Map<String, dynamic>> filterAdminOrders(
  Iterable<Map<String, dynamic>> source, {
  required String query,
  required AdminOrderScope scope,
  required AdminOrderDateRange dateRange,
  DateTime? now,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final reference = (now ?? DateTime.now()).toLocal();
  final today = DateTime(reference.year, reference.month, reference.day);
  final start = switch (dateRange) {
    AdminOrderDateRange.all => null,
    AdminOrderDateRange.today => today,
    AdminOrderDateRange.last7Days => today.subtract(const Duration(days: 6)),
    AdminOrderDateRange.last30Days => today.subtract(const Duration(days: 29)),
  };

  return source
      .where((row) {
        final status = row['status'] as String?;
        final matchesScope = switch (scope) {
          AdminOrderScope.active => adminActiveOrderStatuses.contains(status),
          AdminOrderScope.delivered => status == 'delivered',
          AdminOrderScope.cancelled => status == 'cancelled',
          AdminOrderScope.all => true,
        };
        if (!matchesScope) return false;

        if (normalizedQuery.isNotEmpty) {
          final searchable =
              '${row['order_number'] ?? ''} ${row['customer_name'] ?? ''} ${row['phone'] ?? ''}'
                  .toLowerCase();
          if (!searchable.contains(normalizedQuery)) return false;
        }

        if (start != null) {
          final createdAt = DateTime.tryParse(
            row['created_at'] as String? ?? '',
          )?.toLocal();
          if (createdAt == null || createdAt.isBefore(start)) return false;
        }
        return true;
      })
      .toList(growable: false);
}

class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({
    required this.service,
    required this.onChanged,
    this.initialScope = AdminOrderScope.active,
    this.initialQuery = '',
    super.key,
  });

  final AdminOperationsService service;
  final VoidCallback onChanged;
  final AdminOrderScope initialScope;
  final String initialQuery;

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  late String query;
  late AdminOrderScope scope;
  AdminOrderDateRange dateRange = AdminOrderDateRange.all;
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  late final TextEditingController _searchController;
  final Set<String> _updatingOrderIds = {};

  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    scope = widget.initialScope;
    _searchController = TextEditingController(text: query);
    _ordersFuture = widget.service.orders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _ordersFuture = widget.service.orders();
  });

  void _resetFilters() => setState(() {
    query = '';
    scope = AdminOrderScope.active;
    dateRange = AdminOrderDateRange.all;
    _searchController.clear();
  });

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _AdminLoadingState(
              key: ValueKey('admin-orders-loading'),
              label: 'جارٍ تحميل الطلبات...',
            );
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: 'تعذر تحميل الطلبات. تحقق من الاتصال وحاول مجددًا.',
              onRetry: _reload,
            );
          }
          final rows = filterAdminOrders(
            snapshot.data!,
            query: query,
            scope: scope,
            dateRange: dateRange,
          );
          return _AdminContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سجل الطلبات',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ابحث في الطلبات النشطة والمكتملة والملغاة دون تغيير السجل.',
                  style: TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                AdminSectionCard(
                  title: 'البحث والتصفية',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const ValueKey('admin-orders-search'),
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        onChanged: (value) => setState(() => query = value),
                        decoration: adminRtlInputDecoration(
                          const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'بحث في الطلبات',
                            hintText: 'رقم الطلب أو العميل أو الهاتف',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AdminOrderScope.values
                            .map(
                              (item) => ChoiceChip(
                                key: ValueKey('admin-order-scope-${item.name}'),
                                label: Text(_adminOrderScopeLabel(item)),
                                selected: scope == item,
                                onSelected: (_) => setState(() => scope = item),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            key: const ValueKey('admin-orders-date-filter'),
                            width: 220,
                            child: DropdownButtonFormField<AdminOrderDateRange>(
                              key: ValueKey(
                                'admin-orders-date-filter-${dateRange.name}',
                              ),
                              initialValue: dateRange,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الإنشاء',
                                prefixIcon: Icon(Icons.date_range_outlined),
                              ),
                              items: AdminOrderDateRange.values
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: adminRtlDropdownItem(
                                        _adminOrderDateLabel(item),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => dateRange = value);
                                }
                              },
                            ),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('admin-orders-reset-filters'),
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('إعادة ضبط الفلاتر'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'النتائج: ${rows.length}',
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  _EmptyState(
                    key: const ValueKey('admin-orders-empty'),
                    message:
                        scope == AdminOrderScope.active &&
                            query.isEmpty &&
                            dateRange == AdminOrderDateRange.all
                        ? 'لا توجد طلبات تحتاج متابعة حاليًا.'
                        : 'لا توجد طلبات مطابقة للفلاتر الحالية.',
                    positive: scope == AdminOrderScope.active,
                  )
                else
                  ...rows.map(_orderRow),
              ],
            ),
          );
        },
      );
  Widget _orderRow(Map<String, dynamic> row) {
    final status = orderStatusFromString(row['status'] as String? ?? 'pending');
    final id = row['id'] as String? ?? '';
    final updating = _updatingOrderIds.contains(id);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${row['order_number'] ?? ''} · ${row['customer_name'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          '${row['phone'] ?? ''} · ${row['city'] ?? ''}',
          style: const TextStyle(
            color: AdminColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
    final badge = AdminStatusBadge(
      label: orderStatusLabel(status),
      tone: _orderTone(status),
      icon: _orderIcon(status),
    );
    final statusControl = SizedBox(
      width: 180,
      height: 48,
      child: DropdownButton<String>(
        isExpanded: true,
        alignment: AlignmentDirectional.centerStart,
        value: status.name,
        items: OrderStatus.values
            .map(
              (item) => DropdownMenuItem(
                value: item.name,
                child: adminRtlDropdownItem(orderStatusLabel(item)),
              ),
            )
            .toList(),
        onChanged: updating ? null : (value) => _updateOrderStatus(row, value),
      ),
    );
    final openButton = OutlinedButton.icon(
      onPressed: () => _details(row),
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('فتح'),
    );

    return Container(
      key: ValueKey('admin-order-row-$id'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    badge,
                    Text(
                      _adminMoney(row['total_lyd']),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _formatAdminDate(row['created_at']),
                      style: const TextStyle(
                        color: AdminColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [statusControl, openButton],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              SizedBox(
                width: 200,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: badge,
                ),
              ),
              Expanded(
                child: Text(
                  _adminMoney(row['total_lyd']),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  _formatAdminDate(row['created_at']),
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              statusControl,
              const SizedBox(width: 10),
              openButton,
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(
    Map<String, dynamic> row,
    String? value,
  ) async {
    if (value == null || value == row['status']) return;
    final id = row['id'] as String?;
    if (id == null || _updatingOrderIds.contains(id)) return;
    setState(() => _updatingOrderIds.add(id));
    try {
      await widget.service.updateOrderStatus(id, value);
      widget.onChanged();
      if (mounted) {
        showAdminMessage(context, 'تم تحديث حالة الطلب.');
        _reload();
      }
    } catch (_) {
      if (mounted) {
        showAdminMessage(
          context,
          'تعذر تحديث الحالة. راجع تسلسل الحالة وتوفر المخزون.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderIds.remove(id));
    }
  }

  Future<void> _details(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: AdminDialogHeader(
            title: 'تفاصيل ${row['order_number'] ?? ''}',
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'بيانات العميل',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${row['customer_name'] ?? ''}\n${row['phone'] ?? ''}\n${row['city'] ?? ''}\n${row['address'] ?? ''}',
                  ),
                  const Divider(height: 28),
                  const Text(
                    'المنتجات',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...(row['order_items'] as List<dynamic>? ?? []).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${item['product_name_snapshot'] ?? ''}${item['color_name_ar'] == null ? '' : '  ·  اللون: ${item['color_name_ar']}'}  ·  ${item['selected_size'] ?? ''}  × ${item['quantity'] ?? 0}  ·  ${item['line_total_lyd'] ?? 0} د.ل',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نسبة الخصم: ${(row['customer_discount_percent'] as num?)?.toStringAsFixed(2) ?? '0'}%  ·  نسبة العمولة: ${(row['athlete_commission_percent'] as num?)?.toStringAsFixed(2) ?? '0'}%  ·  مبلغ العمولة: ${(row['athlete_commission_amount_lyd'] as num?)?.toStringAsFixed(2) ?? '0'} د.ل  ·  الحالة: ${row['commission_status'] ?? 'void'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (row['commission_status'] == 'approved')
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () async {
                          await widget.service.updateCommissionStatus(
                            row['id'] as String,
                            'paid',
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          widget.onChanged();
                        },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('تسجيل العمولة كمدفوعة'),
                      ),
                    ),
                  const Divider(height: 28),
                  Text(
                    'المجموع الفرعي: ${row['subtotal_lyd'] ?? 0} د.ل\nالخصم: ${row['discount_amount_lyd'] ?? 0} د.ل\nالإجمالي: ${row['total_lyd'] ?? 0} د.ل',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDiscountsView extends StatefulWidget {
  const AdminDiscountsView({required this.service, super.key});
  final AdminDiscountCodesService service;

  @override
  State<AdminDiscountsView> createState() => _AdminDiscountsViewState();
}

class _AdminDiscountsViewState extends State<AdminDiscountsView> {
  late Future<List<Map<String, dynamic>>> _codesFuture;
  late Future<List<PayableCommissionGroup>> _payablesFuture;
  List<PayableCommissionGroup> _payableGroups = const [];
  Map<String, dynamic>? _selectedRow;
  Future<DiscountPerformance>? _performanceFuture;
  final Set<String> _pendingCodeIds = {};
  final Set<String> _hiddenCodeIds = {};

  @override
  void initState() {
    super.initState();
    _codesFuture = widget.service.discounts();
    _payablesFuture = _loadPayables();
  }

  Future<List<PayableCommissionGroup>> _loadPayables() async {
    final groups = await widget.service.payableCommissions();
    _payableGroups = groups;
    return groups;
  }

  void _retryPayables() => setState(() {
    _payablesFuture = _loadPayables();
  });

  void _openDetails(Map<String, dynamic> row) {
    final code = row['code'] as String? ?? '';
    setState(() {
      _selectedRow = row;
      _performanceFuture = widget.service.discountPerformance(code);
    });
  }

  Future<void> _reload() async {
    final selectedId = _selectedRow?['id'];
    final codesRequest = widget.service.discounts();
    final payablesRequest = widget.service.payableCommissions();
    final rows = await codesRequest;
    final payables = await payablesRequest;
    if (!mounted) return;
    final refreshed = rows.where((row) => row['id'] == selectedId).firstOrNull;
    final refreshedCode = refreshed?['code'] as String?;
    setState(() {
      _codesFuture = Future.value(rows);
      _payableGroups = payables;
      _payablesFuture = Future.value(payables);
      _hiddenCodeIds.clear();
      _selectedRow = selectedId == null ? null : refreshed;
      _performanceFuture = refreshedCode == null
          ? null
          : widget.service.discountPerformance(refreshedCode);
    });
  }

  Future<bool> _refreshAfterWrite({required String operation}) async {
    try {
      await _reload();
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Admin discount refresh RPC failed after $operation '
        '(admin_list_discount_codes): $error\n$stackTrace',
      );
      if (mounted) {
        showAdminMessage(
          context,
          adminDiscountRefreshFailureMessage,
          error: true,
        );
      }
      return false;
    }
  }

  bool _beginCodeAction(String id) {
    if (_pendingCodeIds.contains(id)) return false;
    setState(() => _pendingCodeIds.add(id));
    return true;
  }

  void _endCodeAction(String id) {
    if (mounted) setState(() => _pendingCodeIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRow;
    if (selected != null) return _details(context, selected);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _codesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _ErrorState(message: 'تعذر تحميل الرموز.');
        }
        final rows = (snapshot.data ?? const <Map<String, dynamic>>[])
            .where((row) => !_hiddenCodeIds.contains(row['id']))
            .toList();
        return _AdminContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'الرموز الرياضية',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _add(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة رمز'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<PayableCommissionGroup>>(
                future: _payablesFuture,
                builder: (context, payableSnapshot) {
                  if (payableSnapshot.connectionState != ConnectionState.done) {
                    return const _PayableCommissionLoading();
                  }
                  if (payableSnapshot.hasError) {
                    return _PayableCommissionError(onRetry: _retryPayables);
                  }
                  final groups = payableSnapshot.data ?? const [];
                  if (groups.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _PayableCommissionsSection(
                      groups: groups,
                      onInspect: _inspectPayable,
                      onPay: (group) => _payInfluencer(
                        context,
                        influencerId: group.influencerId,
                        amount: group.amount,
                      ),
                    ),
                  );
                },
              ),
              if (rows.isEmpty)
                const _EmptyState(message: 'لا توجد رموز رياضية بعد.'),
              ...rows.map((row) => _row(context, row)),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> row) {
    final id = row['id'] as String;
    final code = row['code'] as String? ?? '';
    final athlete = (row['influencers'] as Map?)?['name'] as String?;
    final customer =
        (row['customer_discount_percent'] as num?)?.toStringAsFixed(0) ?? '0';
    final commission =
        (row['athlete_commission_percent'] as num?)?.toStringAsFixed(0) ?? '0';
    final active = row['active'] == true;
    final pending = _pendingCodeIds.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        key: ValueKey('discount-code-row-$id'),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _openDetails(row),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            code,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            athlete?.trim().isNotEmpty == true
                                ? athlete!
                                : 'بدون مسوق',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'خصم $customer%  ·  عمولة $commission%',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AdminStatusBadge(
                      key: ValueKey('discount-code-status-$id'),
                      label: active ? 'نشط' : 'متوقف',
                      tone: active
                          ? AdminStatusTone.good
                          : AdminStatusTone.neutral,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
              child: Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    key: ValueKey('discount-code-edit-$id'),
                    onPressed: pending ? null : () => _add(context, row),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل'),
                  ),
                  IconButton(
                    key: ValueKey('discount-code-toggle-$id'),
                    tooltip: 'تفعيل أو إيقاف',
                    onPressed: pending ? null : () => _toggle(row),
                    icon: const Icon(Icons.power_settings_new),
                  ),
                  IconButton(
                    key: ValueKey('discount-code-delete-$id'),
                    tooltip: 'حذف الرمز',
                    onPressed: pending ? null : () => _delete(row),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AdminColors.danger,
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

  Future<void> _toggle(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    if (!_beginCodeAction(id)) return;
    try {
      final active = row['active'] == true;
      try {
        await widget.service.setDiscountActive(id, !active);
      } catch (error, stackTrace) {
        debugPrint('Admin toggle discount write failed: $error\n$stackTrace');
        if (mounted) {
          showAdminMessage(
            context,
            adminDiscountWriteFailureMessage,
            error: true,
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => row['active'] = !active);
      final refreshed = await _refreshAfterWrite(operation: 'toggle');
      if (refreshed && mounted) {
        showAdminMessage(context, 'تم تحديث حالة الرمز.');
      }
    } finally {
      _endCodeAction(id);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final okay = await confirmAdminAction(
      context,
      title: 'حذف الرمز',
      message: 'هل أنت متأكد من حذف رمز الخصم؟',
      confirmLabel: 'حذف',
    );
    if (!okay || !mounted || !_beginCodeAction(id)) return;
    try {
      try {
        await widget.service.deleteDiscount(id);
      } catch (error, stackTrace) {
        debugPrint('Admin delete discount write failed: $error\n$stackTrace');
        if (mounted) {
          showAdminMessage(
            context,
            adminDiscountWriteFailureMessage,
            error: true,
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _hiddenCodeIds.add(id);
        if (_selectedRow?['id'] == id) {
          _selectedRow = null;
          _performanceFuture = null;
        }
      });
      final refreshed = await _refreshAfterWrite(operation: 'delete');
      if (refreshed && mounted) {
        showAdminMessage(context, 'تم حذف الرمز.');
      }
    } finally {
      _endCodeAction(id);
    }
  }

  Widget _details(BuildContext context, Map<String, dynamic> row) {
    final code = row['code'] as String? ?? '';
    final athlete = (row['influencers'] as Map?)?['name'] as String?;
    final active = row['active'] == true;
    return _AdminContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedRow = null;
                  _performanceFuture = null;
                }),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('الرموز الرياضية'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _add(context, row),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'رمز: $code',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          AdminSectionCard(
            title: 'بيانات الرمز',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 680
                    ? 4
                    : constraints.maxWidth > 400
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: columns == 1 ? 4.2 : 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  children: [
                    _InfoMetric(
                      label: 'المسوق',
                      value: athlete?.trim().isNotEmpty == true
                          ? athlete!
                          : 'بدون مسوق',
                    ),
                    _InfoMetric(
                      label: 'خصم العميل',
                      value:
                          '${(row['customer_discount_percent'] as num?)?.toStringAsFixed(2) ?? '0.00'}%',
                    ),
                    _InfoMetric(
                      label: 'نسبة عمولة المسوق',
                      value:
                          '${(row['athlete_commission_percent'] as num?)?.toStringAsFixed(2) ?? '0.00'}%',
                    ),
                    _InfoMetric(
                      label: 'الحالة',
                      value: active ? 'نشط' : 'متوقف',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<DiscountPerformance>(
            future: _performanceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const AdminSectionCard(
                  title: 'أداء الرمز',
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const _ErrorState(message: 'تعذر تحميل أداء الرمز.');
              }
              final performance =
                  snapshot.data ?? const DiscountPerformance.empty();
              return _performance(context, performance);
            },
          ),
        ],
      ),
    );
  }

  Widget _performance(BuildContext context, DiscountPerformance performance) {
    final metrics = [
      _InfoMetric(label: 'عدد الاستخدامات', value: '${performance.uses}'),
      _InfoMetric(label: 'إجمالي المبيعات', value: _lyd(performance.sales)),
      _InfoMetric(
        label: 'إجمالي العمولة',
        value: _lyd(performance.commission.total),
      ),
      _InfoMetric(
        label: 'قيد الانتظار',
        value: _lyd(performance.commission.pending),
      ),
      _InfoMetric(
        label: 'المستحق للدفع',
        value: _lyd(performance.commission.approved),
      ),
      _InfoMetric(
        label: 'تم دفعه سابقًا',
        value: _lyd(performance.commission.paid),
      ),
    ];
    return AdminSectionCard(
      title: 'أداء الرمز',
      subtitle: 'إحصاءات هذا الرمز فقط.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 680
                  ? 3
                  : constraints.maxWidth > 400
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: columns == 1 ? 4.2 : 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
                children: metrics,
              );
            },
          ),
          const SizedBox(height: 18),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed:
                  performance.commission.approved > 0 &&
                      performance.influencerId != null
                  ? () => _payInfluencer(
                      context,
                      influencerId: performance.influencerId!,
                      amount: performance.commission.approved,
                      selectedPerformance: performance,
                    )
                  : null,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('تأكيد دفع المستحقات'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _inspectPayable(PayableCommissionGroup group) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: AdminDialogHeader(title: 'مستحقات ${group.influencerName}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'إجمالي المستحق: ${_lyd(group.amount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final order in group.orders)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.background,
                        border: Border.all(color: AdminColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber.isEmpty
                                      ? 'طلب بدون رقم ظاهر'
                                      : order.orderNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  order.discountCode?.isNotEmpty == true
                                      ? 'الرمز: ${order.discountCode}'
                                      : 'الرمز الأصلي غير متاح',
                                  style: const TextStyle(
                                    color: AdminColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _lyd(order.amount),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payInfluencer(
    BuildContext context, {
    required String influencerId,
    required double amount,
    DiscountPerformance? selectedPerformance,
  }) async {
    if (amount <= 0) return;
    final confirmed = await confirmAdminAction(
      context,
      title: 'تأكيد دفع المستحقات',
      message:
          'سيتم تسجيل مستحقات بقيمة ${_lyd(amount)} كمدفوعة.\nلن يتم حذف سجل العمولات السابقة.',
      confirmLabel: 'تأكيد الدفع',
    );
    if (!confirmed || !context.mounted) return;

    late final Map<String, dynamic> result;
    try {
      result = await widget.service.markInfluencerCommissionsPaid(influencerId);
    } catch (error, stackTrace) {
      debugPrint('Admin payout write failed: $error\n$stackTrace');
      if (context.mounted) {
        showAdminMessage(context, 'تعذر تسجيل الدفع.', error: true);
      }
      return;
    }

    if (!mounted || !context.mounted) return;
    setState(() {
      _payableGroups = _payableGroups
          .where((group) => group.influencerId != influencerId)
          .toList(growable: false);
      _payablesFuture = Future.value(_payableGroups);
      if (selectedPerformance != null) {
        _performanceFuture = Future.value(
          selectedPerformance.withApprovedMarkedPaid(),
        );
      }
    });

    final refreshed = await _refreshAfterWrite(operation: 'payout');
    if (refreshed && context.mounted) {
      final ordersPaid = (result['orders_paid'] as num?)?.toInt() ?? 0;
      final totalPaid =
          (result['total_paid'] as num?)?.toStringAsFixed(0) ?? '0';
      showAdminMessage(
        context,
        'تم تسجيل $ordersPaid طلبات كمدفوعة بقيمة $totalPaid د.ل.',
      );
    }
  }

  Future<void> _add(
    BuildContext dialogContext, [
    Map<String, dynamic>? row,
  ]) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: dialogContext,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _DiscountFormDialog(service: widget.service, existing: row),
      ),
    );
    if (saved == null || !mounted) return;

    if (row != null) {
      setState(() {
        row.addAll(saved);
        if (_selectedRow?['id'] == row['id']) _selectedRow = row;
      });
    }

    final refreshed = await _refreshAfterWrite(
      operation: row == null ? 'create' : 'edit',
    );
    if (refreshed && mounted) {
      showAdminMessage(context, 'تم حفظ الرمز.');
    }
  }
}

class _PayableCommissionsSection extends StatelessWidget {
  const _PayableCommissionsSection({
    required this.groups,
    required this.onInspect,
    required this.onPay,
  });

  final List<PayableCommissionGroup> groups;
  final ValueChanged<PayableCommissionGroup> onInspect;
  final ValueChanged<PayableCommissionGroup> onPay;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    key: const ValueKey('sports-codes-payable-section'),
    title: 'مستحقات تحتاج دفع',
    subtitle:
        'مجمعة حسب الرياضي لأن إجراء الدفع الحالي يسجل جميع مستحقاته المعتمدة دفعة واحدة.',
    child: Column(
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          _PayableCommissionCard(
            group: groups[index],
            onInspect: () => onInspect(groups[index]),
            onPay: () => onPay(groups[index]),
          ),
          if (index != groups.length - 1) const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

class _PayableCommissionCard extends StatelessWidget {
  const _PayableCommissionCard({
    required this.group,
    required this.onInspect,
    required this.onPay,
  });

  final PayableCommissionGroup group;
  final VoidCallback onInspect;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final hasUnavailableCode = group.orders.any(
      (order) => order.discountCode == null || order.discountCode!.isEmpty,
    );
    final codeText = group.codes.isEmpty
        ? 'الرمز الأصلي غير متاح'
        : 'الرموز: ${group.codes.join('، ')}'
              '${hasUnavailableCode ? ' · وبعض الطلبات بلا رمز متاح' : ''}';
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group.influencerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          '$codeText · ${group.orders.length} طلب',
          style: const TextStyle(
            color: AdminColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
    final amount = Semantics(
      label: 'المستحق للدفع ${_lyd(group.amount)}',
      child: Text(
        _lyd(group.amount),
        style: const TextStyle(
          color: AdminColors.success,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: ValueKey('payable-inspect-${group.influencerId}'),
          onPressed: onInspect,
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: const Text('عرض التفاصيل'),
        ),
        FilledButton.icon(
          key: ValueKey('payable-pay-${group.influencerId}'),
          onPressed: onPay,
          icon: const Icon(Icons.payments_outlined, size: 18),
          label: const Text('تأكيد الدفع'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.successSoft,
        border: Border.all(color: AdminColors.success.withValues(alpha: .24)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 10),
                amount,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              amount,
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PayableCommissionLoading extends StatelessWidget {
  const _PayableCommissionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 18),
    child: AdminSectionCard(
      title: 'مستحقات تحتاج دفع',
      child: LinearProgressIndicator(minHeight: 2),
    ),
  );
}

class _PayableCommissionError extends StatelessWidget {
  const _PayableCommissionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: AdminSectionCard(
      title: 'مستحقات تحتاج دفع',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const message = Text(
            'تعذر تحميل المستحقات. قائمة الرموز ما زالت متاحة.',
            style: TextStyle(color: AdminColors.textSecondary),
          );
          final retry = TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
          );
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: retry,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 12),
              retry,
            ],
          );
        },
      ),
    ),
  );
}

class _DiscountFormDialog extends StatefulWidget {
  const _DiscountFormDialog({required this.service, this.existing});
  final AdminDiscountCodesService service;
  final Map<String, dynamic>? existing;

  @override
  State<_DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<_DiscountFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController code;
  late final TextEditingController athlete;
  late final TextEditingController customerPercent;
  late final TextEditingController athletePercent;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final row = widget.existing;
    code = TextEditingController(text: row?['code'] as String? ?? '');
    athlete = TextEditingController(
      text: (row?['influencers'] as Map?)?['name'] as String? ?? '',
    );
    customerPercent = TextEditingController(
      text: ((row?['customer_discount_percent'] as num?) ?? 0).toStringAsFixed(
        2,
      ),
    );
    athletePercent = TextEditingController(
      text: ((row?['athlete_commission_percent'] as num?) ?? 0).toStringAsFixed(
        2,
      ),
    );
  }

  @override
  void dispose() {
    code.dispose();
    athlete.dispose();
    customerPercent.dispose();
    athletePercent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final normalizedCode = code.text.trim().toUpperCase();
      final athleteName = athlete.text.trim();
      final active = widget.existing?['active'] as bool? ?? true;
      final customerRate = double.parse(customerPercent.text);
      final athleteRate = double.parse(athletePercent.text);
      final rawExpiresAt = widget.existing?['expires_at'];
      final expiresAt = rawExpiresAt is DateTime
          ? rawExpiresAt
          : rawExpiresAt is String
          ? DateTime.tryParse(rawExpiresAt)
          : null;
      await widget.service.saveDiscount(
        id: widget.existing?['id'] as String?,
        code: normalizedCode,
        influencerName: athleteName,
        active: active,
        expiresAt: expiresAt,
        customerDiscountPercent: customerRate,
        athleteCommissionPercent: athleteRate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(<String, dynamic>{
        ...?widget.existing,
        'code': normalizedCode,
        'active': active,
        'expires_at': expiresAt?.toIso8601String(),
        'customer_discount_percent': customerRate,
        'athlete_commission_percent': athleteRate,
        'influencers': athleteName.isEmpty ? null : {'name': athleteName},
      });
    } on DuplicateDiscountCodeException catch (error, stackTrace) {
      debugPrint('Admin save discount duplicate: $error\n$stackTrace');
      if (mounted) {
        showAdminMessage(
          context,
          'رمز الخصم موجود بالفعل. استخدم رمزًا مختلفًا.',
          error: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Admin save discount failed: $error\n$stackTrace');
      if (mounted) {
        showAdminMessage(
          context,
          'تعذر حفظ الرمز. تحقق من البيانات وحاول مرة أخرى.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AdminDialogHeader(
      title: widget.existing == null ? 'إضافة رمز' : 'تعديل الرمز',
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('discount-code-athlete-field'),
                controller: athlete,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: adminRtlInputDecoration(
                  const InputDecoration(labelText: 'اسم الرياضي'),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('discount-code-code-field'),
                controller: code,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: adminRtlInputDecoration(
                  const InputDecoration(labelText: 'الرمز'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'يرجى إدخال الرمز.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('discount-code-customer-rate-field'),
                controller: customerPercent,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: adminRtlInputDecoration(
                  const InputDecoration(labelText: 'نسبة خصم الزبون (%)'),
                ),
                validator: _rateValidator,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('discount-code-athlete-rate-field'),
                controller: athletePercent,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: adminRtlInputDecoration(
                  const InputDecoration(labelText: 'نسبة عمولة الرياضي (%)'),
                ),
                validator: _rateValidator,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton.icon(
        key: const ValueKey('discount-code-save'),
        onPressed: saving ? null : _save,
        icon: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
      ),
    ],
  );

  String? _rateValidator(String? value) {
    final rate = double.tryParse(value?.trim() ?? '');
    return rate == null || rate < 0 || rate > 100
        ? 'يجب أن تكون النسبة بين 0 و100.'
        : null;
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    color: canvasColor,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ],
    ),
  );
}

String _lyd(double value) => '${value.toStringAsFixed(0)} د.ل';

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.positive = false, super.key});
  final String message;
  final bool positive;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: positive ? AdminColors.successSoft : AdminColors.surface,
        border: Border.all(
          color: positive
              ? AdminColors.success.withValues(alpha: .22)
              : AdminColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              positive ? Icons.check_circle_outline : Icons.inbox_outlined,
              color: positive ? AdminColors.success : AdminColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.cloud_off_outlined,
              color: AdminColors.danger,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: AdminColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _coverImage(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final items = raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
  final covers = items.where((item) => item['is_cover'] == true).toList();
  final value =
      (covers.isNotEmpty ? covers.first : items.first)['url'] as String?;
  return value == null || value.isEmpty ? null : value;
}

int _visibleProductStock(Map<String, dynamic> row) {
  final activeColors = <String, bool>{};
  for (final raw in row['product_colors'] as List<dynamic>? ?? []) {
    if (raw is Map && raw['id'] is String) {
      activeColors[raw['id'] as String] = raw['active'] == true;
    }
  }
  return (row['product_variants'] as List<dynamic>? ?? []).fold<int>(0, (
    sum,
    raw,
  ) {
    if (raw is! Map || raw['active'] != true) return sum;
    final colorId = raw['color_id'] as String?;
    if (colorId != null && activeColors[colorId] != true) return sum;
    return sum + ((raw['stock_quantity'] as num?)?.toInt() ?? 0);
  });
}

String _category(Map<String, dynamic> row) => row['categories'] is Map
    ? '${(row['categories'] as Map)['name_ar'] ?? 'بدون تصنيف'}'
    : 'بدون تصنيف';
String _gender(String? value) => switch (value) {
  'men' => 'رجال',
  'women' => 'نساء',
  _ => 'للجنسين',
};
AdminStatusTone _orderTone(OrderStatus status) => switch (status) {
  OrderStatus.pending => AdminStatusTone.warning,
  OrderStatus.confirmed || OrderStatus.preparing => AdminStatusTone.good,
  OrderStatus.delivered => AdminStatusTone.neutral,
  OrderStatus.cancelled => AdminStatusTone.danger,
};

IconData _orderIcon(OrderStatus status) => switch (status) {
  OrderStatus.pending => Icons.schedule_outlined,
  OrderStatus.confirmed => Icons.check_circle_outline,
  OrderStatus.preparing => Icons.inventory_2_outlined,
  OrderStatus.delivered => Icons.local_shipping_outlined,
  OrderStatus.cancelled => Icons.cancel_outlined,
};

String _adminOrderScopeLabel(AdminOrderScope scope) => switch (scope) {
  AdminOrderScope.active => 'النشطة',
  AdminOrderScope.delivered => 'تم التوصيل',
  AdminOrderScope.cancelled => 'ملغاة',
  AdminOrderScope.all => 'الكل',
};

String _adminOrderDateLabel(AdminOrderDateRange range) => switch (range) {
  AdminOrderDateRange.all => 'كل التواريخ',
  AdminOrderDateRange.today => 'اليوم',
  AdminOrderDateRange.last7Days => 'آخر 7 أيام',
  AdminOrderDateRange.last30Days => 'آخر 30 يومًا',
};

String _adminMoney(dynamic raw) {
  final value = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
  return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} د.ل';
}

String _formatAdminDate(dynamic raw) {
  final date = DateTime.tryParse('$raw')?.toLocal();
  if (date == null) return 'تاريخ غير متاح';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}/${two(date.month)}/${two(date.day)} · ${two(date.hour)}:${two(date.minute)}';
}
