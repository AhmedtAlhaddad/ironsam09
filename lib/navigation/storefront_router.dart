import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../admin/admin_gate.dart';
import '../data/models/product.dart';
import '../features/cart/cart_state.dart';
import '../pages/cart/cart_page.dart';
import '../pages/catalog/catalog_page.dart';
import '../pages/catalog/product_details_page.dart';
import '../pages/catalog/storefront_audience.dart';
import '../pages/checkout/checkout_page.dart';
import 'storefront_navigation.dart';
import 'web_navigation_platform.dart';

enum _StorefrontRouteKind { catalog, product, cart, checkout, admin }

@immutable
class _StorefrontRouteEntry {
  const _StorefrontRouteEntry({
    required this.id,
    required this.kind,
    this.audience = StorefrontAudience.all,
    this.productKey,
    this.product,
    this.onSearchPressed,
  });

  final int id;
  final _StorefrontRouteKind kind;
  final StorefrontAudience audience;
  final String? productKey;
  final Product? product;
  final VoidCallback? onSearchPressed;

  Uri get uri {
    return switch (kind) {
      _StorefrontRouteKind.catalog => switch (audience) {
        StorefrontAudience.all => Uri(path: '/'),
        StorefrontAudience.men => Uri(path: '/men'),
        StorefrontAudience.women => Uri(path: '/women'),
      },
      _StorefrontRouteKind.product => Uri(
        pathSegments: <String>['product', productKey ?? 'unknown'],
        queryParameters: audience == StorefrontAudience.all
            ? null
            : <String, String>{'audience': audience.name},
      ),
      _StorefrontRouteKind.cart => Uri(path: '/cart'),
      _StorefrontRouteKind.checkout => Uri(path: '/checkout'),
      _StorefrontRouteKind.admin => Uri(path: '/admin'),
    };
  }

  Map<String, Object?> toState() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'audience': audience.name,
    if (productKey != null) 'productKey': productKey,
  };

  static _StorefrontRouteEntry? fromState(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final kindName = value['kind'];
    final audienceName = value['audience'];
    if (id is! num || kindName is! String || audienceName is! String) {
      return null;
    }
    final kind = _StorefrontRouteKind.values
        .where((candidate) => candidate.name == kindName)
        .firstOrNull;
    final audience = StorefrontAudience.values
        .where((candidate) => candidate.name == audienceName)
        .firstOrNull;
    if (kind == null || audience == null) return null;
    final productKey = value['productKey'];
    return _StorefrontRouteEntry(
      id: id.toInt(),
      kind: kind,
      audience: audience,
      productKey: productKey is String ? productKey : null,
    );
  }
}

@immutable
class StorefrontRouteState {
  const StorefrontRouteState({
    required this.entries,
    required this.historyIndex,
  });

  // ignore: library_private_types_in_public_api
  final List<_StorefrontRouteEntry> entries;
  final int historyIndex;

  // ignore: library_private_types_in_public_api
  _StorefrontRouteEntry get current => entries.last;
}

