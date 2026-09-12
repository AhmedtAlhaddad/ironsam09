class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const isSupabaseConfigured =
      supabaseUrl != '' && supabaseAnonKey != '';
  static const isReleaseBuild = bool.fromEnvironment('dart.vm.product');
  static const useOrderEdgeFunction = isReleaseBuild
      ? true
      : bool.fromEnvironment('USE_ORDER_EDGE_FUNCTION');
  static const orderEdgeFunctionName = 'submit-order';

  static bool get isProductionMisconfigured =>
      requiresSupabase(isReleaseBuild: isReleaseBuild);

  static bool requiresSupabase({
    required bool isReleaseBuild,
    bool configured = isSupabaseConfigured,
  }) => isReleaseBuild && !configured;
}
