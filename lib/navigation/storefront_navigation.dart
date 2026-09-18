import 'package:flutter/material.dart';

import '../data/models/product.dart';
import '../pages/catalog/storefront_audience.dart';

abstract interface class StorefrontNavigationController {
  StorefrontAudience get currentAudience;

  void selectAudience(StorefrontAudience audience);

  void openProduct(Product product, {VoidCallback? onSearchPressed});

  void openCart();

  void openCheckout();

  void goHome();

  void goBack();
}

abstract final class StorefrontNavigation {
  static StorefrontNavigationController? maybeOf(BuildContext context) {
    final router = Router.maybeOf<dynamic>(context);
    final Object? delegate = router?.routerDelegate;
    if (delegate is StorefrontNavigationController) return delegate;
    return null;
  }
}