class StorefrontRouteInformationParser
    extends RouteInformationParser<StorefrontRouteState> {
  const StorefrontRouteInformationParser();

  @override
  Future<StorefrontRouteState> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final restored = _stateFromBrowser(routeInformation.state);
    if (restored != null && restored.current.uri == routeInformation.uri) {
      return SynchronousFuture<StorefrontRouteState>(restored);
    }
    return SynchronousFuture<StorefrontRouteState>(
      _stateFromUri(routeInformation.uri),
    );
  }

  @override
  RouteInformation restoreRouteInformation(StorefrontRouteState configuration) {
    return RouteInformation(
      uri: configuration.current.uri,
      state: <String, Object?>{
        'ironSamStorefrontHistory': <Map<String, Object?>>[
          for (final entry in configuration.entries) entry.toState(),
        ],
        'historyIndex': configuration.historyIndex,
      },
    );
  }

  StorefrontRouteState? _stateFromBrowser(Object? value) {
    if (value is! Map) return null;
    final rawEntries = value['ironSamStorefrontHistory'];
    final rawHistoryIndex = value['historyIndex'];
    if (rawEntries is! List || rawHistoryIndex is! num) return null;
    final entries = <_StorefrontRouteEntry>[];
    for (final rawEntry in rawEntries) {
      final entry = _StorefrontRouteEntry.fromState(rawEntry);
      if (entry == null) return null;
      entries.add(entry);
    }
    if (entries.isEmpty || entries.first.kind != _StorefrontRouteKind.catalog) {
      return null;
    }
    return StorefrontRouteState(
      entries: List.unmodifiable(entries),
      historyIndex: rawHistoryIndex.toInt(),
    );
  }

  StorefrontRouteState _stateFromUri(Uri uri) {
    const home = _StorefrontRouteEntry(
      id: 0,
      kind: _StorefrontRouteKind.catalog,
    );
    final entries = <_StorefrontRouteEntry>[home];
    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      return const StorefrontRouteState(
        entries: <_StorefrontRouteEntry>[home],
        historyIndex: 0,
      );
    }

    final first = segments.first;
    final audience = _audienceFromName(uri.queryParameters['audience']);
    switch (first) {
      case 'men':
        entries.add(
          const _StorefrontRouteEntry(
            id: 1,
            kind: _StorefrontRouteKind.catalog,
            audience: StorefrontAudience.men,
          ),
        );
      case 'women':
        entries.add(
          const _StorefrontRouteEntry(
            id: 1,
            kind: _StorefrontRouteKind.catalog,
            audience: StorefrontAudience.women,
          ),
        );
      case 'product' when segments.length >= 2:
        if (audience != StorefrontAudience.all) {
          entries.add(
            _StorefrontRouteEntry(
              id: 1,
              kind: _StorefrontRouteKind.catalog,
              audience: audience,
            ),
          );
        }
        entries.add(
          _StorefrontRouteEntry(
            id: entries.length,
            kind: _StorefrontRouteKind.product,
            audience: audience,
            productKey: segments[1],
          ),
        );
      case 'cart':
        entries.add(
          const _StorefrontRouteEntry(id: 1, kind: _StorefrontRouteKind.cart),
        );
      case 'checkout':
        entries
          ..add(
            const _StorefrontRouteEntry(id: 1, kind: _StorefrontRouteKind.cart),
          )
          ..add(
            const _StorefrontRouteEntry(
              id: 2,
              kind: _StorefrontRouteKind.checkout,
            ),
          );
      case 'admin':
        entries.add(
          const _StorefrontRouteEntry(id: 1, kind: _StorefrontRouteKind.admin),
        );
      default:
        break;
    }
    return StorefrontRouteState(
      entries: List.unmodifiable(entries),
      historyIndex: 0,
    );
  }

  StorefrontAudience _audienceFromName(String? value) {
    return StorefrontAudience.values
            .where((candidate) => candidate.name == value)
            .firstOrNull ??
        StorefrontAudience.all;
  }
}

