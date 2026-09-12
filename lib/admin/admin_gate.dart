import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../features/cart/cart_state.dart';
import '../widgets/catalog_widgets.dart';
import 'admin_panel.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({required this.store, super.key});

  final StoreState store;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  bool preparingFreshLogin = true;

  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.isSupabaseConfigured) {
      preparingFreshLogin = false;
      return;
    }
    _startFreshLogin();
  }

  Future<void> _startFreshLogin() async {
    await client.auth.signOut();
    if (mounted) setState(() => preparingFreshLogin = false);
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      if (!await AdminService(client).isCurrentUserAdmin()) {
        await client.auth.signOut();
        throw StateError('not_admin');
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'بيانات الدخول غير صحيحة أو لا تملك صلاحية الإدارة.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = adminTheme(Theme.of(context));
    if (!AppConfig.isSupabaseConfigured) {
      return Theme(data: theme, child: const _AdminConfigNotice());
    }
    return Theme(
      data: theme,
      child: StreamBuilder<AuthState>(
        stream: client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = client.auth.currentSession;
          if (preparingFreshLogin || session == null) {
            return _AdminLogin(
              onSubmit: signIn,
              email: email,
              password: password,
              loading: loading,
              error: error,
            );
          }
          return AdminPanel(store: widget.store, service: AdminService(client));
        },
      ),
    );
  }
}

class _AdminLogin extends StatelessWidget {
  const _AdminLogin({
    required this.onSubmit,
    required this.email,
    required this.password,
    required this.loading,
    this.error,
  });

  final VoidCallback onSubmit;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const IronSamLogo(width: 150, height: 88),
                    const SizedBox(height: 8),
                    const Text(
                      'دخول لوحة الإدارة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: email,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                      ),
                      onSubmitted: (_) => onSubmit(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(color: AdminColors.danger),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: loading ? null : onSubmit,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('دخول'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AdminConfigNotice extends StatelessWidget {
  const _AdminConfigNotice();

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: Text(
          'لوحة الإدارة تحتاج إعداد SUPABASE_URL و SUPABASE_ANON_KEY.',
        ),
      ),
    ),
  );
}
