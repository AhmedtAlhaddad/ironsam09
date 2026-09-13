import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/storefront_theme.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../checkout/checkout_page.dart';
import '../../widgets/safe_product_image.dart';

class CartPage extends StatelessWidget {
  const CartPage({required this.store, super.key});

  final StoreState store;

  void openCheckout(BuildContext context) {
    if (store.items.isEmpty) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CheckoutPage(store: store)));
  }

  @override
  Widget build(BuildContext context) {
    return StorefrontTheme(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'العودة للتسوق',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_forward),
            ),
            title: const Text(
              'سلة التسوق',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              AnimatedBuilder(
                animation: store,
                builder: (context, _) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Center(
                    child: Text(
                      '${store.itemCount} منتجات',
                      style: const TextStyle(
                        color: StorefrontColors.mutedInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              if (store.items.isEmpty) {
                return _EmptyCart(onReturn: () => Navigator.of(context).pop());
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final items = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CartSectionHeading(itemCount: store.itemCount),
                      const SizedBox(height: StorefrontSpacing.md),
                      ...store.items.map(
                        (entry) => _CartRow(
                          product: entry.key,
                          size: entry.size,
                          colorName: entry.colorName,
                          colorId: entry.colorId,
                          variantId: entry.variantId,
                          quantity: entry.value,
                          store: store,
                        ),
                      ),
                      const SizedBox(height: StorefrontSpacing.xxs),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('العودة للتسوق'),
                        style: TextButton.styleFrom(
                          foregroundColor: StorefrontColors.mutedInk,
                          alignment: AlignmentDirectional.centerStart,
                        ),
                      ),
                    ],
                  );
                  final summary = _CartSummary(
                    store: store,
                    onCheckout: () => openCheckout(context),
                  );

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      StorefrontLayout.gutterFor(constraints.maxWidth),
                      constraints.maxWidth < StorefrontLayout.narrow
                          ? StorefrontSpacing.lg
                          : StorefrontSpacing.xl,
                      StorefrontLayout.gutterFor(constraints.maxWidth),
                      StorefrontSpacing.section +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: items),
                                  const SizedBox(width: StorefrontSpacing.xl),
                                  Expanded(flex: 4, child: summary),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  items,
                                  const SizedBox(height: StorefrontSpacing.lg),
                                  summary,
                                ],
                              ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          StorefrontLayout.gutterFor(constraints.maxWidth),
          StorefrontSpacing.xxl,
          StorefrontLayout.gutterFor(constraints.maxWidth),
          StorefrontSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: EdgeInsets.all(
                constraints.maxWidth < StorefrontLayout.narrow
                    ? StorefrontSpacing.lg
                    : StorefrontSpacing.xl,
              ),
              decoration: const BoxDecoration(
                color: StorefrontColors.surface,
                borderRadius: StorefrontRadius.surfaceBorder,
                border: Border.fromBorderSide(
                  BorderSide(color: StorefrontColors.line),
                ),
                boxShadow: StorefrontShadows.subtle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: StorefrontColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 30,
                      color: StorefrontColors.ink,
                    ),
                  ),
                  const SizedBox(height: StorefrontSpacing.lg),
                  Text(
                    'سلتك بانتظار اختيارك.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: StorefrontSpacing.xs),
                  const Text(
                    'اكتشف التشكيلة واختر القطع والمقاسات المناسبة لك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: StorefrontColors.mutedInk,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: StorefrontSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onReturn,
                      icon: const Icon(Icons.arrow_forward, size: 19),
                      label: const Text('العودة للتسوق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartSectionHeading extends StatelessWidget {
  const _CartSectionHeading({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختياراتك',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: StorefrontSpacing.xxs),
              const Text(
                'راجع المقاس واللون والكمية قبل إتمام الطلب.',
                style: TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: StorefrontSpacing.sm),
        Semantics(
          label: 'إجمالي عناصر السلة $itemCount',
          child: Text(
            '$itemCount قطعة',
            style: const TextStyle(
              color: StorefrontColors.mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.store, required this.onCheckout});

  final StoreState store;
  final VoidCallback onCheckout;

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
            'تفاصيل الدفع',
            style: TextStyle(
              color: StorefrontColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: StorefrontSpacing.xxs),
          const Text(
            'ملخص الطلب',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          _TotalRow(label: 'المجموع الفرعي', value: store.subtotal),
          if (store.hasDiscount) ...[
            const SizedBox(height: StorefrontSpacing.sm),
            _TotalRow(
              label:
                  'خصم (${store.discountPercent.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}٪)',
              value: -store.discountAmount,
              accent: true,
            ),
          ],
          const SizedBox(height: 16),
          _CartDiscountField(store: store),
          const SizedBox(height: 12),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: StorefrontSpacing.md,
            runSpacing: StorefrontSpacing.xs,
            children: [
              Text(
                'الشحن',
                style: TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 13,
                ),
              ),
              Text(
                'يُحسب عند الدفع',
                style: TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: lineColor),
          ),
          _TotalRow(label: 'الإجمالي', value: store.total, large: true),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text(
                'إتمام الطلب',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'الدفع عند الاستلام · توصيل سريع',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StorefrontColors.mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartDiscountField extends StatefulWidget {
  const _CartDiscountField({required this.store});

  final StoreState store;

  @override
  State<_CartDiscountField> createState() => _CartDiscountFieldState();
}

class _CartDiscountFieldState extends State<_CartDiscountField> {
  late final TextEditingController controller;
  bool applying = false;
  String? feedback;
  bool feedbackSuccess = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.store.discountCode ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> apply() async {
    if (applying) return;
    final code = controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      widget.store.clearDiscount();
      setState(() {
        feedback = 'أدخل كود الخصم أولًا.';
        feedbackSuccess = false;
      });
      _showMessage('أدخل كود الخصم أولًا.');
      return;
    }

    setState(() => applying = true);
    try {
      final validation = await widget.store.applyDiscount(code);
      if (!mounted) return;
      final message = validation.valid
          ? 'تم تطبيق خصم ${validation.customerDiscountPercent.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}٪.'
          : 'كود الخصم غير صالح أو منتهي الصلاحية.';
      setState(() {
        feedback = message;
        feedbackSuccess = validation.valid;
      });
      _showMessage(message);
    } catch (_) {
      if (mounted) {
        const message = 'تعذر التحقق من كود الخصم حاليًا. حاول مرة أخرى.';
        setState(() {
          feedback = message;
          feedbackSuccess = false;
        });
        _showMessage(message);
      }
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.store.hasDiscount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'كود الخصم',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 340;
            final input = TextField(
              key: const ValueKey('cart-discount-input'),
              controller: controller,
              enabled: !applying,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'أدخل كود الخصم',
                prefixIcon: Icon(Icons.sell_outlined, size: 19),
              ),
              onChanged: (_) {
                if (feedback != null) setState(() => feedback = null);
              },
              onSubmitted: (_) => apply(),
            );
            final button = SizedBox(
              height: 56,
              width: stacked ? double.infinity : null,
              child: FilledButton(
                key: const ValueKey('cart-discount-apply'),
                onPressed: applying ? null : apply,
                child: AnimatedSwitcher(
                  duration: StorefrontMotion.resolve(
                    context,
                    StorefrontMotion.fast,
                  ),
                  child: applying
                      ? const SizedBox(
                          key: ValueKey('discount-loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          applied ? 'تم التطبيق' : 'تطبيق',
                          key: ValueKey(applied),
                        ),
                ),
              ),
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  input,
                  const SizedBox(height: StorefrontSpacing.xs),
                  button,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: input),
                const SizedBox(width: StorefrontSpacing.xs),
                button,
              ],
            );
          },
        ),
        AnimatedSwitcher(
          duration: StorefrontMotion.resolve(
            context,
            StorefrontMotion.standard,
          ),
          child: feedback != null || applied
              ? Semantics(
                  key: ValueKey(feedback ?? widget.store.discountCode),
                  liveRegion: true,
                  child: Container(
                    margin: const EdgeInsets.only(top: StorefrontSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: StorefrontSpacing.sm,
                      vertical: StorefrontSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: feedbackSuccess || (feedback == null && applied)
                          ? StorefrontColors.successSurface
                          : StorefrontColors.errorSurface,
                      borderRadius: StorefrontRadius.controlBorder,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          feedbackSuccess || (feedback == null && applied)
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 18,
                          color:
                              feedbackSuccess || (feedback == null && applied)
                              ? StorefrontColors.success
                              : StorefrontColors.error,
                        ),
                        const SizedBox(width: StorefrontSpacing.xs),
                        Expanded(
                          child: Text(
                            feedback ??
                                'الكود المعتمد: ${widget.store.discountCode}',
                            style: TextStyle(
                              color:
                                  feedbackSuccess ||
                                      (feedback == null && applied)
                                  ? StorefrontColors.success
                                  : StorefrontColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.product,
    required this.size,
    this.colorName,
    this.colorId,
    this.variantId,
    required this.quantity,
    required this.store,
  });

  final Product product;
  final String size;
  final String? colorName;
  final String? colorId;
  final String? variantId;
  final int quantity;
  final StoreState store;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final canIncrease = quantity < product.stockFor(size, colorId: colorId);
    void remove() => store.remove(
      product,
      size: size,
      colorId: colorId,
      variantId: variantId,
    );
    final increase = canIncrease
        ? () => store.add(product, size: size, colorId: colorId)
        : null;
    final details = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'إزالة وحدة من المنتج',
                style: IconButton.styleFrom(
                  foregroundColor: StorefrontColors.error,
                ),
                onPressed: remove,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: StorefrontSpacing.xxs),
          Wrap(
            spacing: StorefrontSpacing.xs,
            runSpacing: StorefrontSpacing.xxs,
            children: [
              _VariantLabel(label: 'المقاس', value: size),
              if (colorName != null)
                _VariantLabel(label: 'اللون', value: colorName!),
            ],
          ),
          const SizedBox(height: StorefrontSpacing.xs),
          Text(
            '${product.price.toStringAsFixed(2)} د.ل للقطعة',
            style: const TextStyle(
              color: StorefrontColors.mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    final quantityControl = _QuantityControl(
      quantity: quantity,
      onDecrease: remove,
      onIncrease: increase,
    );
    final totalPrice = Semantics(
      label:
          'إجمالي المنتج ${(product.price * quantity).toStringAsFixed(2)} دينار ليبي',
      child: Text(
        '${(product.price * quantity).toStringAsFixed(2)} د.ل',
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      ),
    );

    return Semantics(
      container: true,
      label: '${product.name}، المقاس $size، الكمية $quantity',
      child: Container(
        margin: const EdgeInsets.only(bottom: StorefrontSpacing.sm),
        padding: EdgeInsets.all(compact ? StorefrontSpacing.sm : 16),
        decoration: const BoxDecoration(
          color: StorefrontColors.surface,
          borderRadius: StorefrontRadius.controlBorder,
          border: Border.fromBorderSide(
            BorderSide(color: StorefrontColors.line),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: StorefrontRadius.controlBorder,
                  child: Container(
                    width: compact ? 72 : 92,
                    height: compact ? 96 : 116,
                    color: surfaceColor,
                    child: SafeProductImage(
                      url: product.imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 240,
                      filterQuality: FilterQuality.low,
                      color: Colors.white.withValues(alpha: .12),
                      colorBlendMode: BlendMode.saturation,
                      fallback: const Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                SizedBox(width: compact ? StorefrontSpacing.sm : 16),
                details,
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: StorefrontSpacing.sm),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                quantityControl,
                const SizedBox(width: StorefrontSpacing.sm),
                Flexible(child: totalPrice),
              ],
            ),
            if (!canIncrease) ...[
              const SizedBox(height: StorefrontSpacing.xs),
              const Text(
                'وصلت إلى الكمية المتاحة.',
                style: TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VariantLabel extends StatelessWidget {
  const _VariantLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorefrontSpacing.xs,
        vertical: StorefrontSpacing.xxs,
      ),
      decoration: const BoxDecoration(
        color: StorefrontColors.surfaceMuted,
        borderRadius: BorderRadius.all(
          Radius.circular(StorefrontRadius.subtle),
        ),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: StorefrontColors.mutedInk,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'الكمية الحالية $quantity',
      child: Container(
        decoration: const BoxDecoration(
          color: StorefrontColors.canvas,
          borderRadius: StorefrontRadius.controlBorder,
          border: Border.fromBorderSide(
            BorderSide(color: StorefrontColors.line),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: quantity == 1 ? 'إزالة المنتج' : 'إنقاص الكمية',
              onPressed: onDecrease,
              icon: Icon(
                quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 18,
              ),
            ),
            SizedBox(
              width: 30,
              child: AnimatedSwitcher(
                duration: StorefrontMotion.resolve(
                  context,
                  StorefrontMotion.fast,
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            IconButton(
              tooltip: onIncrease == null
                  ? 'الكمية القصوى متاحة'
                  : 'زيادة الكمية',
              onPressed: onIncrease,
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
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
            ? StorefrontColors.success
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
        color: accent ? StorefrontColors.success : inkColor,
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
