import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../pages/cart/cart_page.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        'توصيل إلى جميع أنحاء ليبيا  ·  DELIVERY ACROSS LIBYA',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.3,
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
        final isWide = constraints.maxWidth >= 760;
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: lineColor)),
            color: canvasColor,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth >= 1100 ? 48 : 16,
            vertical: 14,
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
                        SizedBox(width: 30),
                        _HeaderLink(
                          label: 'النساء',
                          active: activeSection == 'النساء',
                          onPressed: onWomenPressed,
                        ),
                        SizedBox(width: 30),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
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
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: active ? TextDecoration.underline : null,
          decorationThickness: 2,
          decorationColor: accentColor,
        ),
      ),
      child: Text(label),
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
        final titleSize = constraints.maxWidth >= 1024
            ? 60.0
            : constraints.maxWidth >= 600
            ? 48.0
            : 36.0;
        final descriptionWidth = constraints.maxWidth > 650
            ? 650.0
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'جميع الملابس',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 7),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: inkColor,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: .95,
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
                  color: Color(0xFF57534E),
                  fontSize: 15,
                  height: 1.8,
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
        final isWide = constraints.maxWidth >= 1024;
        final categoryStrip = SizedBox(
          height: 44,
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
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                );
              },
            ),
          ),
        );
        final searchField = TextField(
          focusNode: searchFocusNode,
          onChanged: onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'ابحث عن المنتجات...',
            prefixIcon: Icon(Icons.search, color: Colors.black54),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                    const SizedBox(width: 24),
                    SizedBox(width: 320, child: searchField),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    categoryStrip,
                    const SizedBox(height: 14),
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
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 768;
        final columns = isDesktop
            ? 4
            : isTablet
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: isDesktop ? 32 : 16,
            mainAxisSpacing: isDesktop ? 64 : 40,
            childAspectRatio: columns == 2
                ? constraints.maxWidth < 500
                      ? .46
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

  void addToCart(BuildContext context) {
    if (product.sizeOptions.length > 1 && !store.hasSelectedSize(product)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار المقاس أولاً')));
      return;
    }
    if (store.stockFor(product) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا المنتج غير متوفر حاليًا.')),
      );
      return;
    }
    store.add(product);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تمت الإضافة إلى السلة'),
        persist: false,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'السلة',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => CartPage(store: store)),
          ),
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
        border: Border.symmetric(horizontal: BorderSide(color: lineColor)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 16,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IronSamLogo(width: 118, height: 70),
            SizedBox(height: 8),
            Text(
              'ملابس رياضية لكل حركة',
              style: TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ),
        Text(
          '© 2025 آيرون سام. جميع الحقوق محفوظة.',
          style: TextStyle(color: Colors.black45, fontSize: 10),
        ),
      ],
    );
  }
}
