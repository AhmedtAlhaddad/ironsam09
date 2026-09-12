import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

export 'app.dart';
export 'data/catalog/product_catalog.dart';
export 'data/models/product.dart';
export 'features/cart/cart_state.dart';
export 'pages/cart/cart_page.dart';
export 'pages/catalog/catalog_page.dart';
export 'pages/catalog/product_details_page.dart';
export 'pages/checkout/checkout_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isProductionMisconfigured) {
    runApp(const MissingProductionConfigurationApp());
    return;
  }
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const MyApp());
}

class MissingProductionConfigurationApp extends StatelessWidget {
  const MissingProductionConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'تعذر تشغيل المتجر بأمان. إعدادات الاتصال بالخادم غير مكتملة.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}
