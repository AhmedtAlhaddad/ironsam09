import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/cart/cart_state.dart';
import 'pages/catalog/catalog_page.dart';
import 'admin/admin_gate.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StoreState store;

  @override
  void initState() {
    super.initState();
    store = StoreState();
    store.loadCatalog();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'آيرون سام — الكل',
      theme: buildAppTheme(),
      routes: {'/admin': (_) => AdminGate(store: store)},
      home: CollectionsPage(store: store),
    );
  }
}
