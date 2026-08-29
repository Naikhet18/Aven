/// Compile-time configuration, supplied via `--dart-define-from-file=.env`
/// (the `.env` file at the repo root is already in `KEY=VALUE` format, which
/// is exactly what `--dart-define-from-file` expects) or individual
/// `--dart-define=KEY=VALUE` flags.
///
/// There is deliberately no hardcoded fallback key here: a POS app that
/// silently falls back to a baked-in Supabase project when misconfigured
/// would write orders and payments into the wrong backend without anyone
/// noticing.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void assertConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Missing Supabase configuration. Run with:\n'
        '  flutter run --dart-define-from-file=.env\n'
        'or pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
