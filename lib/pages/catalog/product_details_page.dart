import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../../core/utils/hex_color.dart';
import '../../widgets/safe_product_image.dart';
import '../cart/cart_page.dart';

class _ProductColorSwatch extends StatelessWidget {
  const _ProductColorSwatch({
    required this.color,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final ProductColor color;
  final bool selected;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = colorFromHex(color.hexCode) ?? canvasColor;
    return Semantics(
      key: ValueKey('product-color-swatch-${color.id}'),
      button: true,
      enabled: available,
      selected: selected,
      label: color.nameAr,
      child: Opacity(
        opacity: available ? 1 : .38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? inkColor : lineColor,
                  width: selected ? 2.5 : 1.2,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                scale: selected ? 1.06 : 1,
                child: Material(
                  color: fill,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(width: 38, height: 38),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              color.nameAr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? inkColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    required this.product,
    required this.store,
    this.onSearchPressed,
    super.key,
  });

  final Product product;
  final StoreState store;
  final VoidCallback? onSearchPressed;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final PageController _galleryController;
  String _gallerySignature = '';
  int _galleryIndex = 0;
  int _galleryImageCount = 0;
  bool _galleryResetScheduled = false;

  Product get product => widget.product;
  StoreState get store => widget.store;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
  }

  @override
  void didUpdateWidget(covariant ProductDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product) {
      _gallerySignature = '';
      _galleryIndex = 0;
      _galleryImageCount = 0;
    }
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  void _syncGallery(List<ProductImage> images, String? colorId) {
    final signature =
        '$colorId:${images.map((image) => '${image.id}:${image.url}').join('|')}';
    if (_gallerySignature == signature) return;
    _gallerySignature = signature;
    _galleryIndex = 0;
    _galleryImageCount = images.length;
    if (_galleryResetScheduled) return;
    _galleryResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _galleryResetScheduled = false;
      if (!mounted || !_galleryController.hasClients) return;
      _galleryController.jumpToPage(0);
    });
  }

