import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class DuplicateDiscountCodeException implements Exception {
  const DuplicateDiscountCodeException();
}

abstract interface class AdminDiscountCodesService {
  Future<List<Map<String, dynamic>>> discounts();

  Future<DiscountPerformance> discountPerformance(String code);

  Future<Map<String, dynamic>> markInfluencerCommissionsPaid(
    String influencerId,
  );

  Future<void> saveDiscount({
    String? id,
    required String code,
    required bool active,
    String? influencerName,
    DateTime? expiresAt,
    required double customerDiscountPercent,
    required double athleteCommissionPercent,
  });

  Future<void> setDiscountActive(String discountId, bool active);

  Future<void> deleteDiscount(String discountId);
}

class CommissionTotals {
  const CommissionTotals({
    required this.pending,
    required this.approved,
    required this.paid,
  });

  final double pending;
  final double approved;
  final double paid;

  double get total => pending + approved + paid;
}

class DiscountPerformance {
  const DiscountPerformance({
    required this.uses,
    required this.sales,
    required this.commission,
    required this.influencerId,
  });

  const DiscountPerformance.empty()
    : uses = 0,
      sales = 0,
      commission = const CommissionTotals(pending: 0, approved: 0, paid: 0),
      influencerId = null;

  final int uses;
  final double sales;
  final CommissionTotals commission;
  final String? influencerId;
}

CommissionTotals commissionTotalsFromRows(Iterable<Map<String, dynamic>> rows) {
  var pending = 0.0;
  var approved = 0.0;
  var paid = 0.0;
  for (final row in rows) {
    final amount =
        (row['athlete_commission_amount_lyd'] as num?)?.toDouble() ?? 0;
    switch (row['commission_status']) {
      case 'pending':
        pending += amount;
      case 'approved':
        approved += amount;
      case 'paid':
        paid += amount;
    }
  }
  return CommissionTotals(pending: pending, approved: approved, paid: paid);
}

DiscountPerformance discountPerformanceFromRows(
  Iterable<Map<String, dynamic>> rows,
  String code,
) {
  final normalizedCode = code.trim().toUpperCase();
  final matching = rows.where(
    (row) =>
        (row['discount_code'] as String? ?? '').trim().toUpperCase() ==
        normalizedCode,
  );
  final matchingRows = matching.toList();
  return DiscountPerformance(
    uses: matchingRows.length,
    sales: matchingRows.fold<double>(
      0,
      (sum, row) => sum + ((row['total_lyd'] as num?)?.toDouble() ?? 0),
    ),
    commission: commissionTotalsFromRows(matchingRows),
    influencerId: matchingRows
        .map((row) => row['influencer_id'] as String?)
        .whereType<String>()
        .firstOrNull,
  );
}

class AdminService implements AdminDiscountCodesService {
  AdminService(this.client);

  final SupabaseClient client;

