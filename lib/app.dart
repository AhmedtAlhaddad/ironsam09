import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/cart/cart_state.dart';
import 'navigation/storefront_router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StoreState store;
  late final StorefrontRouterDelegate routerDelegate;

  @override
  void initState() {
    super.initState();
    store = StoreState();
    routerDelegate = StorefrontRouterDelegate(store: store);
    store.loadCatalog();
  }

  @override
  void dispose() {
    routerDelegate.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'آيرون سام — الكل',
      theme: buildAppTheme(),
      routerDelegate: routerDelegate,
      routeInformationParser: const StorefrontRouteInformationParser(),
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }
}
