import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_url_policy.dart';
import '../../core/utils/product_image_paths.dart';
import '../catalog/product_catalog.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';

abstract interface class StoreRepository {
  Future<List<Product>> fetchProducts();
  Future<List<Category>> fetchCategories();
  Future<DiscountValidation> validateDiscount(String code);
  Future<OrderReceipt?> createOrder(
    OrderDraft draft,
    List<Map<String, dynamic>> items, {
    String? requestId,
  });
}

class LocalStoreRepository implements StoreRepository {
  const LocalStoreRepository();

  @override
  Future<List<Product>> fetchProducts() async => products;

  @override
  Future<List<Category>> fetchCategories() async => const [
    Category(nameAr: 'تيشيرتات'),
    Category(nameAr: 'هوديز'),
    Category(nameAr: 'بناطيل'),
    Category(nameAr: 'شورتات'),
    Category(nameAr: 'جاكيتات'),
    Category(nameAr: 'أطقم'),
    Category(nameAr: 'إكسسوارات'),
  ];

  @override
  Future<DiscountValidation> validateDiscount(String code) async {
    // LocalStoreRepository never accepts discount codes. Codes must be created
    // and activated from the admin panel in Supabase.
    final normalized = code.trim().toUpperCase();
    return DiscountValidation(valid: false, code: normalized);
  }

  @override
  Future<OrderReceipt?> createOrder(
    OrderDraft draft,
    List<Map<String, dynamic>> items, {
    String? requestId,
  }) async {
    return OrderReceipt(
      orderNumber: 'LOCAL-${DateTime.now().millisecondsSinceEpoch % 10000}',
      subtotal: draft.subtotal,
      discount: 0,
      total: draft.subtotal,
    );
  }
}

class SupabaseStoreRepository implements StoreRepository {
  SupabaseStoreRepository(this.client);

  final SupabaseClient client;