  Future<bool> isCurrentUserAdmin() async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    final row = await client
        .from('profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();
    return row?['is_admin'] == true;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final orders = await client
        .from('orders')
        .select(
          'id, status, subtotal_lyd, total_lyd, discount_code, influencer_id, athlete_commission_amount_lyd, commission_status, created_at, influencers(name)',
        );
    final variants = await client
        .from('product_variants')
        .select('stock_quantity, products(name_ar)');
    final today = DateTime.now();
    final todayOrders = orders.where((row) {
      final date = DateTime.tryParse(row['created_at'] as String? ?? '');
      return date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();
    final confirmed = orders.where(
      (row) =>
          row['status'] == 'confirmed' ||
          row['status'] == 'preparing' ||
          row['status'] == 'delivered',
    );
    final codes = <String, int>{};
    final codeRevenue = <String, double>{};
    final athleteOrders = <String, List<Map<String, dynamic>>>{};
    final athleteNames = <String, String>{};
    for (final order in orders) {
      final code = order['discount_code'] as String?;
      if (code != null && code.isNotEmpty) {
        codes[code] = (codes[code] ?? 0) + 1;
        codeRevenue[code] =
            (codeRevenue[code] ?? 0) +
            ((order['total_lyd'] as num?)?.toDouble() ?? 0);
      }
      final influencerId = order['influencer_id'] as String?;
      if (influencerId != null) {
        athleteNames.putIfAbsent(
          influencerId,
          () =>
              (order['influencers'] as Map?)?['name'] as String? ??
              'Ø±ÙŠØ§Ø¶ÙŠ',
        );
        athleteOrders.putIfAbsent(influencerId, () => []).add(order);
      }
    }
    final athleteStats = <String, Map<String, dynamic>>{};
    for (final entry in athleteOrders.entries) {
      final totals = commissionTotalsFromRows(entry.value);
      athleteStats[entry.key] = {
        'id': entry.key,
        'name': athleteNames[entry.key] ?? 'Ø±ÙŠØ§Ø¶ÙŠ',
        'uses': entry.value.length,
        'revenue': entry.value.fold<double>(
          0,
          (sum, row) => sum + ((row['total_lyd'] as num?)?.toDouble() ?? 0),
        ),
        'commission': totals.total,
        'pending': totals.pending,
        'approved': totals.approved,
        'paid': totals.paid,
      };
    }
    final commissionTotals = commissionTotalsFromRows(orders);
    final topCode = codes.entries.isEmpty
        ? null
        : (codes.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    return {
      'orders_today': todayOrders.length,
      'pending': orders.where((row) => row['status'] == 'pending').length,
      'confirmed': confirmed.length,
      'sales': confirmed.fold<double>(
        0,
        (sum, row) => sum + ((row['total_lyd'] as num?)?.toDouble() ?? 0),
      ),
      'low_stock': variants
          .where(
            (row) =>
                ((row['stock_quantity'] as num?)?.toInt() ?? 0) > 0 &&
                ((row['stock_quantity'] as num?)?.toInt() ?? 0) <= 3,
          )
          .length,
      'out_of_stock': variants
          .where((row) => ((row['stock_quantity'] as num?)?.toInt() ?? 0) <= 0)
          .length,
      'top_code': codes.entries.isEmpty
          ? '—'
          : (codes.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key,
      'top_code_uses': codes.values.isEmpty
          ? 0
          : codes.values.reduce((a, b) => a > b ? a : b),
      'top_code_revenue': topCode == null ? 0.0 : codeRevenue[topCode] ?? 0.0,
      'pending_commissions': commissionTotals.pending,
      'approved_commissions': commissionTotals.approved,
      'paid_commissions': commissionTotals.paid,
      'athletes': athleteStats.values.toList(),
    };
  }

  Future<List<Map<String, dynamic>>> products() async => _maps(
    await client
        .from('products')
        .select(
          'id, name_ar, description_ar, price_lyd, gender, badge, active, category_id, categories(name_ar), product_colors(id, name_ar, hex_code, active), product_variants(id, color_id, size, stock_quantity, active), product_images(id, color_id, storage_path, url, is_cover)',
        )
        .order('created_at', ascending: false),
  );

  Future<List<Map<String, dynamic>>> categories() async => _maps(
    await client
        .from('categories')
        .select('id, name_ar, slug, active')
        .order('name_ar'),
  );

  Future<List<Map<String, dynamic>>> inventory() async => _maps(
    await client
        .from('product_variants')
        .select(
          'id, color_id, size, stock_quantity, active, products(id, name_ar, product_images(url, is_cover)), product_colors(name_ar)',
        )
        .order('stock_quantity'),
  );

  Future<List<Map<String, dynamic>>> orders() async => _maps(
    await client
        .from('orders')
        .select(
          'id, order_number, customer_name, phone, city, address, notes, subtotal_lyd, discount_amount_lyd, total_lyd, customer_discount_percent, athlete_commission_percent, athlete_commission_amount_lyd, commission_status, discount_code, influencer_id, influencers(name), status, created_at, order_items(*)',
        )
        .order('created_at', ascending: false),
  );

  @override
  Future<List<Map<String, dynamic>>> discounts() async =>
      _maps(await client.rpc('admin_list_discount_codes'));

  @override
  Future<DiscountPerformance> discountPerformance(String code) async {
    final rows = _maps(
      await client
          .from('orders')
          .select(
            'discount_code, influencer_id, total_lyd, athlete_commission_amount_lyd, commission_status',
          )
          .eq('discount_code', code.trim().toUpperCase()),
    );
    return discountPerformanceFromRows(rows, code);
  }

  @override
  Future<Map<String, dynamic>> markInfluencerCommissionsPaid(
    String influencerId,
  ) async {
    final result = await client.rpc(
      'admin_mark_influencer_commissions_paid',
      params: {'p_influencer_id': influencerId},
    );
    if (result is Map) return Map<String, dynamic>.from(result);
    return const {};
  }

  Future<void> saveCategory({
    String? id,
    required String nameAr,
    required String slug,
    bool active = true,
  }) async {
    await client.from('categories').upsert({
      'id': ?id,
      'name_ar': nameAr,
      'slug': slug,
      'active': active,
    });
  }

  Future<void> deleteCategory(String id) =>
      client.from('categories').delete().eq('id', id);

  Future<String> saveProduct({
    String? id,
    required String nameAr,
    required String descriptionAr,
    required double price,
    required String? categoryId,
    required String gender,
    String badge = '',
    required bool active,
    required List<Map<String, dynamic>> variants,
    List<Map<String, dynamic>> colors = const [],
  }) async {
    final row = <String, dynamic>{
      'id': ?id,
      'name_ar': nameAr,
      'description_ar': descriptionAr,
      'price_lyd': price,
      'category_id': categoryId,
      'gender': gender,
      'badge': badge,
      'active': active,
    };
    final saved = await client
        .from('products')
        .upsert(row)
        .select('id')
        .single();
    final productId = saved['id'] as String;
    final colorIds = <int, String>{};
    for (var index = 0; index < colors.length; index++) {
      final color = colors[index];
      final savedColor = await client
          .from('product_colors')
          .upsert({
            'id': ?(color['id'] as String?),
            'product_id': productId,
            'name_ar': color['name_ar'],
            'hex_code': color['hex_code'],
            'active': color['active'] ?? true,
          })
          .select('id')
          .single();
      color['id'] = savedColor['id'];
      colorIds[index] = savedColor['id'] as String;
    }
    final firstAdoption = colors.indexWhere(
      (color) => color['adopt_legacy_variants'] == true,
    );
    if (firstAdoption >= 0) {
      await client
          .from('product_variants')
          .update({'color_id': colorIds[firstAdoption]})
          .eq('product_id', productId)
          .isFilter('color_id', null);
    }
    final existingVariants = await client
        .from('product_variants')
        .select('id')
        .eq('product_id', productId);
    final retainedIds = <String>{};
    for (final variant in variants) {
      final id = variant['id'] as String?;
      final payload = {
        'id': ?id,
        'product_id': productId,
        'color_id':
            variant['color_id'] ??
            colorIds[variant['color_index'] as int? ?? -1] ??
            (firstAdoption >= 0 ? colorIds[firstAdoption] : null),
        'size': variant['size'],
        'stock_quantity': variant['stock_quantity'],
        'active': variant['active'] ?? true,
      };
      final savedVariant = await client
          .from('product_variants')
          .upsert(payload)
          .select('id')
          .single();
      retainedIds.add(savedVariant['id'] as String);
    }
    for (final oldVariant in existingVariants) {
      final oldId = oldVariant['id'] as String;
      if (!retainedIds.contains(oldId)) {
        await client
            .from('product_variants')
            .update({'active': false, 'stock_quantity': 0})
            .eq('id', oldId);
      }
    }
    final existingColors = await client
        .from('product_colors')
        .select('id')
        .eq('product_id', productId);
    final retainedColorIds = colors
        .asMap()
        .entries
        .map((entry) => colorIds[entry.key])
        .whereType<String>()
        .toSet();
    for (final oldColor in existingColors) {
      final oldColorId = oldColor['id'] as String;
      if (!retainedColorIds.contains(oldColorId)) {
        await client
            .from('product_colors')
            .update({'active': false})
            .eq('id', oldColorId);
      }
    }
    return productId;
  }

  Future<void> uploadProductImage(
    String productId,
    Uint8List bytes,
    String fileName, {
    bool cover = false,
    int sortOrder = 0,
    String? colorId,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$productId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await client.storage
        .from('product-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = client.storage.from('product-images').getPublicUrl(path);
    if (cover) {
      await client
          .from('product_images')
          .update({'is_cover': false})
          .eq('product_id', productId);
    }
    await client.from('product_images').insert({
      'product_id': productId,
      'color_id': colorId,
      'storage_path': path,
      'url': url,
      'sort_order': sortOrder,
      'is_cover': cover,
    });
  }

  Future<void> removeProductImage(String imageId, String storagePath) async {
    await client.storage.from('product-images').remove([storagePath]);
    await client.from('product_images').delete().eq('id', imageId);
  }

  Future<void> setCoverImage(String imageId, String productId) async {
    await client
        .from('product_images')
        .update({'is_cover': false})
        .eq('product_id', productId);
    await client
        .from('product_images')
        .update({'is_cover': true})
        .eq('id', imageId);
  }

  Future<void> setStock(String variantId, int quantity) => client
      .from('product_variants')
      .update({'stock_quantity': quantity})
      .eq('id', variantId);

  Future<void> setProductActive(String productId, bool active) =>
      client.from('products').update({'active': active}).eq('id', productId);

  Future<void> deleteProduct(String productId) =>
      client.from('products').delete().eq('id', productId);

  Future<void> updateOrderStatus(String orderId, String status) async {
    await client.rpc(
      'set_order_status',
      params: {'p_order_id': orderId, 'p_status': status},
    );
  }

  @override
  Future<void> saveDiscount({
    String? id,
    required String code,
    required bool active,
    String? influencerName,
    DateTime? expiresAt,
    required double customerDiscountPercent,
    required double athleteCommissionPercent,
  }) async {
    String? influencerId;
    if (influencerName != null && influencerName.trim().isNotEmpty) {
      final influencer = await client
          .from('influencers')
          .upsert({'name': influencerName.trim()})
          .select('id')
          .single();
      influencerId = influencer['id'] as String;
    }
    final fields = {
      'code': code.trim().toUpperCase(),
      'active': active,
      'influencer_id': influencerId,
      'expires_at': expiresAt?.toIso8601String(),
      'customer_discount_percent': customerDiscountPercent,
      'athlete_commission_percent': athleteCommissionPercent,
    };

    try {
      if (id == null) {
        await client
            .from('discount_codes')
            .insert(fields)
            .setHeader('Prefer', 'return=minimal');
      } else {
        await client
            .from('discount_codes')
            .update(fields)
            .eq('id', id)
            .setHeader('Prefer', 'return=minimal');
      }
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const DuplicateDiscountCodeException();
      }
      rethrow;
    }
  }

  @override
  Future<void> setDiscountActive(String discountId, bool active) => client
      .from('discount_codes')
      .update({'active': active})
      .eq('id', discountId)
      .setHeader('Prefer', 'return=minimal');

  @override
  Future<void> deleteDiscount(String discountId) => client
      .from('discount_codes')
      .delete()
      .eq('id', discountId)
      .setHeader('Prefer', 'return=minimal');

  Future<void> updateCommissionStatus(String orderId, String status) async {
    await client.rpc(
      'set_commission_status',
      params: {'p_order_id': orderId, 'p_status': status},
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic rows) =>
      (rows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
}
