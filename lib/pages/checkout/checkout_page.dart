import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/order.dart';
import '../../features/cart/cart_state.dart';
import '../../features/order/whatsapp_order_service.dart';
import '../../widgets/safe_product_image.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.store, super.key});

  final StoreState store;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final whatsappService = const WhatsAppOrderService();
  static const cities = [
    'طرابلس',
    'بنغازي',
    'مصراتة',
    'الزاوية',
    'سبها',
    'البيضاء',
    'زليتن',
  ];

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();

  String? city;
  bool openingWhatsApp = false;
  bool submitted = false;
  double submittedTotal = 0;
  OrderReceipt? savedOrder;
  String? pendingWhatsAppMessage;
  String? requestId;

  double get discount => widget.store.discountAmount;
  double get total => widget.store.total;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String _newRequestId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message), action: action));
  }

  String buildOrderMessage(OrderReceipt receipt) {
    final productLines = widget.store.items
        .map((entry) {
          final product = entry.key;
          final color = entry.colorName == null
              ? ''
              : ' · اللون: ${entry.colorName}';
          return '- ${product.name}$color · المقاس: ${entry.size} × ${entry.value}';
        })
        .join('\n');

    return 'طلب جديد - آيرون سام\n\n'
        'المنتجات:\n$productLines\n\n'
        '${widget.store.discountCode == null ? '' : 'كود الخصم: ${widget.store.discountCode}\n'}'
        'التوصيل: يحدد حسب المدينة\n'
        'الإجمالي: ${receipt.total.toStringAsFixed(2)} د.ل\n'
        'الاسم: ${fullNameController.text.trim()}\n'
        'الهاتف: ${phoneController.text.trim()}\n'
        'المدينة: ${city ?? ''}\n'
        'العنوان: ${addressController.text.trim()}\n'
        'ملاحظات: ${notesController.text.trim().isEmpty ? 'لا توجد' : notesController.text.trim()}';
  }

  Future<void> confirmOrder() async {
    if (openingWhatsApp) return;
    if (savedOrder != null && pendingWhatsAppMessage != null) {
      await _openSavedOrderInWhatsApp();
      return;
    }
    if (widget.store.items.isEmpty) {
      _showMessage('السلة فارغة حاليًا.');
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => openingWhatsApp = true);
    try {
      requestId ??= _newRequestId();
      final receipt = await widget.store.submitOrder(
        customerName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        city: city ?? '',
        address: addressController.text.trim(),
        notes: notesController.text.trim(),
        requestId: requestId,
      );
      if (receipt == null || receipt.orderNumber.isEmpty) {
        throw StateError('order_not_created');
      }
      savedOrder = receipt;
      pendingWhatsAppMessage =
          '${buildOrderMessage(receipt)}\nرقم الطلب: ${receipt.orderNumber}';
      // The order is already saved. Clear the cart now so a failed WhatsApp
      // launch cannot cause the same order to be submitted again.
      widget.store.clear();
      if (!mounted) return;
      setState(() => openingWhatsApp = false);
      await _openSavedOrderInWhatsApp();
    } catch (_) {
      if (!mounted) return;
      setState(() => openingWhatsApp = false);
      _showMessage('تعذر حفظ الطلب. تحقق من الاتصال وحاول مرة أخرى.');
    }
  }

  Future<void> _openSavedOrderInWhatsApp() async {
    final receipt = savedOrder;
    final message = pendingWhatsAppMessage;
    if (receipt == null || message == null || openingWhatsApp) return;
    setState(() => openingWhatsApp = true);
    var launched = false;
    try {
      launched = await whatsappService.send(message);
    } catch (_) {
      launched = false;
    }
    if (!mounted) return;
    if (launched) {
      submittedTotal = receipt.total;
      setState(() {
        openingWhatsApp = false;
        submitted = true;
      });
    } else {
      setState(() => openingWhatsApp = false);
      _showMessage(
        'تم حفظ الطلب رقم ${receipt.orderNumber}، لكن تعذر فتح واتساب.',
        action: SnackBarAction(
          label: 'إعادة الفتح',
          onPressed: () {
            _openSavedOrderInWhatsApp();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: _OrderSuccessView(
            total: submittedTotal,
            onReturn: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 950;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'العودة للسلة',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_forward),
              ),
              title: const Text(
                'إتمام الطلب',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'سلة التسوق',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              ],
            ),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 1100 ? 48 : 16,
                  24,
                  constraints.maxWidth >= 1100 ? 48 : 16,
                  isWide ? 48 : 120,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _CheckoutHeading(),
                        const SizedBox(height: 30),
                        isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _CheckoutForm(
                                      fullNameController: fullNameController,
                                      phoneController: phoneController,
                                      addressController: addressController,
                                      notesController: notesController,
                                      city: city,
                                      cities: cities,
                                      onCityChanged: (value) =>
                                          setState(() => city = value),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                  Expanded(
                                    flex: 5,
                                    child: _OrderSummary(
                                      store: widget.store,
                                      discount: discount,
                                      discountPercent:
                                          widget.store.discountPercent,
                                      total: total,
                                      discountApplied: widget.store.hasDiscount,
                                      onConfirm: confirmOrder,
                                      loading: openingWhatsApp,
                                      retryAvailable: savedOrder != null,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CheckoutForm(
                                    fullNameController: fullNameController,
                                    phoneController: phoneController,
                                    addressController: addressController,
                                    notesController: notesController,
                                    city: city,
                                    cities: cities,
                                    onCityChanged: (value) =>
                                        setState(() => city = value),
                                  ),
                                  const SizedBox(height: 30),
                                  _OrderSummary(
                                    store: widget.store,
                                    discount: discount,
                                    discountPercent:
                                        widget.store.discountPercent,
                                    total: total,
                                    discountApplied: widget.store.hasDiscount,
                                    onConfirm: confirmOrder,
                                    loading: openingWhatsApp,
                                    retryAvailable: savedOrder != null,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckoutHeading extends StatelessWidget {
  const _CheckoutHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: inkColor,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
            children: [
              TextSpan(text: 'إتمام الطلب'),
              TextSpan(
                text: '.',
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.fullNameController,
    required this.phoneController,
    required this.addressController,
    required this.notesController,
    required this.city,
    required this.cities,
    required this.onCityChanged,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final String? city;
  final List<String> cities;
  final ValueChanged<String?> onCityChanged;

  InputDecoration decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FormSectionTitle(title: '١. معلومات التوصيل'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 560;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: twoColumns
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: TextFormField(
                    controller: fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: decoration('الاسم الكامل *', 'محمد أحمد علي'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'يرجى إدخال الاسم الكامل.'
                        : null,
                  ),
                ),
                SizedBox(
                  width: twoColumns
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: decoration('رقم الهاتف *', '09XXXXXXXX'),
                    validator: (value) =>
                        !RegExp(r'^09\d{8}$').hasMatch(value?.trim() ?? '')
                        ? 'أدخل رقمًا ليبيًا صحيحًا بصيغة 09XXXXXXXX.'
                        : null,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: DropdownButtonFormField<String>(
                    initialValue: city,
                    isExpanded: true,
                    decoration: decoration('المدينة *', 'اختر المدينة'),
                    items: cities
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: onCityChanged,
                    validator: (value) =>
                        value == null ? 'يرجى اختيار المدينة.' : null,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: TextFormField(
                    controller: addressController,
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    decoration: decoration(
                      'العنوان التفصيلي *',
                      'الحي، الشارع، رقم المبنى',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'يرجى إدخال عنوان تفصيلي.'
                        : null,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: decoration(
                      'ملاحظات إضافية (اختياري)',
                      'أي تعليمات خاصة بالتوصيل',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: lineColor)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.store,
    required this.discount,
    required this.discountPercent,
    required this.total,
    required this.discountApplied,
    required this.onConfirm,
    required this.loading,
    required this.retryAvailable,
  });

  final StoreState store;
  final double discount;
  final double discountPercent;
  final double total;
  final bool discountApplied;
  final VoidCallback onConfirm;
  final bool loading;
  final bool retryAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: surfaceColor.withValues(alpha: .3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ملخص الطلب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: lineColor),
          ),
          if (store.hasDiscount) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: lineColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'كود الخصم',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  Text(
                    store.discountCode!,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (store.items.isEmpty)
            const Text('لا توجد منتجات في السلة.')
          else
            ...store.items.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 66,
                      color: Colors.white,
                      child: SafeProductImage(
                        url: entry.key.imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        filterQuality: FilterQuality.low,
                        fallback: const Icon(Icons.image_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.colorName == null ? '' : 'اللون: ${entry.colorName} · '}مقاس: ${entry.size} · كمية: ${entry.value}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(entry.key.price * entry.value).toStringAsFixed(2)} د.ل',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(color: lineColor),
          const SizedBox(height: 12),
          _TotalRow(label: 'المجموع الفرعي', value: store.subtotal),
          if (discountApplied) ...[
            const SizedBox(height: 10),
            _TotalRow(
              label:
                  'خصم (${discountPercent.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}٪)',
              value: -discount,
              accent: true,
            ),
          ],
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التوصيل',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                'يحدد حسب المدينة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: lineColor),
          ),
          _TotalRow(label: 'الإجمالي', value: total, large: true),
          const SizedBox(height: 20),
          _ConfirmButton(
            loading: loading,
            retryAvailable: retryAvailable,
            onPressed: onConfirm,
          ),
          const SizedBox(height: 14),
          const Text(
            'دفع عند الاستلام · توصيل سريع',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black45,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.loading,
    required this.onPressed,
    this.retryAvailable = false,
  });

  final bool loading;
  final VoidCallback onPressed;
  final bool retryAvailable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: inkColor,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.chat_bubble_outline, size: 20),
        label: Text(
          loading
              ? 'جاري فتح واتساب...'
              : retryAvailable
              ? 'إعادة فتح واتساب'
              : 'تأكيد الطلب عبر واتساب',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _OrderSuccessView extends StatelessWidget {
  const _OrderSuccessView({required this.total, required this.onReturn});

  final double total;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(32),
            color: surfaceColor.withValues(alpha: .3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: inkColor,
                  child: Icon(Icons.check, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 22),
                const Text(
                  'تم إرسال طلبك بنجاح.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'سنتواصل معك قريبًا لتأكيد تفاصيل التوصيل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: lineColor),
                ),
                const Text(
                  'إجمالي الطلب',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${total.toStringAsFixed(2)} د.ل',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'الدفع عند الاستلام',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: inkColor,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: onReturn,
                    child: const Text('العودة إلى التسوق'),
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.large = false,
    this.accent = false,
  });

  final String label;
  final double value;
  final bool large;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent
                ? accentColor
                : large
                ? inkColor
                : Colors.black54,
            fontSize: large ? 18 : 13,
            fontWeight: large ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} د.ل',
          style: TextStyle(
            color: accent ? accentColor : inkColor,
            fontSize: large ? 18 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
