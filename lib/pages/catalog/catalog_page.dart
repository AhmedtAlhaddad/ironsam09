import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/storefront_theme.dart';
import '../../data/models/product.dart';
import '../../features/cart/cart_state.dart';
import '../../widgets/catalog_widgets.dart';
import '../cart/cart_page.dart';
import 'storefront_audience.dart';

class CollectionsPage extends CatalogPage {
  const CollectionsPage({required super.store, super.key})
    : super(audience: StorefrontAudience.all);
}

class MenPage extends CatalogPage {
  const MenPage({required super.store, super.key})
    : super(audience: StorefrontAudience.men);
}

class WomenPage extends CatalogPage {
  const WomenPage({required super.store, super.key})
    : super(audience: StorefrontAudience.women);
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({required this.store, required this.audience, super.key});

  final StoreState store;
  final StorefrontAudience audience;

  static const allCategory = 'الكل';

  String get title => audience.label;

  String? get genderFilter => audience.productGender;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  Timer? _searchDebounce;
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _catalogSectionKey = GlobalKey();
  List<String> _liveCategories = const [];
  List<Product> _visibleProducts = const [];

  @override
  void initState() {
    super.initState();
    widget.store.catalogChanges.addListener(_onCatalogChanged);
    _rebuildCatalogView();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    widget.store.catalogChanges.removeListener(_onCatalogChanged);
    super.dispose();
  }

  void _onCatalogChanged() {
    if (!mounted) return;
    setState(_rebuildCatalogView);
  }

  String selectedCategory = CatalogPage.allCategory;
  String query = '';

  void _rebuildCatalogView() {
    final dynamicCategories = widget.store.categories
        .where(
          (category) =>
              category.active &&
              category.nameAr.isNotEmpty &&
              category.nameAr != CatalogPage.allCategory,
        )
        .map((category) => category.nameAr);
    _liveCategories = <String>{
      CatalogPage.allCategory,
      ...dynamicCategories,
    }.toList(growable: false);
    if (!_liveCategories.contains(selectedCategory)) {
      selectedCategory = CatalogPage.allCategory;
    }
    _visibleProducts = _filterProducts();
  }

  List<String> get liveCategories => _liveCategories;

  List<Product> get visibleProducts => _visibleProducts;

  List<Product> _filterProducts() {
    final normalizedQuery = query.trim().toLowerCase();
    return widget.store.products.where((product) {
      final matchesGender =
          widget.genderFilter == null ||
          product.gender == widget.genderFilter ||
          product.gender == 'للجنسين';
      final matchesCategory =
          selectedCategory == CatalogPage.allCategory ||
          product.category == selectedCategory;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery);
      return matchesGender && matchesCategory && matchesQuery;
    }).toList();
  }

  void _onCategoryChanged(String category) {
    if (category == selectedCategory) return;
    setState(() {
      selectedCategory = category;
      _visibleProducts = _filterProducts();
    });
  }

  void _onQueryChanged(String value) {
    query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _visibleProducts = _filterProducts());
    });
  }

  void _focusSearch() {
    if (!mounted) return;
    _searchFocusNode.requestFocus();
  }

  void _scrollToCatalog() {
    final sectionContext = _catalogSectionKey.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: StorefrontMotion.resolve(context, StorefrontMotion.deliberate),
      curve: StorefrontMotion.curve,
      alignment: 0,
    );
  }

  void openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CartPage(store: widget.store)),
    );
  }

  void _selectAudience(StorefrontAudience audience) {
    if (audience == widget.audience) return;
    final page = switch (audience) {
      StorefrontAudience.all => CollectionsPage(store: widget.store),
      StorefrontAudience.men => MenPage(store: widget.store),
      StorefrontAudience.women => WomenPage(store: widget.store),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return StorefrontTheme(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const DeliveryBanner(),
                StoreHeader(
                  store: widget.store,
                  activeAudience: widget.audience,
                  onAudienceChanged: _selectAudience,
                  onCartPressed: openCart,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = StorefrontLayout.gutterFor(
                        constraints.maxWidth,
                      );
                      final content = ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: StorefrontLayout.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.audience == StorefrontAudience.all) ...[
                              PageIntro(
                                title: widget.title,
                                heroProducts: visibleProducts,
                                onShopPressed: _scrollToCatalog,
                              ),
                              const SizedBox(height: StorefrontSpacing.lg),
                            ],
                            CatalogSectionHeading(
                              key: _catalogSectionKey,
                              title: widget.title,
                            ),
                            const SizedBox(height: StorefrontSpacing.lg),
                            FilterBar(
                              categories: liveCategories,
                              selectedCategory: selectedCategory,
                              onCategoryChanged: _onCategoryChanged,
                              query: query,
                              onQueryChanged: _onQueryChanged,
                              searchFocusNode: _searchFocusNode,
                            ),
                          ],
                        ),
                      );
                      const scrollTopSpacing = 6.0;
                      return CustomScrollView(
                        key: const ValueKey('catalog-scroll-view'),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(height: scrollTopSpacing),
                          ),
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                child: content,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: StorefrontSpacing.lg),
                          ),
                          SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: StorefrontLayout.contentMaxWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                  ),
                                  child: AnimatedBuilder(
                                    animation: widget.store,
                                    builder: (context, _) => CatalogResults(
                                      isLoading: widget.store.isLoading,
                                      error: widget.store.loadError,
                                      products: visibleProducts,
                                      store: widget.store,
                                      hasActiveFilter:
                                          query.trim().isNotEmpty ||
                                          selectedCategory !=
                                              CatalogPage.allCategory,
                                      onRetry: widget.store.loadCatalog,
                                      onSearchPressed: _focusSearch,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 20)),
                          const SliverToBoxAdapter(child: TrustStrip()),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: StorefrontSpacing.section),
                          ),
                          const SliverToBoxAdapter(child: StoreFooter()),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: StorefrontSpacing.section),
                          ),
                        ],
                      );
                    },
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