  void _selectGalleryImage(int index) {
    if (index < 0 || index >= _galleryImageCount || index == _galleryIndex) {
      return;
    }
    setState(() => _galleryIndex = index);
    if (!_galleryController.hasClients) return;
    _galleryController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Widget _gallery(List<ProductImage> images, {required bool isDesktop}) {
    if (images.isEmpty) {
      return Column(
        key: const ValueKey('product-details-gallery'),
        children: [
          AspectRatio(
            aspectRatio: isDesktop ? .96 : 1,
            child: Container(
              color: surfaceColor,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, size: 42),
            ),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey('product-details-gallery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: isDesktop ? .96 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    key: ValueKey(_gallerySignature),
                    controller: _galleryController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      if (!mounted || index == _galleryIndex) return;
                      setState(() => _galleryIndex = index);
                    },
                    itemBuilder: (context, index) => SizedBox.expand(
                      child: SafeProductImage(
                        key: ValueKey(
                          'product-gallery-image-${images[index].id ?? index}',
                        ),
                        url: images[index].url,
                        fit: BoxFit.contain,
                        fallback: const Icon(Icons.image_outlined, size: 42),
                      ),
                    ),
                  ),
                ),
                if (isDesktop && images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: canvasColor.withValues(alpha: .9),
                        shape: const CircleBorder(),
                        child: IconButton(
                          key: const ValueKey('product-gallery-previous'),
                          tooltip: 'الصورة السابقة',
                          onPressed: _galleryIndex > 0
                              ? () => _selectGalleryImage(_galleryIndex - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: canvasColor.withValues(alpha: .9),
                        shape: const CircleBorder(),
                        child: IconButton(
                          key: const ValueKey('product-gallery-next'),
                          tooltip: 'الصورة التالية',
                          onPressed: _galleryIndex < images.length - 1
                              ? () => _selectGalleryImage(_galleryIndex + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            textDirection: TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < images.length; index++)
                Semantics(
                  button: true,
                  selected: index == _galleryIndex,
                  label: 'الصورة ${index + 1}',
                  child: InkWell(
                    key: ValueKey('product-gallery-dot-$index'),
                    customBorder: const CircleBorder(),
                    onTap: () => _selectGalleryImage(index),
                    child: SizedBox(
                      width: 22,
                      height: 24,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: index == _galleryIndex ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: index == _galleryIndex
                                ? inkColor
                                : lineColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${_galleryIndex + 1} / ${images.length}',
                key: const ValueKey('product-gallery-counter'),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: images.asMap().entries.map((entry) {
                  final selected = entry.key == _galleryIndex;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: 'الصورة ${entry.key + 1}',
                      child: InkWell(
                        key: ValueKey(
                          'product-gallery-thumbnail-${images[entry.key].id ?? entry.key}',
                        ),
                        onTap: () => _selectGalleryImage(entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: selected ? inkColor : lineColor,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: SafeProductImage(
                            url: images[entry.key].url,
                            width: 68,
                            height: 70,
                            fit: BoxFit.cover,
                            fallback: const Icon(Icons.image_outlined),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openSearch() {
    final callback = widget.onSearchPressed;
    final navigator = Navigator.of(context);
    if (callback == null) {
      if (navigator.canPop()) navigator.pop();
      return;
    }
    if (!navigator.canPop()) {
      callback();
      return;
    }
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }

  Future<void> _goBack() async {
    final didPop = await Navigator.maybePop(context);
    if (!mounted || didPop) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Widget _productInformation({
    required List<ProductColor> colors,
    required String? selectedColor,
    required List<String> sizes,
    required String? selectedSize,
  }) {
    final selectedColorName = product.colorById(selectedColor)?.nameAr;
    final colorTitle = selectedColorName == null || selectedColorName.isEmpty
        ? 'اللون'
        : 'اللون: $selectedColorName';
    final quantity = store.items
        .where(
          (item) =>
              item.product == product &&
              item.colorId == selectedColor &&
              item.size == selectedSize,
        )
        .fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          product.name,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          '${product.price.toStringAsFixed(0)} د.ل',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        if (product.description.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            product.description,
            style: const TextStyle(color: Colors.black54, height: 1.8),
          ),
        ],
        if (colors.isNotEmpty) ...[
          const SizedBox(height: 30),
          Text(colorTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                for (var index = 0; index < colors.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Builder(
                    builder: (context) {
                      final color = colors[index];
                      final available = product
                          .variantsForColor(color.id)
                          .any((variant) => variant.inStock);
                      final selected = color.id == selectedColor;
                      return _ProductColorSwatch(
                        color: color,
                        selected: selected,
                        available: available,
                        onTap: available && color.id != null
                            ? () => store.selectColor(product, color.id!)
                            : null,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
        const Text('المقاس', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes.map((size) {
            final available =
                product.stockFor(size, colorId: selectedColor) > 0;
            final selected = size == selectedSize;
            return ChoiceChip(
              label: Text(size, textDirection: TextDirection.ltr),
              selected: selected,
              onSelected: available
                  ? (_) => store.selectSize(product, size)
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            const Text('الكمية', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: lineColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => store.remove(
                      product,
                      size: selectedSize,
                      colorId: selectedColor,
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    key: const ValueKey('product-details-quantity'),
                    width: 34,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => store.add(
                      product,
                      size: selectedSize,
                      colorId: selectedColor,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('product-details-add'),
            onPressed: () {
              if (colors.length > 1 && selectedColor == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى اختيار اللون أولاً')),
                );
                return;
              }
              if (sizes.length > 1 && selectedSize == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى اختيار المقاس أولاً')),
                );
                return;
              }
              final before = store.itemCount;
              store.add(product, size: selectedSize, colorId: selectedColor);
              if (store.itemCount == before) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا الخيار غير متوفر حالياً')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت الإضافة إلى السلة')),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('إضافة إلى السلة'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: _ProductDetailsHeader(
            store: store,
            onSearchPressed: _openSearch,
          ),
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final colors = product.activeColors;
            final selectedColor = store.colorFor(product);
            final sizes = product.sizeOptionsForColor(selectedColor);
            final selectedSize = store.selectedSizeFor(product);
            final galleryImages = product.imagesForColor(selectedColor);
            _syncGallery(galleryImages, selectedColor);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;
                final gallery = _gallery(galleryImages, isDesktop: isDesktop);
                final information = Directionality(
                  textDirection: TextDirection.rtl,
                  child: _productInformation(
                    colors: colors,
                    selectedColor: selectedColor,
                    sizes: sizes,
                    selectedSize: selectedSize,
                  ),
                );
                final content = isDesktop
                    ? Row(
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 58, child: gallery),
                          const SizedBox(width: 48),
                          Expanded(flex: 42, child: information),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gallery,
                          const SizedBox(height: 28),
                          information,
                        ],
                      );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Material(
                                color: surfaceColor,
                                shape: const CircleBorder(
                                  side: BorderSide(color: lineColor),
                                ),
                                child: IconButton(
                                  key: const ValueKey('product-details-back'),
                                  tooltip: 'رجوع',
                                  onPressed: _goBack,
                                  icon: const BackButtonIcon(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            content,
                          ],
                        ),
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

class _ProductDetailsHeader extends StatelessWidget {
  const _ProductDetailsHeader({
    required this.store,
    required this.onSearchPressed,
  });

  final StoreState store;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: canvasColor,
        border: Border(bottom: BorderSide(color: lineColor)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width >= 1100 ? 48 : 16,
      ),
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Image(
              key: ValueKey('product-details-logo'),
              image: AssetImage('assets/images/iron_sam_logo.png'),
              width: 104,
              height: 60,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: store,
                  builder: (context, _) => _ProductCartAction(store: store),
                ),
                IconButton(
                  key: const ValueKey('product-details-search'),
                  tooltip: 'البحث',
                  onPressed: onSearchPressed,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCartAction extends StatelessWidget {
  const _ProductCartAction({required this.store});

  final StoreState store;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('product-details-cart'),
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'سلة التسوق',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => CartPage(store: store)),
          ),
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
        if (store.itemCount > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${store.itemCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
