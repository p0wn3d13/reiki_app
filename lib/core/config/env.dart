/// Configuración de entorno.
///
/// Los valores se inyectan en tiempo de compilación con `--dart-define`,
/// nunca se guardan literales en el repositorio (Fase 2, punto 5).
///
/// Ejemplo de uso:
///   flutter run --dart-define=ENV=dev \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxxx
class Env {
  Env._();

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Clave pública del proyecto (la que se puede publicar en el cliente;
  /// la `service_role` nunca entra en la app).
  ///
  /// Supabase renombró `anonKey` a `publishableKey`, así que aceptamos
  /// las dos variables de entorno: los scripts y documentación antiguos
  /// que pasan `SUPABASE_ANON_KEY` siguen funcionando.
  static String get supabaseKey =>
      _publishableKey.isNotEmpty ? _publishableKey : _anonKey;

  static bool get isProd => environment == 'prod';
  static bool get isDev => !isProd;

  /// Falla rápido y con un mensaje claro si falta configuración,
  /// en vez de dejar que Supabase falle más adelante con un error confuso.
  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty,
      'Faltan SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY. '
      'Pásalos con --dart-define al ejecutar o compilar la app.',
    );
  }
}