class StorefrontRouterDelegate extends RouterDelegate<StorefrontRouteState>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<StorefrontRouteState>
    implements StorefrontNavigationController {
  StorefrontRouterDelegate({required this.store}) {
    _updateLeaveWarning();
  }

  final StoreState store;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final List<_StorefrontRouteEntry> _entries = <_StorefrontRouteEntry>[
    const _StorefrontRouteEntry(id: 0, kind: _StorefrontRouteKind.catalog),
  ];
  var _historyIndex = 0;
  var _nextEntryId = 1;

  @override
  StorefrontRouteState get currentConfiguration => StorefrontRouteState(
    entries: List.unmodifiable(_entries),
    historyIndex: _historyIndex,
  );

  @override
  StorefrontAudience get currentAudience => _entries.reversed
      .map((entry) => entry.audience)
      .firstWhere((_) => true, orElse: () => StorefrontAudience.all);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: <Page<void>>[for (final entry in _entries) _pageFor(entry)],
      onDidRemovePage: _handleRemovedPage,
    );
  }

  Page<void> _pageFor(_StorefrontRouteEntry entry) {
    final child = switch (entry.kind) {
      _StorefrontRouteKind.catalog => switch (entry.audience) {
        StorefrontAudience.all => CollectionsPage(store: store),
        StorefrontAudience.men => MenPage(store: store),
        StorefrontAudience.women => WomenPage(store: store),
      },
      _StorefrontRouteKind.product => _ResolvedProductPage(
        store: store,
        productKey: entry.productKey ?? '',
        initialProduct: entry.product,
        onSearchPressed: entry.onSearchPressed,
      ),
      _StorefrontRouteKind.cart => CartPage(store: store),
      _StorefrontRouteKind.checkout => CheckoutPage(store: store),
      _StorefrontRouteKind.admin => AdminGate(store: store),
    };
    return MaterialPage<void>(
      key: ValueKey<String>('storefront-route-${entry.id}'),
      name: entry.uri.toString(),
      child: child,
    );
  }

  @override
  Future<void> setNewRoutePath(StorefrontRouteState configuration) {
    _entries
      ..clear()
      ..addAll(configuration.entries);
    _historyIndex = configuration.historyIndex;
    _nextEntryId =
        _entries.fold<int>(0, (largest, entry) => math.max(largest, entry.id)) +
        1;
    _updateLeaveWarning();
    notifyListeners();
    return SynchronousFuture<void>(null);
  }

  @override
  Future<bool> popRoute() {
    if (_entries.length == 1) return SynchronousFuture<bool>(false);
    _removeLast();
    return SynchronousFuture<bool>(true);
  }

  @override
  void selectAudience(StorefrontAudience audience) {
    if (audience == currentAudience &&
        _entries.last.kind == _StorefrontRouteKind.catalog) {
      return;
    }
    if (audience == StorefrontAudience.all) {
      goHome();
      return;
    }
    _push(
      _StorefrontRouteEntry(
        id: _nextEntryId++,
        kind: _StorefrontRouteKind.catalog,
        audience: audience,
      ),
    );
  }

  @override
  void openProduct(Product product, {VoidCallback? onSearchPressed}) {
    _push(
      _StorefrontRouteEntry(
        id: _nextEntryId++,
        kind: _StorefrontRouteKind.product,
        audience: currentAudience,
        productKey: _productKey(product),
        product: product,
        onSearchPressed: onSearchPressed,
      ),
    );
  }

  @override
  void openCart() {
    _push(
      _StorefrontRouteEntry(
        id: _nextEntryId++,
        kind: _StorefrontRouteKind.cart,
        audience: currentAudience,
      ),
    );
  }

  @override
  void openCheckout() {
    _push(
      _StorefrontRouteEntry(
        id: _nextEntryId++,
        kind: _StorefrontRouteKind.checkout,
        audience: currentAudience,
      ),
    );
  }

  @override
  void goHome() {
    if (_entries.length == 1 &&
        _entries.single.kind == _StorefrontRouteKind.catalog &&
        _entries.single.audience == StorefrontAudience.all) {
      return;
    }
    final home = _entries.first;
    _entries
      ..clear()
      ..add(home);
    _historyIndex += 1;
    _updateLeaveWarning();
    notifyListeners();
  }

  @override
  void goBack() {
    if (_historyIndex > 0 && requestBrowserBack()) return;
    if (_entries.length > 1) _removeLast();
  }

  void _push(_StorefrontRouteEntry entry) {
    _entries.add(entry);
    _historyIndex += 1;
    _updateLeaveWarning();
    notifyListeners();
  }

  void _removeLast() {
    _entries.removeLast();
    _historyIndex = math.max(0, _historyIndex - 1);
    _updateLeaveWarning();
    notifyListeners();
  }

  void _handleRemovedPage(Page<Object?> page) {
    final index = _entries.indexWhere(
      (entry) => page.key == ValueKey<String>('storefront-route-${entry.id}'),
    );
    if (index <= 0 || index >= _entries.length) return;
    final removedCount = _entries.length - index;
    _entries.removeRange(index, _entries.length);
    _historyIndex = math.max(0, _historyIndex - removedCount);
    _updateLeaveWarning();
    notifyListeners();
  }

  void _updateLeaveWarning() {
    final atLandingEntry = _historyIndex == 0;
    final atHome =
        _entries.length == 1 &&
        _entries.single.kind == _StorefrontRouteKind.catalog &&
        _entries.single.audience == StorefrontAudience.all;
    setRootLeaveWarningEnabled(atLandingEntry && atHome);
  }

  String _productKey(Product product) {
    final id = product.id?.trim();
    return id == null || id.isEmpty ? 'name:${product.name}' : 'id:$id';
  }

  @override
  void dispose() {
    setRootLeaveWarningEnabled(false);
    super.dispose();
  }
}

class _ResolvedProductPage extends StatelessWidget {
  const _ResolvedProductPage({
    required this.store,
    required this.productKey,
    this.initialProduct,
    this.onSearchPressed,
  });

  final StoreState store;
  final String productKey;
  final Product? initialProduct;
  final VoidCallback? onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final product = initialProduct ?? _findProduct();
        if (product != null) {
          return ProductDetailsPage(
            product: product,
            store: store,
            onSearchPressed: onSearchPressed,
          );
        }
        if (store.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    StorefrontNavigation.maybeOf(context)?.goHome(),
                child: const Text('العودة إلى المتجر'),
              ),
            ),
          ),
        );
      },
    );
  }

  Product? _findProduct() {
    final separator = productKey.indexOf(':');
    if (separator <= 0) return null;
    final type = productKey.substring(0, separator);
    final value = productKey.substring(separator + 1);
    for (final product in store.products) {
      if (type == 'id' && product.id == value) return product;
      if (type == 'name' && product.name == value) return product;
    }
    return null;
  }
}
