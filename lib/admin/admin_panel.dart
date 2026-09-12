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
  static const titles = [
    'لوحة التحكم',
    'المنتجات',
    'التصنيفات',
    'المخزون',
    'الطلبات',
    'الرموز الرياضية',
  ];
  void refresh() => setState(() => refreshKey++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        service: widget.service,
        onChanged: refresh,
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
      _Orders(
        service: widget.service,
        onChanged: refresh,
        key: ValueKey(refreshKey),
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
            return Scaffold(
              drawer: mobile
                  ? Drawer(
                      child: _AdminNavigation(
                        index: index,
                        onSelected: (value) {
                          Navigator.pop(context);
                          setState(() => index = value);
                        },
                      ),
                    )
                  : null,
              appBar: AppBar(
                leading: mobile
                    ? Builder(
                        builder: (context) => IconButton(
                          tooltip: 'فتح القائمة',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu),
                        ),
                      )
                    : null,
                title: Text(
                  titles[index],
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                actions: [
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
                      onSelected: (value) => setState(() => index = value),
                    ),
                  Expanded(child: pages[index]),
                ],
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
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: child,
      ),
    ),
  );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.service, required this.onChanged, super.key});
  final AdminService service;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: service.dashboard(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const _ErrorState(message: 'تعذر تحميل لوحة التحكم.');
      }
      final data = snapshot.data!;
      final metrics = [
        ('طلبات اليوم', '${data['orders_today']}', Icons.today_outlined),
        ('قيد الانتظار', '${data['pending']}', Icons.pending_actions),
        ('تم التأكيد', '${data['confirmed']}', Icons.task_alt),
        (
          'المبيعات المؤكدة',
          '${(data['sales'] as num).toStringAsFixed(0)} د.ل',
          Icons.payments_outlined,
        ),
        ('مخزون منخفض', '${data['low_stock']}', Icons.warning_amber_outlined),
        (
          'نفد المخزون',
          '${data['out_of_stock']}',
          Icons.remove_shopping_cart_outlined,
        ),
        (
          'قيد الانتظار - غير مستحق حاليًا',
          '${(data['pending_commissions'] as num).toStringAsFixed(0)} د.ل',
          Icons.account_balance_wallet_outlined,
        ),
        (
          'المستحق حاليًا',
          '${(data['approved_commissions'] as num).toStringAsFixed(0)} د.ل',
          Icons.pending_actions,
        ),
        (
          'تم دفعه سابقًا',
          '${(data['paid_commissions'] as num).toStringAsFixed(0)} د.ل',
          Icons.payments_outlined,
        ),
      ];
      return _AdminContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'نظرة عامة',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'بيانات مباشرة من قاعدة البيانات.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 980
                    ? 3
                    : constraints.maxWidth > 540
                    ? 2
                    : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  childAspectRatio: columns == 1 ? 4 : 2.5,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: metrics
                      .map(
                        (metric) => _Metric(
                          label: metric.$1,
                          value: metric.$2,
                          icon: metric.$3,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Icon(icon, color: AdminColors.accent, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
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
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.service.products();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
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
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
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
    required this.onEdit,
  });
  final Map<String, dynamic> row;
  final AdminService service;
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
                    'هل أنت متأكد؟ المنتجات المرتبطة بطلبات سابقة لا يمكن حذفها.',
                confirmLabel: 'حذف',
              );
              if (!context.mounted) return;
              if (okay) {
                try {
                  await service.deleteProduct(row['id'] as String);
                  if (!context.mounted) return;
                  onChanged();
                  showAdminMessage(context, 'تم حذف المنتج.');
                } catch (_) {
                  showAdminMessage(
                    context,
                    'تعذر حذف المنتج المرتبط بطلبات.',
                    error: true,
                  );
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
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              size,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          AdminStatusBadge(
            label: value == 0
                ? 'نفد المخزون'
                : value <= 3
                ? 'مخزون منخفض'
                : 'متوفر',
            tone: tone,
          ),
          const Spacer(),
          StockStepper(
            value: value,
            compact: true,
            onChanged: (next) => setState(() => sizes[size] = next),
          ),
          IconButton(
            tooltip: 'إزالة المقاس',
            onPressed: () => _removeSize(size),
            icon: const Icon(Icons.close, color: AdminColors.danger),
          ),
        ],
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
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            size,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: StockStepper(
            value: value,
            compact: true,
            onChanged: (next) => setState(() => color.sizes[size] = next),
          ),
        ),
        IconButton(
          tooltip: 'إزالة المقاس',
          onPressed: () => setState(() {
            color.sizes.remove(size);
            color.variantIds.remove(size);
          }),
          icon: const Icon(Icons.close, color: AdminColors.danger),
        ),
      ],
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
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (image != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: SafeProductImage(
                url: image,
                width: 48,
                height: 56,
                fit: BoxFit.cover,
                fallback: const Icon(Icons.image_outlined),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['name_ar'] ?? 'منتج'}${(row['product_colors'] as Map?)?['name_ar'] == null ? '' : '  ·  اللون ${(row['product_colors'] as Map)['name_ar']}'}  ·  المقاس ${row['size']}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                AdminStatusBadge(
                  label: stock == 0
                      ? 'نفد المخزون'
                      : stock <= 3
                      ? 'مخزون منخفض'
                      : 'متوفر',
                  tone: tone,
                ),
              ],
            ),
          ),
          StockStepper(
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
          ),
        ],
      ),
    );
  }
}

