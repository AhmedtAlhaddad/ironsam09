import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/storefront_theme.dart';
import '../core/utils/image_url_policy.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../pages/catalog/product_details_page.dart';
import 'safe_product_image.dart';

class HeroImageSource {
  const HeroImageSource({required this.url, required this.productName});

  final String url;
  final String productName;
}

List<HeroImageSource> buildHeroImageSources(Iterable<Product> products) {
  final seenUrls = <String>{};
  final sources = <HeroImageSource>[];

  for (final product in products) {
    final candidates = <String>[
      product.imageUrl,
      ...product.imageUrls,
      ...product.images.map((image) => image.url),
    ];
    String? representativeUrl;
    for (final candidate in candidates) {
      final safeUrl = safeProductImageUrl(candidate);
      if (safeUrl != null) {
        representativeUrl = safeUrl;
        break;
      }
    }
    if (representativeUrl == null || !seenUrls.add(representativeUrl)) {
      continue;
    }
    sources.add(
      HeroImageSource(url: representativeUrl, productName: product.name),
    );
  }

  return List.unmodifiable(sources);
}

class IronSamLogo extends StatelessWidget {
  const IronSamLogo({this.width = 96, this.height = 58, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/iron_sam_logo.png',
        semanticLabel: 'آيرون سام',
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class DeliveryBanner extends StatelessWidget {
  const DeliveryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: inkColor,
      padding: const EdgeInsets.symmetric(
        horizontal: StorefrontSpacing.md,
        vertical: StorefrontSpacing.xs,
      ),
      child: const Text(
        'توصيل إلى جميع أنحاء ليبيا',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StoreHeader extends StatelessWidget {
  const StoreHeader({
    required this.store,
    required this.activeSection,
    required this.onMenPressed,
    required this.onWomenPressed,
    required this.onAllPressed,
    required this.onCartPressed,
    super.key,
  });

  final StoreState store;
  final String activeSection;
  final VoidCallback onMenPressed;
  final VoidCallback onWomenPressed;
  final VoidCallback onAllPressed;
  final VoidCallback onCartPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= StorefrontLayout.tablet;
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: lineColor)),
            color: StorefrontColors.surface,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: StorefrontLayout.gutterFor(constraints.maxWidth),
            vertical: StorefrontSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                flex: isWide ? 1 : 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      if (!isWide)
                        IconButton(
                          tooltip: 'القائمة',
                          onPressed: () => _showMobileMenu(context),
                          icon: const Icon(Icons.menu),
                        ),
                      const IronSamLogo(width: 92, height: 54),
                    ],
                  ),
                ),
              ),
              if (isWide)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderLink(
                          label: 'الرجال',
                          active: activeSection == 'الرجال',
                          onPressed: onMenPressed,
                        ),
                        SizedBox(width: StorefrontSpacing.md),
                        _HeaderLink(
                          label: 'النساء',
                          active: activeSection == 'النساء',
                          onPressed: onWomenPressed,
                        ),
                        SizedBox(width: StorefrontSpacing.md),
                        _HeaderLink(
                          label: 'الكل',
                          active: activeSection == 'الكل',
                          onPressed: onAllPressed,
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedBuilder(
                      animation: store,
                      builder: (context, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              tooltip: 'سلة التسوق',
                              onPressed: onCartPressed,
                              icon: const Icon(Icons.shopping_bag_outlined),
                            ),
                            if (store.itemCount > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Semantics(
                                  liveRegion: true,
                                  label:
                                      'عدد المنتجات في السلة: ${store.itemCount}',
                                  child: ExcludeSemantics(
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
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
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: canvasColor,
      builder: (sheetContext) {
        void select(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'القائمة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق القائمة',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(color: lineColor),
                  _MobileMenuItem(
                    label: 'الكل',
                    active: activeSection == 'الكل',
                    onTap: () => select(onAllPressed),
                  ),
                  _MobileMenuItem(
                    label: 'الرجال',
                    active: activeSection == 'الرجال',
                    onTap: () => select(onMenPressed),
                  ),
                  _MobileMenuItem(
                    label: 'النساء',
                    active: activeSection == 'النساء',
                    onTap: () => select(onWomenPressed),
                  ),
                  _MobileMenuItem(
                    label: 'سلة التسوق',
                    onTap: () => select(onCartPressed),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  const _MobileMenuItem({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: active ? accentColor : inkColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: Icon(
        Icons.arrow_back,
        color: active ? accentColor : Colors.black54,
        size: 19,
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active ? accentColor : inkColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(48, 48),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: AnimatedContainer(
        duration: StorefrontMotion.fast,
        curve: StorefrontMotion.curve,
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.title,
    required this.heroProducts,
    required this.onShopPressed,
    super.key,
  });

  final String title;
  final List<Product> heroProducts;
  final VoidCallback onShopPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600;
        final isPhone = !isTablet;
        final mediaQuery = MediaQuery.of(context);
        final usableViewportHeight = math.max(
          0.0,
          mediaQuery.size.height - mediaQuery.padding.vertical,
        );
        final compactMobile = isPhone && usableViewportHeight < 700;
        final image = _RotatingHeroImage(
          sources: buildHeroImageSources(heroProducts),
          cacheWidth:
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round(),
        );
        final copy = _HeroCopy(
          title: title,
          onShopPressed: onShopPressed,
          isDesktop: isDesktop,
          isNarrow: constraints.maxWidth < StorefrontLayout.narrow,
          compactMobile: compactMobile,
        );
        final phoneImageHeight = math
            .min(
              constraints.maxWidth / (compactMobile ? 1.5 : 1.16),
              usableViewportHeight * (compactMobile ? .31 : .38),
            )
            .clamp(168.0, 344.0);

        return Semantics(
          container: true,
          label: 'تشكيلة آيرون سام: $title',
          child: Container(
            width: double.infinity,
            height: isDesktop
                ? (constraints.maxWidth * .42).clamp(480.0, 600.0)
                : null,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: StorefrontColors.ink,
              borderRadius: const BorderRadius.all(
                Radius.circular(StorefrontRadius.subtle),
              ),
              border: Border.all(color: StorefrontColors.ink),
              boxShadow: StorefrontShadows.raised,
            ),
            child: isDesktop
                ? Row(
                    key: const ValueKey('catalog-hero-desktop'),
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 9, child: copy),
                      Expanded(flex: 11, child: image),
                    ],
                  )
                : Column(
                    key: const ValueKey('catalog-hero-mobile'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: isPhone
                        ? [
                            copy,
                            SizedBox(
                              key: const ValueKey('catalog-hero-mobile-image'),
                              height: phoneImageHeight,
                              child: image,
                            ),
                          ]
                        : [AspectRatio(aspectRatio: 1.72, child: image), copy],
                  ),
          ),
        );
      },
    );
  }
}

class _RotatingHeroImage extends StatefulWidget {
  const _RotatingHeroImage({required this.sources, required this.cacheWidth});

  static const rotationInterval = Duration(milliseconds: 2500);
  static const transitionDuration = Duration(milliseconds: 380);

  final List<HeroImageSource> sources;
  final int cacheWidth;

  @override
  State<_RotatingHeroImage> createState() => _RotatingHeroImageState();
}

class _RotatingHeroImageState extends State<_RotatingHeroImage> {
  Timer? _rotationTimer;
  int _activeIndex = 0;
  bool? _reducedMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
      _activeIndex = 0;
    } else {
      _restartTimer();
    }
  }

  @override
  void didUpdateWidget(covariant _RotatingHeroImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameSources(oldWidget.sources, widget.sources)) return;

    final previousUrl = oldWidget.sources.isEmpty
        ? null
        : oldWidget
              .sources[_activeIndex.clamp(0, oldWidget.sources.length - 1)]
              .url;
    final retainedIndex = previousUrl == null
        ? -1
        : widget.sources.indexWhere((source) => source.url == previousUrl);
    _activeIndex = retainedIndex >= 0 ? retainedIndex : 0;
    _restartTimer();
  }

  bool _sameSources(
    List<HeroImageSource> previous,
    List<HeroImageSource> current,
  ) {
    if (identical(previous, current)) return true;
    if (previous.length != current.length) return false;
    for (var index = 0; index < previous.length; index++) {
      if (previous[index].url != current[index].url) return false;
    }
    return true;
  }

  void _restartTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    if (_reducedMotion != false || widget.sources.length < 2) return;

    _rotationTimer = Timer.periodic(_RotatingHeroImage.rotationInterval, (_) {
      if (!mounted || widget.sources.length < 2) return;
      setState(() {
        _activeIndex = (_activeIndex + 1) % widget.sources.length;
      });
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.sources.isEmpty
        ? null
        : widget.sources[_activeIndex.clamp(0, widget.sources.length - 1)];
    final reducedMotion = _reducedMotion ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          image: true,
          label: 'صور منتجات من تشكيلة آيرون سام',
          child: ExcludeSemantics(
            child: AnimatedSwitcher(
              duration: reducedMotion
                  ? Duration.zero
                  : _RotatingHeroImage.transitionDuration,
              switchInCurve: StorefrontMotion.curve,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) {
                if (reducedMotion) return child;
                final scale = Tween<double>(begin: .985, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: StorefrontMotion.curve,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: scale, child: child),
                );
              },
              child: SafeProductImage(
                key: ValueKey(source?.url ?? 'hero-image-fallback'),
                url: source?.url,
                fit: BoxFit.cover,
                cacheWidth: widget.cacheWidth,
                filterQuality: FilterQuality.medium,
                fallback: ColoredBox(
                  color: StorefrontColors.surfaceMuted,
                  child: Center(
                    child: Opacity(
                      opacity: .2,
                      child: IronSamLogo(width: 180, height: 110),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const PositionedDirectional(
          top: 0,
          bottom: 0,
          start: 0,
          child: SizedBox(
            width: 5,
            child: ColoredBox(color: StorefrontColors.accent),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    StorefrontColors.ink.withValues(alpha: .16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.title,
    required this.onShopPressed,
    required this.isDesktop,
    required this.isNarrow,
    required this.compactMobile,
  });

  final String title;
  final VoidCallback onShopPressed;
  final bool isDesktop;
  final bool isNarrow;
  final bool compactMobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactDesktop = isDesktop && constraints.maxWidth < 520;
        final headingSize = isDesktop
            ? compactDesktop
                  ? 38.0
                  : 52.0
            : compactMobile
            ? isNarrow
                  ? 31.0
                  : 34.0
            : isNarrow
            ? 34.0
            : 40.0;
        final horizontalPadding = compactDesktop
            ? StorefrontSpacing.xl
            : isDesktop
            ? StorefrontSpacing.xxl
            : compactMobile
            ? StorefrontSpacing.md
            : isNarrow
            ? StorefrontSpacing.md
            : StorefrontSpacing.lg;
        final verticalPadding = compactDesktop
            ? StorefrontSpacing.xl
            : isDesktop
            ? StorefrontSpacing.xxl
            : compactMobile
            ? StorefrontSpacing.sm
            : StorefrontSpacing.xl;

        return Container(
          color: StorefrontColors.ink,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مجموعة آيرون سام · $title',
                style: const TextStyle(
                  color: StorefrontColors.surfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(
                height: compactDesktop
                    ? StorefrontSpacing.md
                    : isDesktop
                    ? StorefrontSpacing.lg
                    : compactMobile
                    ? StorefrontSpacing.sm
                    : StorefrontSpacing.md,
              ),
              ExcludeSemantics(
                child: Text(
                  'صُممت للحركة.\nوبُنيت للحضور.',
                  style: TextStyle(
                    color: StorefrontColors.onDark,
                    fontSize: headingSize,
                    height: compactMobile ? 1.18 : 1.22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                height: compactMobile
                    ? StorefrontSpacing.sm
                    : StorefrontSpacing.md,
              ),
              Text(
                'ملابس رياضية عالية الأداء تجمع بين الراحة والقوة وأسلوب آيرون سام الواثق.',
                style: TextStyle(
                  color: StorefrontColors.line,
                  fontSize: compactDesktop || compactMobile ? 14 : 16,
                  height: compactMobile ? 1.55 : 1.7,
                ),
              ),
              SizedBox(
                height: compactDesktop
                    ? StorefrontSpacing.lg
                    : isDesktop
                    ? StorefrontSpacing.xl
                    : compactMobile
                    ? StorefrontSpacing.md
                    : StorefrontSpacing.lg,
              ),
              SizedBox(
                width: isDesktop ? null : double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('catalog-hero-cta'),
                  onPressed: onShopPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: StorefrontColors.surface,
                    foregroundColor: StorefrontColors.ink,
                    padding: EdgeInsets.symmetric(
                      horizontal: StorefrontSpacing.lg,
                      vertical: compactMobile ? 13 : StorefrontSpacing.md,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  label: const Text('تسوق التشكيلة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CatalogSectionHeading extends StatelessWidget {
  const CatalogSectionHeading({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مختارات آيرون سام',
                style: TextStyle(
                  color: StorefrontColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: StorefrontSpacing.xs),
              Text(
                'تسوق التشكيلة',
                style: TextStyle(
                  color: StorefrontColors.ink,
                  fontSize: compact ? 28 : 36,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
          final contextWidget = Text(
            title == 'الكل' ? 'كل القطع' : 'تشكيلة $title',
            style: const TextStyle(
              color: StorefrontColors.mutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: StorefrontSpacing.sm),
                contextWidget,
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [titleWidget, contextWidget],
          );
        },
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.query,
    required this.onQueryChanged,
    this.searchFocusNode,
    super.key,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final FocusNode? searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final categoryStrip = SizedBox(
          height: 52,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView.separated(
              padding: EdgeInsetsDirectional.only(
                start: isWide ? 0 : 4,
                end: isWide ? 0 : 4,
                bottom: 0,
              ),
              scrollDirection: Axis.horizontal,
              primary: false,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final active = category == selectedCategory;
                return _CategoryFilterChip(
                  label: category,
                  selected: active,
                  onPressed: () => onCategoryChanged(category),
                );
              },
            ),
          ),
        );
        final searchField = _CatalogSearchField(
          focusNode: searchFocusNode,
          onChanged: onQueryChanged,
        );

        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: lineColor)),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: categoryStrip),
                    const SizedBox(width: StorefrontSpacing.lg),
                    SizedBox(width: 360, child: searchField),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    categoryStrip,
                    const SizedBox(height: StorefrontSpacing.md),
                    searchField,
                  ],
                ),
        );
      },
    );
  }
}

class _CategoryFilterChip extends StatefulWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_CategoryFilterChip> createState() => _CategoryFilterChipState();
}

class _CategoryFilterChipState extends State<_CategoryFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final background = selected
        ? StorefrontColors.ink
        : _pressed
        ? StorefrontColors.surfaceMuted
        : _hovered
        ? const Color(0xFFF2EFE9)
        : StorefrontColors.surface;
    final duration = StorefrontMotion.resolve(context, StorefrontMotion.fast);

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: AnimatedContainer(
        duration: duration,
        curve: StorefrontMotion.curve,
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(
            Radius.circular(StorefrontRadius.subtle),
          ),
          border: Border.all(
            color: selected ? StorefrontColors.ink : StorefrontColors.line,
          ),
          boxShadow: [
            if (selected)
              const BoxShadow(
                color: StorefrontColors.accent,
                offset: Offset(0, 3),
              ),
            if (_focused)
              const BoxShadow(
                color: StorefrontColors.focus,
                blurRadius: 0,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(() => _focused = value),
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: const BorderRadius.all(
              Radius.circular(StorefrontRadius.subtle),
            ),
            mouseCursor: SystemMouseCursors.click,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected
                          ? StorefrontColors.onDark
                          : StorefrontColors.ink,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
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

class _CatalogSearchField extends StatefulWidget {
  const _CatalogSearchField({required this.onChanged, this.focusNode});

  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  State<_CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<_CatalogSearchField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _syncFocusNode();
  }

  @override
  void didUpdateWidget(covariant _CatalogSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    _syncFocusNode();
  }

  void _syncFocusNode() {
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'البحث في المنتجات',
      child: AnimatedContainer(
        duration: StorefrontMotion.resolve(context, StorefrontMotion.standard),
        curve: StorefrontMotion.curve,
        decoration: BoxDecoration(
          borderRadius: StorefrontRadius.controlBorder,
          boxShadow: _focusNode.hasFocus ? StorefrontShadows.subtle : const [],
        ),
        child: TextField(
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'ابحث عن المنتجات...',
            prefixIcon: Icon(Icons.search, color: StorefrontColors.mutedInk),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }
}

int _catalogColumnCount(double width) {
  if (width >= 1280) return 5;
  if (width >= 900) return 4;
  if (width >= 680) return 3;
  return 2;
}

double _catalogCrossSpacing(double width) {
  if (width >= 1280) return StorefrontSpacing.xl;
  if (width >= 900) return 28;
  if (width >= 680) return StorefrontSpacing.lg;
  if (width < StorefrontLayout.narrow) return 10;
  return StorefrontSpacing.md;
}

double _catalogMainSpacing(double width) {
  if (width >= 900) return StorefrontSpacing.xxl;
  if (width >= 680) return 40;
  return StorefrontSpacing.xl;
}

double _catalogCardAspectRatio(double width) {
  if (width >= 1280) return .64;
  if (width >= 900) return .62;
  if (width >= 680) return .58;
  if (width < StorefrontLayout.narrow) return .52;
  return .55;
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    required this.store,
    this.onSearchPressed,
    super.key,
  });

  final List<Product> products;
  final StoreState store;
  final VoidCallback? onSearchPressed;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Text('لا توجد منتجات مطابقة للبحث.')),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _catalogColumnCount(width);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: _catalogCrossSpacing(width),
            mainAxisSpacing: _catalogMainSpacing(width),
            childAspectRatio: _catalogCardAspectRatio(width),
          ),
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
            store: store,
            onSearchPressed: onSearchPressed,
          ),
        );
      },
    );
  }
}

class CatalogResults extends StatelessWidget {
  const CatalogResults({
    required this.isLoading,
    required this.error,
    required this.products,
    required this.store,
    required this.hasActiveFilter,
    required this.onRetry,
    this.onSearchPressed,
    super.key,
  });

  final bool isLoading;
  final String? error;
  final List<Product> products;
  final StoreState store;
  final bool hasActiveFilter;
  final VoidCallback onRetry;
  final VoidCallback? onSearchPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (products.isEmpty) return const _CatalogLoadingState();
      return Semantics(
        key: const ValueKey('catalog-loading-state'),
        container: true,
        liveRegion: true,
        label: 'جاري تحديث المنتجات',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: StorefrontSpacing.lg),
            ProductGrid(
              products: products,
              store: store,
              onSearchPressed: onSearchPressed,
            ),
          ],
        ),
      );
    }

    if (error != null && products.isEmpty) {
      return _CatalogStatePanel(
        key: const ValueKey('catalog-error-state'),
        icon: Icons.wifi_off_outlined,
        title: 'تعذّر تحميل المنتجات',
        message: 'تحقق من اتصالك وحاول مرة أخرى.',
        actionLabel: 'إعادة المحاولة',
        onAction: onRetry,
        isError: true,
      );
    }

    if (products.isEmpty) {
      return _CatalogStatePanel(
        key: const ValueKey('catalog-empty-state'),
        icon: hasActiveFilter
            ? Icons.search_off_outlined
            : Icons.inventory_2_outlined,
        title: hasActiveFilter
            ? 'لا توجد نتائج مطابقة'
            : 'لا توجد منتجات حاليًا',
        message: hasActiveFilter
            ? 'جرّب كلمة بحث أخرى أو تصفّح فئة مختلفة.'
            : 'ستظهر التشكيلة الجديدة هنا فور توفرها.',
        actionLabel: hasActiveFilter ? 'العودة إلى البحث' : null,
        onAction: hasActiveFilter ? onSearchPressed : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          _CatalogErrorNotice(onRetry: onRetry),
          const SizedBox(height: StorefrontSpacing.lg),
        ],
        ProductGrid(
          products: products,
          store: store,
          onSearchPressed: onSearchPressed,
        ),
      ],
    );
  }
}

