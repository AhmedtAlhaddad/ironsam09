import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/storefront_theme.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../../core/utils/hex_color.dart';
import '../../widgets/safe_product_image.dart';
import '../cart/cart_page.dart';

class _ProductColorSwatch extends StatefulWidget {
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
  State<_ProductColorSwatch> createState() => _ProductColorSwatchState();
}

class _ProductColorSwatchState extends State<_ProductColorSwatch> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fill = colorFromHex(widget.color.hexCode) ?? canvasColor;
    final isLight = fill.computeLuminance() > .78;
    final interactive = widget.available && widget.onTap != null;
    final outerBorder = _focused
        ? StorefrontColors.focus
        : widget.selected
        ? StorefrontColors.ink
        : _hovered && interactive
        ? StorefrontColors.accent
        : StorefrontColors.line;

    return Semantics(
      key: ValueKey('product-color-swatch-${widget.color.id}'),
      button: true,
      enabled: widget.available,
      selected: widget.selected,
      label: '${widget.color.nameAr}${widget.available ? '' : '، غير متوفر'}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: interactive ? widget.onTap : null,
                onFocusChange: (value) => setState(() => _focused = value),
                onHover: (value) => setState(() => _hovered = value),
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: StorefrontMotion.resolve(
                    context,
                    StorefrontMotion.standard,
                  ),
                  curve: StorefrontMotion.curve,
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hovered && interactive
                        ? StorefrontColors.surface
                        : Colors.transparent,
                    border: Border.all(
                      color: outerBorder,
                      width: _focused || widget.selected ? 2.2 : 1.2,
                    ),
                    boxShadow: widget.selected
                        ? StorefrontShadows.subtle
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedScale(
                        duration: StorefrontMotion.resolve(
                          context,
                          StorefrontMotion.fast,
                        ),
                        curve: StorefrontMotion.curve,
                        scale: widget.selected ? 1 : .9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: fill,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLight ? StorefrontColors.mutedInk : fill,
                              width: isLight ? 1.2 : 1,
                            ),
                          ),
                        ),
                      ),
                      if (widget.selected)
                        Icon(
                          Icons.check_rounded,
                          size: 21,
                          color: isLight
                              ? StorefrontColors.ink
                              : StorefrontColors.onDark,
                        ),
                      if (!widget.available)
                        Transform.rotate(
                          angle: -.72,
                          child: Container(
                            width: 42,
                            height: 2,
                            color: StorefrontColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.color.nameAr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
                color: widget.available
                    ? widget.selected
                          ? StorefrontColors.ink
                          : StorefrontColors.mutedInk
                    : StorefrontColors.subtleInk,
                decoration: widget.available
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatefulWidget {
  const _GalleryThumbnail({
    required this.image,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final ProductImage image;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GalleryThumbnail> createState() => _GalleryThumbnailState();
}

class _GalleryThumbnailState extends State<_GalleryThumbnail> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? StorefrontColors.focus
        : widget.selected
        ? StorefrontColors.ink
        : _hovered
        ? StorefrontColors.accent
        : StorefrontColors.line;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'الصورة ${widget.index + 1}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(StorefrontRadius.subtle),
          child: InkWell(
            key: ValueKey(
              'product-gallery-thumbnail-${widget.image.id ?? widget.index}',
            ),
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            onHover: (value) => setState(() => _hovered = value),
            borderRadius: BorderRadius.circular(StorefrontRadius.subtle),
            child: AnimatedContainer(
              duration: StorefrontMotion.resolve(
                context,
                StorefrontMotion.fast,
              ),
              curve: StorefrontMotion.curve,
              width: 74,
              height: 82,
              padding: EdgeInsets.all(widget.selected ? 3 : 4),
              decoration: BoxDecoration(
                color: StorefrontColors.surface,
                borderRadius: BorderRadius.circular(StorefrontRadius.subtle),
                border: Border.all(
                  color: borderColor,
                  width: _focused || widget.selected ? 2 : 1,
                ),
                boxShadow: widget.selected ? StorefrontShadows.subtle : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SafeProductImage(
                  url: widget.image.url,
                  width: 66,
                  height: 74,
                  fit: BoxFit.cover,
                  fallback: const ColoredBox(
                    color: StorefrontColors.surfaceMuted,
                    child: Icon(Icons.image_outlined),
                  ),
                ),
              ),
            ),
          ),
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
  bool _addSucceeded = false;
  Timer? _successTimer;

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
    _successTimer?.cancel();
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
      duration: StorefrontMotion.resolve(context, StorefrontMotion.deliberate),
      curve: StorefrontMotion.curve,
    );
  }

  Widget _galleryArrow({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: StorefrontColors.surface.withValues(alpha: .94),
      shape: const CircleBorder(side: BorderSide(color: StorefrontColors.line)),
      elevation: onPressed == null ? 0 : 2,
      shadowColor: StorefrontColors.ink.withValues(alpha: .16),
      child: IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }

  Widget _gallery(List<ProductImage> images, {required bool isDesktop}) {
    final gallerySurface = AspectRatio(
      aspectRatio: isDesktop ? .9 : .86,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StorefrontColors.surfaceMuted,
          borderRadius: StorefrontRadius.surfaceBorder,
          border: Border.all(color: StorefrontColors.line),
          boxShadow: StorefrontShadows.subtle,
        ),
        child: ClipRRect(
          borderRadius: StorefrontRadius.surfaceBorder,
          child: images.isEmpty
              ? Semantics(
                  image: true,
                  label: 'لا تتوفر صورة لهذا المنتج',
                  child: const ColoredBox(
                    color: StorefrontColors.surfaceMuted,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: StorefrontColors.subtleInk,
                      ),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: PageView.builder(
                          key: const ValueKey('product-gallery-page-view'),
                          controller: _galleryController,
                          itemCount: images.length,
                          onPageChanged: (index) {
                            if (!mounted || index == _galleryIndex) return;
                            setState(() => _galleryIndex = index);
                          },
                          itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.all(isDesktop ? 28 : 16),
                            child: AnimatedSwitcher(
                              duration: StorefrontMotion.resolve(
                                context,
                                StorefrontMotion.standard,
                              ),
                              switchInCurve: StorefrontMotion.curve,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: SafeProductImage(
                                key: ValueKey(
                                  'product-gallery-image-${images[index].id ?? index}',
                                ),
                                url: images[index].url,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                semanticLabel:
                                    'صورة ${index + 1} من صور ${product.name}',
                                fallback: const Center(
                                  child: Icon(Icons.image_outlined, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: Semantics(
                        liveRegion: true,
                        label:
                            'الصورة ${_galleryIndex + 1} من ${images.length}',
                        child: ExcludeSemantics(
                          child: Container(
                            key: const ValueKey('product-gallery-counter'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: StorefrontColors.ink.withValues(alpha: .9),
                              borderRadius: StorefrontRadius.controlBorder,
                            ),
                            child: Text(
                              '${_galleryIndex + 1} / ${images.length}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: StorefrontColors.onDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isDesktop && images.length > 1) ...[
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _galleryArrow(
                            key: const ValueKey('product-gallery-previous'),
                            tooltip: 'الصورة السابقة',
                            icon: Icons.chevron_left_rounded,
                            onPressed: _galleryIndex > 0
                                ? () => _selectGalleryImage(_galleryIndex - 1)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _galleryArrow(
                            key: const ValueKey('product-gallery-next'),
                            tooltip: 'الصورة التالية',
                            icon: Icons.chevron_right_rounded,
                            onPressed: _galleryIndex < images.length - 1
                                ? () => _selectGalleryImage(_galleryIndex + 1)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );

    return Column(
      key: const ValueKey('product-details-gallery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        gallerySurface,
        if (images.length > 1) ...[
          const SizedBox(height: StorefrontSpacing.sm),
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < images.length; index++)
                    Semantics(
                      button: true,
                      selected: index == _galleryIndex,
                      label: 'عرض الصورة ${index + 1}',
                      child: InkWell(
                        key: ValueKey('product-gallery-dot-$index'),
                        customBorder: const CircleBorder(),
                        onTap: () => _selectGalleryImage(index),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: AnimatedContainer(
                              duration: StorefrontMotion.resolve(
                                context,
                                StorefrontMotion.fast,
                              ),
                              curve: StorefrontMotion.curve,
                              width: index == _galleryIndex ? 24 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: index == _galleryIndex
                                    ? StorefrontColors.ink
                                    : StorefrontColors.line,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: StorefrontSpacing.xs),
          SizedBox(
            height: 82,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in images.asMap().entries) ...[
                    if (entry.key > 0)
                      const SizedBox(width: StorefrontSpacing.xs),
                    _GalleryThumbnail(
                      image: entry.value,
                      index: entry.key,
                      selected: entry.key == _galleryIndex,
                      onTap: () => _selectGalleryImage(entry.key),
                    ),
                  ],
                ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _addToCart({
    required List<ProductColor> colors,
    required String? selectedColor,
    required List<String> sizes,
    required String? selectedSize,
  }) {
    if (colors.length > 1 && selectedColor == null) {
      _showMessage('يرجى اختيار اللون أولاً');
      return;
    }
    if (sizes.length > 1 && selectedSize == null) {
      _showMessage('يرجى اختيار المقاس أولاً');
      return;
    }

    final before = store.itemCount;
    store.add(product, size: selectedSize, colorId: selectedColor);
    if (store.itemCount == before) {
      _showMessage('هذا الخيار غير متوفر حالياً');
      return;
    }

    _successTimer?.cancel();
    setState(() => _addSucceeded = true);
    _successTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _addSucceeded = false);
    });
    _showMessage('تمت الإضافة إلى السلة');
  }

  Widget _productInformation({
    required List<ProductColor> colors,
    required String? selectedColor,
    required List<String> sizes,
    required String? selectedSize,
    required bool isDesktop,
  }) {
    final selectedColorName = product.colorById(selectedColor)?.nameAr;
    final colorTitle = selectedColorName == null || selectedColorName.isEmpty
        ? 'اللون'
        : 'اللون: $selectedColorName';
    final effectiveSize =
        selectedSize ?? (sizes.length == 1 ? sizes.first : null);
    final sizeTitle = effectiveSize == null
        ? 'المقاس'
        : 'المقاس: $effectiveSize';
    final quantity = store.items
        .where(
          (item) =>
              item.product == product &&
              item.colorId == selectedColor &&
              item.size == selectedSize,
        )
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final selectedStock = effectiveSize == null
        ? 0
        : product.stockFor(effectiveSize, colorId: selectedColor);
    final optionsSelected =
        (colors.length <= 1 || selectedColor != null) &&
        (sizes.length <= 1 || selectedSize != null);
    final stockLimitReached =
        optionsSelected && selectedStock > 0 && quantity >= selectedStock;
    final selectedOptionUnavailable = optionsSelected && selectedStock <= 0;
    final canSubmit = !stockLimitReached && !selectedOptionUnavailable;
    final bodyTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          product.category,
          style: bodyTheme.labelLarge?.copyWith(
            color: StorefrontColors.accent,
            fontSize: 12,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: StorefrontSpacing.sm),
        Text(
          product.name,
          style:
              (isDesktop ? bodyTheme.headlineLarge : bodyTheme.headlineMedium)
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: -.4,
                  ),
        ),
        const SizedBox(height: StorefrontSpacing.md),
        Text(
          '${product.price.toStringAsFixed(0)} د.ل',
          textDirection: TextDirection.rtl,
          style: bodyTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        if (product.description.isNotEmpty) ...[
          const SizedBox(height: StorefrontSpacing.lg),
          Text(
            product.description,
            style: bodyTheme.bodyLarge?.copyWith(
              color: StorefrontColors.mutedInk,
              height: 1.75,
            ),
          ),
        ],
        const SizedBox(height: StorefrontSpacing.xl),
        const Divider(),
        if (colors.isNotEmpty) ...[
          const SizedBox(height: StorefrontSpacing.lg),
          Text(
            colorTitle,
            style: bodyTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: StorefrontSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                for (var index = 0; index < colors.length; index++) ...[
                  if (index > 0) const SizedBox(width: StorefrontSpacing.sm),
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
          const SizedBox(height: StorefrontSpacing.lg),
          const Divider(),
        ],
        const SizedBox(height: StorefrontSpacing.lg),
        Text(
          sizeTitle,
          style: bodyTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: StorefrontSpacing.md),
        Wrap(
          spacing: StorefrontSpacing.xs,
          runSpacing: StorefrontSpacing.xs,
          children: sizes.map((size) {
            final available =
                product.stockFor(size, colorId: selectedColor) > 0;
            final selected = size == effectiveSize;
            return Tooltip(
              message: available
                  ? 'اختيار المقاس $size'
                  : 'غير متوفر بهذا اللون',
              child: Semantics(
                button: true,
                enabled: available,
                selected: selected,
                label: 'المقاس $size${available ? '' : '، غير متوفر'}',
                child: ChoiceChip(
                  key: ValueKey('product-size-$size'),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 38),
                    child: Text(
                      size,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  avatar: !available
                      ? const Icon(Icons.close_rounded, size: 16)
                      : selected
                      ? const Icon(Icons.check_rounded, size: 16)
                      : null,
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: StorefrontColors.ink,
                  backgroundColor: StorefrontColors.surface,
                  disabledColor: StorefrontColors.surfaceMuted,
                  labelStyle: bodyTheme.labelLarge?.copyWith(
                    color: selected
                        ? StorefrontColors.onDark
                        : available
                        ? StorefrontColors.ink
                        : StorefrontColors.subtleInk,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: selected
                        ? StorefrontColors.ink
                        : available
                        ? StorefrontColors.line
                        : StorefrontColors.line.withValues(alpha: .7),
                    width: selected ? 1.6 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      StorefrontRadius.control,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StorefrontSpacing.sm,
                    vertical: StorefrontSpacing.sm,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: available
                      ? (_) => store.selectSize(product, size)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: StorefrontSpacing.lg),
        const Divider(),
        const SizedBox(height: StorefrontSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final label = Text(
              'الكمية',
              style: bodyTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            );
            final control = Semantics(
              label: 'الكمية المختارة',
              value: '$quantity',
              child: ExcludeSemantics(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    decoration: BoxDecoration(
                      color: StorefrontColors.surface,
                      border: Border.all(color: StorefrontColors.line),
                      borderRadius: StorefrontRadius.controlBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: const ValueKey('product-quantity-decrease'),
                          tooltip: 'إنقاص الكمية',
                          onPressed: quantity > 0
                              ? () => store.remove(
                                  product,
                                  size: selectedSize,
                                  colorId: selectedColor,
                                )
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Container(
                          key: const ValueKey('product-details-quantity'),
                          width: 46,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: StorefrontColors.line,
                              ),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: StorefrontMotion.resolve(
                              context,
                              StorefrontMotion.fast,
                            ),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: Text(
                              '$quantity',
                              key: ValueKey(quantity),
                              textAlign: TextAlign.center,
                              style: bodyTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('product-quantity-increase'),
                          tooltip: 'زيادة الكمية',
                          onPressed: optionsSelected && quantity < selectedStock
                              ? () => store.add(
                                  product,
                                  size: selectedSize,
                                  colorId: selectedColor,
                                )
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label,
                      const SizedBox(height: StorefrontSpacing.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: control,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [label, control],
                  );
          },
        ),
        const SizedBox(height: StorefrontSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: FilledButton(
              key: const ValueKey('product-details-add'),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  _addSucceeded
                      ? StorefrontColors.success
                      : StorefrontColors.ink,
                ),
                foregroundColor: const WidgetStatePropertyAll(
                  StorefrontColors.onDark,
                ),
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return const BorderSide(
                      color: StorefrontColors.focus,
                      width: 2.4,
                    );
                  }
                  return BorderSide.none;
                }),
              ),
              onPressed: canSubmit
                  ? () => _addToCart(
                      colors: colors,
                      selectedColor: selectedColor,
                      sizes: sizes,
                      selectedSize: selectedSize,
                    )
                  : null,
              child: AnimatedSwitcher(
                duration: StorefrontMotion.resolve(
                  context,
                  StorefrontMotion.standard,
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .97, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(
                    _addSucceeded
                        ? 'success'
                        : canSubmit
                        ? 'ready'
                        : 'disabled',
                  ),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _addSucceeded
                          ? Icons.check_circle_outline_rounded
                          : Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(width: StorefrontSpacing.sm),
                    Flexible(
                      child: Text(
                        _addSucceeded
                            ? 'تمت الإضافة'
                            : stockLimitReached
                            ? 'اكتملت الكمية المتاحة'
                            : selectedOptionUnavailable
                            ? 'غير متوفر حالياً'
                            : 'إضافة إلى السلة',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: StorefrontSpacing.sm),
        Text(
          stockLimitReached
              ? 'لا يمكن إضافة كمية أكبر من المخزون المتاح.'
              : colors.isEmpty
              ? 'اختر المقاس المناسب قبل الإضافة.'
              : 'اختر اللون والمقاس المناسبين قبل الإضافة.',
          textAlign: TextAlign.center,
          style: bodyTheme.bodySmall?.copyWith(
            color: StorefrontColors.subtleInk,
          ),
        ),
      ],
    );
  }

  Widget _backControl({required bool isDesktop}) {
    if (isDesktop) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          key: const ValueKey('product-details-back'),
          onPressed: _goBack,
          icon: const BackButtonIcon(),
          label: const Text('العودة إلى المتجر'),
          style: OutlinedButton.styleFrom(
            backgroundColor: StorefrontColors.surface,
            foregroundColor: StorefrontColors.ink,
            side: const BorderSide(color: StorefrontColors.line),
          ),
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: StorefrontColors.surface,
        shape: const CircleBorder(
          side: BorderSide(color: StorefrontColors.line),
        ),
        child: IconButton(
          key: const ValueKey('product-details-back'),
          tooltip: 'رجوع',
          onPressed: _goBack,
          icon: const BackButtonIcon(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StorefrontTheme(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
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
                  final isDesktop =
                      constraints.maxWidth >= StorefrontLayout.desktop;
                  final gallery = _gallery(galleryImages, isDesktop: isDesktop);
                  final information = Directionality(
                    textDirection: TextDirection.rtl,
                    child: _productInformation(
                      colors: colors,
                      selectedColor: selectedColor,
                      sizes: sizes,
                      selectedSize: selectedSize,
                      isDesktop: isDesktop,
                    ),
                  );
                  final content = isDesktop
                      ? Row(
                          key: const ValueKey('product-details-desktop-layout'),
                          textDirection: TextDirection.ltr,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 59, child: gallery),
                            SizedBox(
                              width: constraints.maxWidth >= 1320 ? 72 : 48,
                            ),
                            Expanded(
                              flex: 41,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: information,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('product-details-mobile-layout'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            gallery,
                            const SizedBox(height: StorefrontSpacing.xl),
                            information,
                          ],
                        );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      StorefrontLayout.gutterFor(constraints.maxWidth),
                      isDesktop ? StorefrontSpacing.lg : StorefrontSpacing.sm,
                      StorefrontLayout.gutterFor(constraints.maxWidth),
                      StorefrontSpacing.xxl +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _backControl(isDesktop: isDesktop),
                              SizedBox(
                                height: isDesktop
                                    ? StorefrontSpacing.lg
                                    : StorefrontSpacing.md,
                              ),
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
    final width = MediaQuery.sizeOf(context).width;
    final logoWidth = width < StorefrontLayout.narrow ? 88.0 : 104.0;
    return Material(
      color: StorefrontColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: StorefrontColors.line)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: StorefrontLayout.gutterFor(width),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image(
                  key: const ValueKey('product-details-logo'),
                  image: const AssetImage('assets/images/iron_sam_logo.png'),
                  semanticLabel: 'آيرون سام',
                  width: logoWidth,
                  height: 56,
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
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            child: Semantics(
              liveRegion: true,
              label: 'عدد المنتجات في السلة: ${store.itemCount}',
              child: ExcludeSemantics(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: const BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${store.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