  factory SupabaseStoreRepository.configured() =>
      SupabaseStoreRepository(Supabase.instance.client);

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await client
        .from('products')
        .select(
          'id, name_ar, description_ar, price_lyd, gender, badge, category_id, categories(name_ar), product_images(id, color_id, storage_path, url, sort_order, is_cover), product_colors(id, name_ar, hex_code, active), product_variants(id, color_id, size, stock_quantity, active, product_colors(name_ar))',
        )
        .eq('active', true)
        .order('created_at', ascending: false);
    return rows.map<Product>(_productFromRow).toList();
  }

  @override
  Future<List<Category>> fetchCategories() async {
    final rows = await client
        .from('categories')
        .select('id, name_ar, slug, active')
        .eq('active', true)
        .order('name_ar');
    return rows
        .map<Category>(
          (row) => Category(
            id: row['id'] as String?,
            nameAr: row['name_ar'] as String? ?? '',
            slug: row['slug'] as String? ?? '',
            active: row['active'] as bool? ?? true,
          ),
        )
        .toList();
  }

  @override
  Future<DiscountValidation> validateDiscount(String code) async {
    final normalized = code.trim().toUpperCase();
    final result = await client.rpc(
      'validate_discount_code_public',
      params: {'p_code': normalized},
    );
    final row = result is Map
        ? Map<String, dynamic>.from(result)
        : <String, dynamic>{};
    return DiscountValidation(
      valid: row['valid'] == true,
      code: row['code'] as String? ?? normalized,
      customerDiscountPercent:
          (row['discount_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<OrderReceipt?> createOrder(
    OrderDraft draft,
    List<Map<String, dynamic>> items, {
    String? requestId,
  }) async {
    final params = <String, dynamic>{
      'p_customer_name': draft.customerName,
      'p_phone': draft.phone,
      'p_city': draft.city,
      'p_address': draft.address,
      'p_notes': draft.notes,
      'p_discount_code': draft.discountCode,
      'p_items': items,
      'p_request_id': requestId,
    };
    final result = AppConfig.useOrderEdgeFunction
        ? (await client.functions.invoke(
            AppConfig.orderEdgeFunctionName,
            body: params,
          )).data
        : await client.rpc('submit_order', params: params);
    if (result is Map && result['order_number'] is String) {
      return OrderReceipt.fromMap(Map<String, dynamic>.from(result));
    }
    return null;
  }

  Product _productFromRow(dynamic raw) {
    final row = Map<String, dynamic>.from(raw as Map);
    final productId = row['id'] as String?;
    final category = row['categories'] is Map
        ? Map<String, dynamic>.from(row['categories'] as Map)
        : <String, dynamic>{};
    final images =
        (row['product_images'] as List<dynamic>? ?? [])
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList()
          ..sort(
            (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
              (b['sort_order'] as num?) ?? 0,
            ),
          );
    final imageUrls = images
        .map((image) => safeProductImageUrl(image['url'] as String?))
        .whereType<String>()
        .toList();
    final productImages = images
        .map((image) {
          final storagePath = image['storage_path'] as String?;
          final thumbnailUrl =
              productId != null &&
                  storagePath != null &&
                  storagePath.trim().isNotEmpty
              ? client.storage
                    .from(productImagesBucket)
                    .getPublicUrl(
                      productThumbnailStoragePath(
                        productId: productId,
                        originalStoragePath: storagePath,
                      ),
                    )
              : null;
          final heroUrl =
              productId != null &&
                  storagePath != null &&
                  storagePath.trim().isNotEmpty
              ? client.storage
                    .from(productImagesBucket)
                    .getPublicUrl(
                      productHeroStoragePath(
                        productId: productId,
                        originalStoragePath: storagePath,
                      ),
                    )
              : null;
          return ProductImage(
            id: image['id'] as String?,
            colorId: image['color_id'] as String?,
            storagePath: storagePath,
            url: safeProductImageUrl(image['url'] as String?) ?? '',
            thumbnailUrl: safeProductImageUrl(thumbnailUrl) ?? '',
            heroUrl: safeProductImageUrl(heroUrl) ?? '',
            sortOrder: (image['sort_order'] as num?)?.toInt() ?? 0,
            isCover: image['is_cover'] as bool? ?? false,
          );
        })
        .where((image) => image.url.isNotEmpty)
        .toList();
    final variants = (row['product_variants'] as List<dynamic>? ?? [])
        .map((value) {
          final variant = Map<String, dynamic>.from(value as Map);
          return ProductVariant(
            id: variant['id'] as String?,
            colorId: variant['color_id'] as String?,
            colorNameAr: variant['product_colors'] is Map
                ? (variant['product_colors'] as Map)['name_ar'] as String?
                : null,
            size: variant['size'] as String? ?? '',
            stockQuantity: (variant['stock_quantity'] as num?)?.toInt() ?? 0,
            active: variant['active'] as bool? ?? true,
          );
        })
        .where((variant) => variant.size.isNotEmpty)
        .toList();
    final colors = (row['product_colors'] as List<dynamic>? ?? [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .map(
          (color) => ProductColor(
            id: color['id'] as String?,
            nameAr: color['name_ar'] as String? ?? '',
            hexCode: color['hex_code'] as String?,
            active: color['active'] as bool? ?? true,
          ),
        )
        .where((color) => color.nameAr.isNotEmpty)
        .toList();
    final rawGender = row['gender'] as String? ?? ProductGender.unisex.value;
    final productGender =
        ProductGender.fromValue(rawGender) ?? ProductGender.unisex;
    final badge = row['badge'] as String? ?? '';
    return Product(
      id: productId,
      name: row['name_ar'] as String? ?? '',
      description: row['description_ar'] as String? ?? '',
      category: category['name_ar'] as String? ?? '',
      categoryId: row['category_id'] as String?,
      gender: productGender.value,
      price: (row['price_lyd'] as num?)?.toDouble() ?? 0,
      sizes: variants.map((variant) => variant.size).join(' - '),
      status: switch (badge) {
        'new' => 'جديد',
        'rare' => 'نادر',
        'limited' => 'كمية محدودة',
        _ =>
          variants.any(
                (variant) =>
                    variant.inStock &&
                    (variant.colorId == null || variant.colorNameAr != null),
              )
              ? 'متوفر'
              : 'غير متوفر',
      },
      imageUrl: imageUrls.isEmpty ? '' : imageUrls.first,
      imageUrls: imageUrls,
      images: productImages,
      colors: colors,
      variants: variants,
    );
  }
}

StoreRepository createStoreRepository() {
  if (AppConfig.isSupabaseConfigured) {
    return SupabaseStoreRepository.configured();
  }
  if (AppConfig.isReleaseBuild) {
    throw StateError('Supabase configuration is required in release builds.');
  }
  return const LocalStoreRepository();
}
