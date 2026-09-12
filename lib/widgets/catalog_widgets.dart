import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/storefront_theme.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../pages/catalog/product_details_page.dart';

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
  const PageIntro({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth >= StorefrontLayout.desktop
            ? 56.0
            : constraints.maxWidth >= 600
            ? 44.0
            : constraints.maxWidth < StorefrontLayout.narrow
            ? 32.0
            : 36.0;
        final descriptionWidth =
            constraints.maxWidth > StorefrontLayout.readingMaxWidth
            ? StorefrontLayout.readingMaxWidth
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'جميع الملابس',
              style: TextStyle(
                color: StorefrontColors.mutedInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: inkColor,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
                children: [
                  TextSpan(text: title),
                  TextSpan(
                    text: '.',
                    style: TextStyle(color: accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: descriptionWidth,
              child: Text(
                'استكشف تشكيلة آيرون سام المختارة من الملابس الرياضية عالية الأداء. صُممت لتوفر لك الراحة والقوة في كل حركة، مع لمسة عصرية تناسب أسلوب حياتك اليومي.',
                style: TextStyle(
                  color: StorefrontColors.mutedInk,
                  fontSize: 16,
                  height: 1.75,
                ),
              ),
            ),
          ],
        );
      },
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
        final isWide = constraints.maxWidth >= StorefrontLayout.desktop;
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
                return ChoiceChip(
                  label: Text(category, textAlign: TextAlign.right),
                  selected: active,
                  onSelected: (_) => onCategoryChanged(category),
                  backgroundColor: Colors.white,
                  selectedColor: inkColor,
                  side: BorderSide(
                    color: active ? inkColor : lineColor,
                    width: active ? 1.4 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: active ? Colors.white : inkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  labelPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                  ),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                );
              },
            ),
          ),
        );
        final searchField = Semantics(
          textField: true,
          label: 'البحث في المنتجات',
          child: TextField(
            focusNode: searchFocusNode,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'ابحث عن المنتجات...',
              prefixIcon: Icon(Icons.search, color: StorefrontColors.mutedInk),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
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
                    SizedBox(width: 320, child: searchField),
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
        final isWideDesktop =
            constraints.maxWidth >= StorefrontLayout.wideDesktop;
        final isDesktop = constraints.maxWidth >= StorefrontLayout.desktop;
        final isTablet = constraints.maxWidth >= StorefrontLayout.tablet;
        final columns = isWideDesktop
            ? 5
            : isDesktop
            ? 4
            : isTablet
            ? 3
            : 2;
        final compact = constraints.maxWidth < StorefrontLayout.narrow;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: isDesktop
                ? StorefrontSpacing.xl
                : compact
                ? 10
                : StorefrontSpacing.md,
            mainAxisSpacing: isDesktop
                ? StorefrontSpacing.section
                : StorefrontSpacing.xxl,
            childAspectRatio: columns == 2
                ? constraints.maxWidth < 500
                      ? .48
                      : .49
                : isDesktop
                ? .58
                : .56,
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
          final columns = constraints.maxWidth >= StorefrontLayout.wideDesktop
              ? 5
              : constraints.maxWidth >= StorefrontLayout.desktop
              ? 4
              : constraints.maxWidth >= StorefrontLayout.tablet
              ? 3
              : 2;
          final gap = constraints.maxWidth < StorefrontLayout.narrow
              ? 10.0
              : 16.0;
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
                  crossAxisSpacing: gap,
                  mainAxisSpacing: StorefrontSpacing.xl,
                  childAspectRatio: .58,
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

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.store,
    this.onSearchPressed,
    super.key,
  });

  final Product product;
  final StoreState store;
  final VoidCallback? onSearchPressed;

  void openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(
          product: product,
          store: store,
          onSearchPressed: onSearchPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: .8,
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: surfaceColor,
                  child: InkWell(
                    onTap: () => openDetails(context),
                    child: Image.network(
                      product.imageUrl,
                      semanticLabel: product.name,
                      fit: BoxFit.cover,
                      color: Colors.white.withValues(alpha: .18),
                      colorBlendMode: BlendMode.saturation,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.image_outlined, size: 34),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 12,
                start: 12,
                child: Container(
                  color: product.status == 'جديد' ? accentColor : canvasColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Text(
                    product.status,
                    style: TextStyle(
                      color: product.status == 'جديد' ? Colors.white : inkColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => openDetails(context),
          child: Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: inkColor,
              fontSize: MediaQuery.sizeOf(context).width >= 1024 ? 16 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${product.price.toStringAsFixed(0)} د.ل',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: inkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
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
