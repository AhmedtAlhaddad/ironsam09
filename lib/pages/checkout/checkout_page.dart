import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/storefront_theme.dart';
import '../../data/local/libya_cities.dart';
import '../../data/models/order.dart';
import '../../features/cart/cart_state.dart';
import '../../features/order/whatsapp_order_service.dart';
import '../../navigation/storefront_navigation.dart';
import '../../widgets/safe_product_image.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.store, super.key});

  final StoreState store;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final whatsappService = const WhatsAppOrderService();

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final fullNameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final cityFocus = FocusNode();
  final addressFocus = FocusNode();

  String? city;
  bool openingWhatsApp = false;
  bool submitted = false;
  double submittedTotal = 0;
  OrderReceipt? savedOrder;
  String? pendingWhatsAppMessage;
  String? requestId;
  String? formFeedback;

  double get discount => widget.store.discountAmount;
  double get total => widget.store.total;

  void _goBack() {
    final navigation = StorefrontNavigation.maybeOf(context);
    if (navigation != null) {
      navigation.goBack();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    fullNameFocus.dispose();
    phoneFocus.dispose();
    cityFocus.dispose();
    addressFocus.dispose();
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
    if (!(formKey.currentState?.validate() ?? false)) {
      setState(() {
        formFeedback = 'راجع الحقول الموضحة وأكمل البيانات المطلوبة.';
      });
      _focusFirstInvalidField();
      return;
    }

    setState(() {
      formFeedback = null;
      openingWhatsApp = true;
    });
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

  void _focusFirstInvalidField() {
    if (fullNameController.text.trim().length < 2) {
      fullNameFocus.requestFocus();
    } else if (!RegExp(r'^09\d{8}$').hasMatch(phoneController.text.trim())) {
      phoneFocus.requestFocus();
    } else if (city == null) {
      cityFocus.requestFocus();
    } else if (addressController.text.trim().length < 5) {
      addressFocus.requestFocus();
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
      return StorefrontTheme(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SafeArea(
              child: _OrderSuccessView(
                total: submittedTotal,
                onReturn: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          ),
        ),
      );
    }

    return StorefrontTheme(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 950;
            final isMobile = constraints.maxWidth < StorefrontLayout.tablet;
            final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
            return Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                leading: IconButton(
                  tooltip: 'العودة للسلة',
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_forward),
                ),
                title: Text(
                  'إتمام الطلب',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                actions: [
                  IconButton(
                    tooltip: 'سلة التسوق',
                    onPressed: _goBack,
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ],
              ),
              body: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    StorefrontLayout.gutterFor(constraints.maxWidth),
                    StorefrontSpacing.xl,
                    StorefrontLayout.gutterFor(constraints.maxWidth),
                    (isWide
                            ? StorefrontSpacing.section
                            : StorefrontSpacing.xl) +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CheckoutHeading(),
                          if (formFeedback != null) ...[
                            const SizedBox(height: StorefrontSpacing.md),
                            _FormFeedback(message: formFeedback!),
                          ],
                          const SizedBox(height: StorefrontSpacing.lg),
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
                                        fullNameFocus: fullNameFocus,
                                        phoneFocus: phoneFocus,
                                        cityFocus: cityFocus,
                                        addressFocus: addressFocus,
                                        city: city,
                                        cities: libyaCitiesAndAreas,
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
                                        discountApplied:
                                            widget.store.hasDiscount,
                                        onConfirm: confirmOrder,
                                        loading: openingWhatsApp,
                                        retryAvailable: savedOrder != null,
                                        showConfirmButton: true,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _CheckoutForm(
                                      fullNameController: fullNameController,
                                      phoneController: phoneController,
                                      addressController: addressController,
                                      notesController: notesController,
                                      fullNameFocus: fullNameFocus,
                                      phoneFocus: phoneFocus,
                                      cityFocus: cityFocus,
                                      addressFocus: addressFocus,
                                      city: city,
                                      cities: libyaCitiesAndAreas,
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
                                      showConfirmButton: !isMobile,
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: isMobile
                  ? AnimatedSwitcher(
                      duration: StorefrontMotion.resolve(
                        context,
                        StorefrontMotion.standard,
                      ),
                      child: keyboardOpen
                          ? const SizedBox.shrink()
                          : _MobileCheckoutBar(
                              key: const ValueKey('mobile-checkout-bar'),
                              total: total,
                              loading: openingWhatsApp,
                              retryAvailable: savedOrder != null,
                              onConfirm: confirmOrder,
                            ),
                    )
                  : null,
            );
          },
        ),
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
        const Text(
          'الخطوة الأخيرة',
          style: TextStyle(
            color: StorefrontColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: StorefrontSpacing.xs),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium,
            children: const [
              TextSpan(text: 'إتمام الطلب'),
              TextSpan(
                text: '.',
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: StorefrontSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: StorefrontLayout.readingMaxWidth,
          ),
          child: const Text(
            'أدخل بيانات التوصيل، راجع طلبك، ثم أكّد الطلب بأمان عبر واتساب.',
            style: TextStyle(
              color: StorefrontColors.mutedInk,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormFeedback extends StatelessWidget {
  const _FormFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(StorefrontSpacing.sm),
        decoration: const BoxDecoration(
          color: StorefrontColors.errorSurface,
          borderRadius: StorefrontRadius.controlBorder,
          border: Border.fromBorderSide(
            BorderSide(color: StorefrontColors.error),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: StorefrontColors.error,
              size: 20,
            ),
            const SizedBox(width: StorefrontSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: StorefrontColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.fullNameController,
    required this.phoneController,
    required this.addressController,
    required this.notesController,
    required this.fullNameFocus,
    required this.phoneFocus,
    required this.cityFocus,
    required this.addressFocus,
    required this.city,
    required this.cities,
    required this.onCityChanged,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final FocusNode fullNameFocus;
  final FocusNode phoneFocus;
  final FocusNode cityFocus;
  final FocusNode addressFocus;
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
    final compact = MediaQuery.sizeOf(context).width < StorefrontLayout.narrow;
    return Container(
      padding: EdgeInsets.all(
        compact ? StorefrontSpacing.md : StorefrontSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: StorefrontColors.surface,
        borderRadius: StorefrontRadius.surfaceBorder,
        border: Border.fromBorderSide(BorderSide(color: StorefrontColors.line)),
        boxShadow: StorefrontShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormSectionTitle(title: '١. معلومات التوصيل'),
          const SizedBox(height: StorefrontSpacing.lg),
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
                      focusNode: fullNameFocus,
                      autofillHints: const [AutofillHints.name],
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
                      focusNode: phoneFocus,
                      autofillHints: const [AutofillHints.telephoneNumber],
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
                      focusNode: cityFocus,
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
                      focusNode: addressFocus,
                      autofillHints: const [AutofillHints.fullStreetAddress],
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
                      minLines: 2,
                      textInputAction: TextInputAction.done,
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
      ),
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
    required this.showConfirmButton,
  });

  final StoreState store;
  final double discount;
  final double discountPercent;
  final double total;
  final bool discountApplied;
  final VoidCallback onConfirm;
  final bool loading;
  final bool retryAvailable;
  final bool showConfirmButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < StorefrontLayout.narrow ? 16 : 24,
      ),
      decoration: const BoxDecoration(
        color: StorefrontColors.surface,
        borderRadius: StorefrontRadius.surfaceBorder,
        border: Border.fromBorderSide(BorderSide(color: StorefrontColors.line)),
        boxShadow: StorefrontShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '٢. مراجعة الطلب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: lineColor),
          ),
          if (store.hasDiscount) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: StorefrontColors.successSurface,
                borderRadius: StorefrontRadius.controlBorder,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: StorefrontColors.success,
                  ),
                  const SizedBox(width: StorefrontSpacing.xs),
                  const Text(
                    'كود الخصم',
                    style: TextStyle(
                      color: StorefrontColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
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
            ...store.items.map((entry) => _CheckoutItemRow(item: entry)),
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
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: StorefrontSpacing.md,
            runSpacing: StorefrontSpacing.xs,
            children: [
              Text(
                'التوصيل',
                style: TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 13,
                ),
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
          const SizedBox(height: StorefrontSpacing.md),
          _WhatsAppNotice(retryAvailable: retryAvailable),
          if (showConfirmButton) ...[
            const SizedBox(height: StorefrontSpacing.md),
            _ConfirmButton(
              loading: loading,
              retryAvailable: retryAvailable,
              onPressed: onConfirm,
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${item.product.name}، المقاس ${item.size}، الكمية ${item.quantity}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: StorefrontSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: StorefrontRadius.controlBorder,
              child: Container(
                width: 56,
                height: 72,
                color: StorefrontColors.surfaceMuted,
                child: SafeProductImage(
                  url: item.product.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 160,
                  filterQuality: FilterQuality.low,
                  fallback: const Icon(Icons.image_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: StorefrontSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: StorefrontSpacing.xxs),
                  Text(
                    '${item.colorName == null ? '' : 'اللون: ${item.colorName} · '}المقاس: ${item.size} · الكمية: ${item.quantity}',
                    style: const TextStyle(
                      color: StorefrontColors.mutedInk,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: StorefrontSpacing.xxs),
                  Text(
                    '${(item.product.price * item.quantity).toStringAsFixed(2)} د.ل',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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
}

class _WhatsAppNotice extends StatelessWidget {
  const _WhatsAppNotice({required this.retryAvailable});

  final bool retryAvailable;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: retryAvailable,
      child: Container(
        padding: const EdgeInsets.all(StorefrontSpacing.sm),
        decoration: BoxDecoration(
          color: retryAvailable
              ? StorefrontColors.successSurface
              : StorefrontColors.surfaceMuted,
          borderRadius: StorefrontRadius.controlBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              retryAvailable
                  ? Icons.check_circle_outline
                  : Icons.chat_bubble_outline,
              size: 20,
              color: retryAvailable ? StorefrontColors.success : null,
            ),
            const SizedBox(width: StorefrontSpacing.xs),
            Expanded(
              child: Text(
                retryAvailable
                    ? 'تم حفظ الطلب. يمكنك إعادة فتح واتساب من دون إنشاء طلب جديد.'
                    : 'سيُحفظ طلبك أولًا، ثم يُفتح واتساب لتأكيد تفاصيل الطلب. الدفع عند الاستلام.',
                style: const TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileCheckoutBar extends StatelessWidget {
  const _MobileCheckoutBar({
    required this.total,
    required this.loading,
    required this.retryAvailable,
    required this.onConfirm,
    super.key,
  });

  final double total;
  final bool loading;
  final bool retryAvailable;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StorefrontColors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          StorefrontSpacing.sm,
          StorefrontSpacing.sm,
          StorefrontSpacing.sm,
          StorefrontSpacing.sm,
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: StorefrontColors.line)),
          ),
          padding: const EdgeInsets.only(top: StorefrontSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'الإجمالي',
                      style: TextStyle(
                        color: StorefrontColors.mutedInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: StorefrontSpacing.sm),
                  Flexible(
                    child: Text(
                      '${total.toStringAsFixed(2)} د.ل',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StorefrontSpacing.xs),
              _ConfirmButton(
                loading: loading,
                retryAvailable: retryAvailable,
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
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
    final label = loading
        ? 'جاري فتح واتساب...'
        : retryAvailable
        ? 'إعادة فتح واتساب'
        : 'تأكيد الطلب عبر واتساب';
    return Semantics(
      button: true,
      enabled: !loading,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          key: const ValueKey('checkout-confirm-cta'),
          onPressed: loading ? null : onPressed,
          icon: AnimatedSwitcher(
            duration: StorefrontMotion.resolve(context, StorefrontMotion.fast),
            child: loading
                ? const SizedBox(
                    key: ValueKey('checkout-loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.chat_bubble_outline,
                    key: ValueKey('checkout-whatsapp-icon'),
                    size: 20,
                  ),
          ),
          label: AnimatedSwitcher(
            duration: StorefrontMotion.resolve(
              context,
              StorefrontMotion.standard,
            ),
            child: Text(
              label,
              key: ValueKey(label),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
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
            decoration: const BoxDecoration(
              color: StorefrontColors.surface,
              borderRadius: StorefrontRadius.surfaceBorder,
              border: Border.fromBorderSide(
                BorderSide(color: StorefrontColors.line),
              ),
              boxShadow: StorefrontShadows.raised,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: inkColor,
                  child: Icon(Icons.check, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 22),
                Semantics(
                  liveRegion: true,
                  header: true,
                  child: const Text(
                    'تم إرسال طلبك بنجاح.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'سنتواصل معك قريبًا لتأكيد تفاصيل التوصيل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: StorefrontColors.mutedInk,
                    fontSize: 14,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: lineColor),
                ),
                const Text(
                  'إجمالي الطلب',
                  style: TextStyle(
                    color: StorefrontColors.mutedInk,
                    fontSize: 12,
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
                    color: StorefrontColors.mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
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
    final labelWidget = Text(
      label,
      style: TextStyle(
        color: accent
            ? accentColor
            : large
            ? inkColor
            : StorefrontColors.mutedInk,
        fontSize: large ? 18 : 13,
        fontWeight: large ? FontWeight.w900 : FontWeight.w600,
      ),
    );
    final valueWidget = Text(
      '${value.toStringAsFixed(2)} د.ل',
      textDirection: TextDirection.rtl,
      style: TextStyle(
        color: accent ? accentColor : inkColor,
        fontSize: large ? 18 : 13,
        fontWeight: FontWeight.w900,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelWidget,
              const SizedBox(height: StorefrontSpacing.xxs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: valueWidget,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: StorefrontSpacing.xs),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: valueWidget,
              ),
            ),
          ],
        );
      },
    );
  }
}