class _CatalogLoadingState extends StatelessWidget {
  const _CatalogLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('catalog-loading-state'),
      container: true,
      liveRegion: true,
      label: 'جاري تحميل المنتجات',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = _catalogColumnCount(width);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: StorefrontSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: columns * 2,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: _catalogCrossSpacing(width),
                  mainAxisSpacing: _catalogMainSpacing(width),
                  childAspectRatio: _catalogCardAspectRatio(width),
                ),
                itemBuilder: (context, index) => ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: .55, end: 1),
                    duration: StorefrontMotion.resolve(
                      context,
                      StorefrontMotion.deliberate,
                    ),
                    curve: StorefrontMotion.curve,
                    builder: (context, value, child) =>
                        Opacity(opacity: value, child: child),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: StorefrontColors.surfaceMuted,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(StorefrontRadius.subtle),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: StorefrontSpacing.md),
                        Container(
                          height: 14,
                          color: StorefrontColors.surfaceMuted,
                        ),
                        const SizedBox(height: StorefrontSpacing.xs),
                        FractionallySizedBox(
                          widthFactor: .55,
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            height: 14,
                            color: StorefrontColors.surfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogErrorNotice extends StatelessWidget {
  const _CatalogErrorNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(StorefrontSpacing.md),
        decoration: BoxDecoration(
          color: StorefrontColors.surface,
          border: Border.all(color: StorefrontColors.error),
          borderRadius: StorefrontRadius.controlBorder,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: StorefrontSpacing.md,
          runSpacing: StorefrontSpacing.sm,
          children: [
            const Text(
              'تعذّر تحديث التشكيلة. نعرض المنتجات المتوفرة حاليًا.',
              style: TextStyle(
                color: StorefrontColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogStatePanel extends StatelessWidget {
  const _CatalogStatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: isError,
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.all(StorefrontSpacing.xl),
        decoration: BoxDecoration(
          color: StorefrontColors.surface,
          border: Border.all(color: StorefrontColors.line),
          borderRadius: StorefrontRadius.surfaceBorder,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 38,
              color: isError
                  ? StorefrontColors.error
                  : StorefrontColors.mutedInk,
            ),
            const SizedBox(height: StorefrontSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: StorefrontSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: StorefrontSpacing.lg),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: Icon(isError ? Icons.refresh : Icons.search, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.store,
    this.onSearchPressed,
    super.key,
  });

  final Product product;
  final StoreState store;
  final VoidCallback? onSearchPressed;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  Product get product => widget.product;

  void openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(
          product: product,
          store: widget.store,
          onSearchPressed: widget.onSearchPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportsHover =
        MediaQuery.sizeOf(context).width >= StorefrontLayout.desktop;
    final elevated = _focused || (supportsHover && _hovered);
    final duration = StorefrontMotion.resolve(
      context,
      StorefrontMotion.standard,
    );
    final status = product.status.trim();
    final semanticPrice = product.price.toStringAsFixed(0);

    return Semantics(
      button: true,
      label:
          '${product.name}، السعر $semanticPrice دينار ليبي${status.isEmpty ? '' : '، $status'}',
      onTap: () => openDetails(context),
      child: ExcludeSemantics(
        child: AnimatedSlide(
          duration: duration,
          curve: StorefrontMotion.curve,
          offset: elevated ? const Offset(0, -.012) : Offset.zero,
          child: AnimatedScale(
            duration: StorefrontMotion.resolve(context, StorefrontMotion.fast),
            curve: StorefrontMotion.curve,
            scale: _pressed ? .992 : 1,
            child: AnimatedContainer(
              duration: duration,
              curve: StorefrontMotion.curve,
              decoration: BoxDecoration(
                color: StorefrontColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(StorefrontRadius.subtle),
                ),
                border: Border.all(
                  color: _focused
                      ? StorefrontColors.focus
                      : StorefrontColors.line,
                ),
                boxShadow: [
                  if (_focused)
                    const BoxShadow(
                      color: StorefrontColors.focus,
                      spreadRadius: 2,
                    ),
                  if (elevated) ...StorefrontShadows.subtle,
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: const BorderRadius.all(
                  Radius.circular(StorefrontRadius.subtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => openDetails(context),
                  onHover: (value) {
                    if (!supportsHover || _hovered == value) return;
                    setState(() => _hovered = value);
                  },
                  onFocusChange: (value) => setState(() => _focused = value),
                  onHighlightChanged: (value) =>
                      setState(() => _pressed = value),
                  mouseCursor: SystemMouseCursors.click,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cacheWidth =
                          (constraints.maxWidth *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRect(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AnimatedScale(
                                    duration: duration,
                                    curve: StorefrontMotion.curve,
                                    scale: supportsHover && _hovered
                                        ? 1.035
                                        : 1,
                                    child: ColoredBox(
                                      color: StorefrontColors.surfaceMuted,
                                      child: SafeProductImage(
                                        url: product.imageUrl,
                                        fit: BoxFit.cover,
                                        cacheWidth: cacheWidth,
                                        filterQuality: FilterQuality.medium,
                                        semanticLabel: product.name,
                                        fallback: const Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 34,
                                            color: StorefrontColors.mutedInk,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (status.isNotEmpty)
                                    PositionedDirectional(
                                      top: StorefrontSpacing.sm,
                                      start: StorefrontSpacing.sm,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 'جديد'
                                              ? StorefrontColors.accent
                                              : StorefrontColors.ink.withValues(
                                                  alpha: .9,
                                                ),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(2),
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                            color: StorefrontColors.onDark,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Tooltip(
                                  message: product.name,
                                  child: Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: StorefrontColors.ink,
                                      fontSize:
                                          MediaQuery.sizeOf(context).width >=
                                              StorefrontLayout.desktop
                                          ? 16
                                          : 14,
                                      height: 1.45,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: StorefrontSpacing.xs),
                                Text(
                                  '${product.price.toStringAsFixed(0)} د.ل',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: StorefrontColors.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: StorefrontColors.surface,
        border: Border.symmetric(horizontal: BorderSide(color: lineColor)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: StorefrontSpacing.md,
        vertical: StorefrontSpacing.lg,
      ),
      child: const Center(
        child: _TrustItem(
          icon: Icons.location_on_outlined,
          title: 'توصيل في ليبيا',
          detail: 'خيارات واضحة عند الدفع',
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accentColor, size: 23),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 12,
                color: StorefrontColors.mutedInk,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: StorefrontLayout.gutterFor(constraints.maxWidth),
          vertical: StorefrontSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: StorefrontColors.surface,
          border: Border(top: BorderSide(color: StorefrontColors.line)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: StorefrontLayout.contentMaxWidth,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: StorefrontSpacing.xl,
              runSpacing: StorefrontSpacing.md,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IronSamLogo(width: 118, height: 70),
                    SizedBox(height: 8),
                    Text(
                      'ملابس رياضية لكل حركة',
                      style: TextStyle(
                        color: StorefrontColors.mutedInk,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '© ${DateTime.now().year} آيرون سام. جميع الحقوق محفوظة.',
                  style: const TextStyle(
                    color: StorefrontColors.mutedInk,
                    fontSize: 12,
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
