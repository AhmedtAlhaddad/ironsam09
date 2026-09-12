import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
    return Directionality(
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
                      color: Colors.black54,
                      fontSize: 11,
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 42),
                      const SizedBox(height: 14),
                      const Text(
                        'السلة فارغة حاليًا.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: inkColor,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('العودة للتسوق'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final items = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('العودة للتسوق'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
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
                    constraints.maxWidth >= 1100 ? 48 : 16,
                    28,
                    constraints.maxWidth >= 1100 ? 48 : 16,
                    48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: items),
                                const SizedBox(width: 32),
                                Expanded(flex: 4, child: summary),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                items,
                                const SizedBox(height: 28),
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
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ملخص الطلب',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          _TotalRow(label: 'المجموع الفرعي', value: store.subtotal),
          const SizedBox(height: 16),
          _CartDiscountField(store: store),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الشحن',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                'يُحسب عند الدفع',
                style: TextStyle(color: Colors.black54, fontSize: 13),
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
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: inkColor,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: onCheckout,
              child: const Text(
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

class _CartDiscountField extends StatefulWidget {
  const _CartDiscountField({required this.store});

  final StoreState store;

  @override
  State<_CartDiscountField> createState() => _CartDiscountFieldState();
}

class _CartDiscountFieldState extends State<_CartDiscountField> {
  late final TextEditingController controller;
  bool applying = false;

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
      _showMessage('أدخل كود الخصم أولًا.');
      return;
    }

    setState(() => applying = true);
    try {
      final validation = await widget.store.applyDiscount(code);
      if (!mounted) return;
      _showMessage(
        validation.valid
            ? 'تم تطبيق خصم ${validation.customerDiscountPercent.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}٪.'
            : 'كود الخصم غير صالح أو منتهي الصلاحية.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر التحقق من كود الخصم حاليًا. حاول مرة أخرى.');
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !applying,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'أدخل كود الخصم'),
                onSubmitted: (_) => apply(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: applying ? null : apply,
                child: Text(applied ? 'تم التطبيق' : 'تطبيق'),
              ),
            ),
          ],
        ),
        if (applied) ...[
          const SizedBox(height: 6),
          Text(
            'الكود المعتمد: ${widget.store.discountCode}',
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 112,
            color: surfaceColor,
            child: SafeProductImage(
              url: product.imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 240,
              filterQuality: FilterQuality.low,
              color: Colors.white.withValues(alpha: .18),
              colorBlendMode: BlendMode.saturation,
              fallback: const Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.gender} · ${product.category}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${colorName == null ? '' : 'اللون: $colorName\n'}المقاس: $size',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف المنتج',
                      onPressed: () => store.remove(
                        product,
                        size: size,
                        colorId: colorId,
                        variantId: variantId,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: lineColor),
                        ),
                        color: canvasColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'إنقاص الكمية',
                            onPressed: () => store.remove(
                              product,
                              size: size,
                              colorId: colorId,
                              variantId: variantId,
                            ),
                            icon: const Icon(Icons.remove, size: 17),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            tooltip: 'زيادة الكمية',
                            onPressed: () => store.add(
                              product,
                              size: size,
                              colorId: colorId,
                            ),
                            icon: const Icon(Icons.add, size: 17),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(product.price * quantity).toStringAsFixed(2)} د.ل',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final double value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: large ? inkColor : Colors.black54,
            fontSize: large ? 18 : 13,
            fontWeight: large ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} د.ل',
          style: TextStyle(
            color: inkColor,
            fontSize: large ? 18 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