class _Orders extends StatefulWidget {
  const _Orders({required this.service, required this.onChanged, super.key});
  final AdminService service;
  final VoidCallback onChanged;
  @override
  State<_Orders> createState() => _OrdersState();
}

class _OrdersState extends State<_Orders> {
  String query = '';
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.service.orders();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _ordersFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const _ErrorState(message: 'تعذر تحميل الطلبات.');
      }
      final rows = snapshot.data!
          .where(
            (row) =>
                query.isEmpty ||
                '${row['order_number']} ${row['customer_name']} ${row['phone']}'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
          )
          .toList();
      return _AdminContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الطلبات',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 320,
              child: TextField(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onChanged: (value) => setState(() => query = value),
                decoration: adminRtlInputDecoration(
                  const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'بحث بالطلب أو العميل',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (rows.isEmpty)
              const _EmptyState(message: 'لا توجد طلبات مطابقة.')
            else
              ...rows.map(_orderRow),
          ],
        ),
      );
    },
  );
  Widget _orderRow(Map<String, dynamic> row) {
    final status = orderStatusFromString(row['status'] as String? ?? 'pending');
    return InkWell(
      onTap: () => _details(row),
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row['order_number'] ?? ''}  ·  ${row['customer_name'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${row['phone'] ?? ''}  ·  ${row['city'] ?? ''}  ·  ${row['total_lyd'] ?? 0} د.ل',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            AdminStatusBadge(
              label: orderStatusLabel(status),
              tone: _orderTone(status),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
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
              onChanged: (value) async {
                if (value == null) return;
                try {
                  await widget.service.updateOrderStatus(
                    row['id'] as String,
                    value,
                  );
                  widget.onChanged();
                  if (mounted) {
                    showAdminMessage(context, 'تم تحديث حالة الطلب.');
                  }
                } catch (_) {
                  if (mounted) {
                    showAdminMessage(
                      context,
                      'تعذر تحديث الحالة. تحقق من المخزون.',
                      error: true,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
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
  Map<String, dynamic>? _selectedRow;
  Future<DiscountPerformance>? _performanceFuture;
  final Set<String> _pendingCodeIds = {};
  final Set<String> _hiddenCodeIds = {};

  @override
  void initState() {
    super.initState();
    _codesFuture = widget.service.discounts();
  }

  void _openDetails(Map<String, dynamic> row) {
    final code = row['code'] as String? ?? '';
    setState(() {
      _selectedRow = row;
      _performanceFuture = widget.service.discountPerformance(code);
    });
  }

  Future<void> _reload() async {
    final selectedId = _selectedRow?['id'];
    final rows = await widget.service.discounts();
    if (!mounted) return;
    final refreshed = rows.where((row) => row['id'] == selectedId).firstOrNull;
    final refreshedCode = refreshed?['code'] as String?;
    setState(() {
      _codesFuture = Future.value(rows);
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
                  ? () => _pay(context, performance)
                  : null,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('تأكيد دفع المستحقات'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(
    BuildContext context,
    DiscountPerformance performance,
  ) async {
    final influencerId = performance.influencerId;
    if (performance.commission.approved <= 0 || influencerId == null) return;
    final confirmed = await confirmAdminAction(
      context,
      title: 'تأكيد دفع المستحقات',
      message:
          'سيتم تسجيل العمولات المستحقة الحالية كمدفوعة.\nلن يتم حذف سجل العمولات السابقة.',
      confirmLabel: 'تأكيد الدفع',
    );
    if (!confirmed || !context.mounted) return;
    try {
      final result = await widget.service.markInfluencerCommissionsPaid(
        influencerId,
      );
      await _reload();
      if (!context.mounted) return;
      final ordersPaid = (result['orders_paid'] as num?)?.toInt() ?? 0;
      final totalPaid =
          (result['total_paid'] as num?)?.toStringAsFixed(0) ?? '0';
      showAdminMessage(
        context,
        'تم تسجيل $ordersPaid طلبات كمدفوعة بقيمة $totalPaid د.ل.',
      );
    } catch (error, stackTrace) {
      debugPrint('Admin payout failed: $error\n$stackTrace');
      if (context.mounted) {
        showAdminMessage(context, 'تعذر تسجيل الدفع.', error: true);
      }
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
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(34),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Text(message, textAlign: TextAlign.center),
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
