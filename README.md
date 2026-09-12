# Iron Sam

Arabic RTL Iron Sam storefront with a Supabase-backed catalog, inventory, checkout, orders, and protected admin area.

## Run

Without configuration, the existing local catalog is used only for development and widget tests. Release builds fail safely until Supabase is configured. Connect Supabase with public client values at runtime:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
```

For a release web build, also deploy the guest-order Edge Function. The release default uses it automatically; local debugging can use the direct RPC with `--dart-define=USE_ORDER_EDGE_FUNCTION=false`.

```bash
flutter build web --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
supabase functions deploy submit-order --no-verify-jwt
```

Never put a service-role key in the Flutter app.

## Supabase setup

Run migrations `001` through `006` in order in the Supabase SQL editor or with the Supabase CLI. Apply `006_product_color_variants.sql` to a staging project first; it adds normalized colors, color-aware variants, and server-side order color snapshots. Review `004_security_hardening.sql` and `006_product_color_variants.sql` before applying them. Do not put the service-role key in Flutter; Supabase injects it only into the Edge Function runtime.

The Edge Function uses a database-backed request-origin/phone throttle. Optional Cloudflare Turnstile protection is supported by setting `TURNSTILE_SECRET_KEY` and `TURNSTILE_ENFORCED=true` in the Edge Function environment, then adding a Turnstile token to the request body from the future client widget integration. No secret values are stored in this repository.

Create an admin user in Supabase Auth, then set its `public.profiles.is_admin` value to `true`. The admin area is available at `/admin` and is protected by Supabase Auth plus the profile authorization check.

## Verify

```bash
flutter analyze
flutter test
```
