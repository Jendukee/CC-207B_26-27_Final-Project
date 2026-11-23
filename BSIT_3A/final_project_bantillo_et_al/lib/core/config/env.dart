// Compile-time configuration read from env.json.
//
// Values are injected with: flutter run --dart-define-from-file=env.json
// env.json is gitignored. Copy env.example.json to env.json and fill it in.
// Never hard-code real keys in Dart files. The Gemini key is NOT here: it
// lives only as a Supabase secret used by the ai-assistant edge function.
//
// OWNER: team lead. Change only via a reviewed PR.

/// Typed access to the values defined in env.json.
abstract final class Env {
  /// Supabase project URL, e.g. https://abcd.supabase.co
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon (public) key. Safe to ship: RLS policies protect data.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Name of the Supabase Edge Function that talks to Gemini.
  static const String aiFunctionName =
      String.fromEnvironment('AI_FUNCTION_NAME');

  /// Keys that are empty or still hold the placeholder from env.example.json.
  static List<String> get missingKeys => [
        if (_isBlank(supabaseUrl)) 'SUPABASE_URL',
        if (_isBlank(supabaseAnonKey)) 'SUPABASE_ANON_KEY',
        if (_isBlank(aiFunctionName)) 'AI_FUNCTION_NAME',
      ];

  /// True when every required value is present.
  static bool get isConfigured => missingKeys.isEmpty;

  /// Treats empty strings and untouched "YOUR-..." placeholders as missing.
  static bool _isBlank(String value) =>
      value.trim().isEmpty || value.contains('YOUR-');
}
