import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migration 010 preserves order item snapshots on product deletion', () {
    final initial = File(
      'supabase/migrations/001_initial.sql',
    ).readAsStringSync();
    final colors = File(
      'supabase/migrations/006_product_color_variants.sql',
    ).readAsStringSync();
    final imageColors = File(
      'supabase/migrations/008_product_image_colors.sql',
    ).readAsStringSync();
    final migration = File(
      'supabase/migrations/010_safe_product_deletion.sql',
    ).readAsStringSync();

    expect(
      initial,
      contains(
        'product_id uuid not null references public.products(id) on delete restrict',
      ),
    );
    expect(
      initial,
      contains(
        'variant_id uuid not null references public.product_variants(id) on delete restrict',
      ),
    );
    expect(migration, contains('alter column product_id drop not null'));
    expect(migration, contains('alter column variant_id drop not null'));
    expect(colors, contains('on delete restrict'));
    expect(imageColors, contains('on delete no action'));
    expect(
      migration,
      isNot(contains('references public.product_colors(product_id, id)')),
    );
    expect(migration, isNot(contains('product_variants_product_color_fk')));
    expect(migration, isNot(contains('product_images_product_color_fk')));
    expect(
      migration,
      matches(
        RegExp(
          r'foreign key \(product_id\)[\s\S]*?references public\.products\(id\)[\s\S]*?on delete set null',
          caseSensitive: false,
        ),
      ),
    );
    expect(
      migration,
      matches(
        RegExp(
          r'foreign key \(variant_id\)[\s\S]*?references public\.product_variants\(id\)[\s\S]*?on delete set null',
          caseSensitive: false,
        ),
      ),
    );
    expect(migration, isNot(contains('delete from public.orders')));
    expect(migration, isNot(contains('delete from public.order_items')));

    for (final snapshotField in [
      'product_name_snapshot',
      'product_image_url_snapshot',
      'selected_size',
      'quantity',
      'unit_price_lyd',
      'line_total_lyd',
    ]) {
      expect(initial, contains(snapshotField));
    }
    expect(colors, contains('color_name_ar'));
  });

  test('migration 010 exposes only the guarded Admin deletion flow', () {
    final migration = File(
      'supabase/migrations/010_safe_product_deletion.sql',
    ).readAsStringSync();
    final service = File('lib/admin/admin_service.dart').readAsStringSync();
    final panel = File('lib/admin/admin_panel.dart').readAsStringSync();

    expect(
      migration,
      contains("where o.status in ('pending', 'confirmed', 'preparing')"),
    );
    expect(migration, contains('active_orders_block_product_delete'));
    expect(
      migration,
      contains(
        'create or replace function public.admin_delete_product(p_product_id uuid)',
      ),
    );
    expect(migration, contains('security definer'));
    expect(migration, contains('set search_path = pg_catalog'));
    expect(migration, contains('if not public.is_admin()'));
    expect(
      migration,
      contains('revoke all on function public.admin_delete_product(uuid)'),
    );
    expect(
      migration,
      contains('grant execute on function public.admin_delete_product(uuid)'),
    );

    final deleteImages = migration.indexOf('delete from public.product_images');
    final deleteVariants = migration.indexOf(
      'delete from public.product_variants',
    );
    final deleteColors = migration.indexOf('delete from public.product_colors');
    final deleteProduct = migration.indexOf('delete from public.products');
    expect(deleteImages, greaterThan(0));
    expect(deleteVariants, greaterThan(deleteImages));
    expect(deleteColors, greaterThan(deleteVariants));
    expect(deleteProduct, greaterThan(deleteColors));
    expect(migration, contains('returns text[]'));
    expect(migration, contains('array_agg(distinct pi.storage_path)'));

    expect(service, matches(RegExp(r"client\.rpc\(\s*'admin_delete_product'")));
    expect(
      service,
      contains(
        'client.storage.from(productImagesBucket).remove(allPaths.toList())',
      ),
    );
    expect(service, contains('productThumbnailStoragePath('));
    expect(service, contains('productHeroStoragePath('));
    expect(service, isNot(contains("from('products')\n        .delete()")));
    expect(panel, contains('on ProductHasActiveOrdersException'));
    expect(panel, contains('لا يمكن حذف المنتج لوجود طلبات نشطة'));
  });
}
