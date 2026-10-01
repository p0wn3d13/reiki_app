import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../domain/models/perfil.dart';
import '../../domain/models/user_role.dart';
import '../services/supabase_service.dart';

/// Tabla de perfiles. El esquema de este proyecto está en español:
/// es `perfiles`, no `profiles` (verificado contra el proyecto real de
/// Supabase, que devuelve PGRST205 si se pide `profiles`).
const String tablaPerfiles = 'perfiles';

/// Qué ha pasado tras un registro correcto.
///
/// Depende de si en Supabase está activada la confirmación por email:
/// con confirmación, `signUp` devuelve usuario pero **sin** sesión.
enum ResultadoRegistro {
  /// Sesión abierta al instante: el router ya puede llevar al inicio.
  sesionIniciada,

  /// Falta que el usuario pulse el enlace del correo de confirmación.
  confirmacionPendiente,
}

/// Único punto de la app que habla con Supabase Auth y con la tabla
/// `perfiles`. La capa de presentación solo ve `AppException` y modelos
/// de dominio, nunca tipos de la librería (Fase 2, punto 3).
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'reikiapp://login-callback',
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Registra una cuenta nueva.
  ///
  /// El rol se fija siempre a `cliente`: nadie puede darse de alta como
  /// terapeuta desde la app, esas cuentas las crea la asociación. Los
  /// datos se envían también en `data:` (metadatos del usuario) para que
  /// un trigger `handle_new_user` en Postgres pueda rellenar `perfiles`
  /// si existe; si no existe, los escribimos nosotros con el upsert de
  /// abajo. Ambos caminos son idempotentes.
  Future<ResultadoRegistro> signUp({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    final emailLimpio = email.trim();
    final nombreLimpio = nombre.trim();
    final telefonoLimpio = telefono?.trim();

    try {
      final res = await _client.auth.signUp(
        email: emailLimpio,
        password: password,
        data: {
          'nombre': nombreLimpio,
          'telefono': telefonoLimpio,
          'rol': UserRole.cliente.dbValue,
        },
      );

      final user = res.user;
      if (user == null) {
        throw const UnknownAppException();
      }

      if (res.session == null) {
        // Camino normal en este proyecto: hay confirmación por email, así
        // que no hay sesión todavía y las políticas RLS no nos dejarían
        // escribir en `perfiles`. La fila se crea en el primer login, en
        // `fetchPerfil`, con los metadatos que acabamos de enviar.
        return ResultadoRegistro.confirmacionPendiente;
      }

      await _upsertPerfil(
        id: user.id,
        email: emailLimpio,
        nombre: nombreLimpio,
        telefono: telefonoLimpio,
      );

      return ResultadoRegistro.sesionIniciada;
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Envía el correo de recuperación de contraseña.
  ///
  /// El enlace lleva a la "Site URL" configurada en Supabase
  /// (Authentication → URL Configuration). Cuando en la Fase 11 se
  /// añadan los deep links, aquí se pasará `redirectTo` con el esquema
  /// propio de la app para que abra la pantalla de cambio de contraseña.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> updateProfile({
    required String nombre,
    String? telefono,
    String? fotoUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthAppException(
          'Tu sesión ha caducado. Vuelve a iniciar sesión.');
    }

    try {
      final data = <String, dynamic>{
        'nombre': nombre.trim(),
        'telefono': _textoONulo(telefono),
      };
      if (fotoUrl != null) {
        data['foto_url'] = fotoUrl;
      }

      await _client.from(tablaPerfiles).update(data).eq('id', user.id);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<String> uploadProfilePhoto(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthAppException(
        'Tu sesión ha caducado. Vuelve a iniciar sesión.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').lastOrNull ?? 'jpg';
      final path = '${user.id}/profile.$ext';

      await _client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (error) {
      if (error is StorageException) {
        throw AuthAppException(
          'No se pudo subir la foto: ${error.message}. '
          'Comprueba que el bucket "avatars" existe y que las políticas de Storage permiten escribir a tu usuario.',
        );
      }
      throw _mapError(error);
    }
  }

  /// Lee el perfil del usuario, que es lo que decide su rol y, con él,
  /// a qué pantallas puede entrar.
  ///
  /// Si la fila no existe, la crea. No es un caso raro sino el normal:
  /// este proyecto tiene la confirmación por email activada
  /// (`mailer_autoconfirm: false`), así que `signUp` no abre sesión y no
  /// hay forma de escribir en `perfiles` durante el registro. Sin este
  /// remate, el usuario confirmaría su correo, entraría, y se quedaría
  /// atascado en una pantalla de error para siempre.
  Future<Perfil> fetchPerfil(String userId) async {
    try {
      final row = await _client
          .from(tablaPerfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row != null) return Perfil.fromMap(row);

      return await _crearPerfilDesdeAuth(userId);
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Crea la fila de `perfiles` a partir de los datos que `signUp`
  /// guardó en los metadatos del usuario de Supabase Auth.
  Future<Perfil> _crearPerfilDesdeAuth(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != userId) {
      throw const AuthAppException(
        'Tu sesión ha caducado. Vuelve a iniciar sesión.',
      );
    }

    final meta = user.userMetadata ?? const <String, dynamic>{};

    final nombreGoogle = _textoOVacio(meta['nombre']);
    final nombreFallback = _textoOVacio(meta['name']);
    final fotoGoogle = _textoONulo(meta['avatar_url']) ??
        _textoONulo(meta['picture']) ??
        _textoONulo(meta['foto_url']);

    final fila = await _upsertPerfil(
      id: userId,
      email: user.email ?? '',
      nombre: nombreGoogle.isNotEmpty ? nombreGoogle : nombreFallback,
      telefono: _textoONulo(meta['telefono']),
      fotoUrl: fotoGoogle,
    );

    if (fila == null) {
      throw const AuthAppException(
        'No hemos podido crear tu perfil en la base de datos. '
        'Ponte en contacto con la asociación.',
      );
    }

    return Perfil.fromMap(fila);
  }

  /// El `rol` solo se escribe aquí para cuentas recién creadas, que son
  /// siempre `cliente`; a un terapeuta existente nunca se le llega a
  /// pisar porque su fila ya está y el upsert no se ejecuta.
  Future<Map<String, dynamic>?> _upsertPerfil({
    required String id,
    required String email,
    required String nombre,
    String? telefono,
    String? fotoUrl,
  }) async {
    return await _client
        .from(tablaPerfiles)
        .upsert(
          {
            'id': id,
            'email': email,
            'nombre': nombre,
            'telefono': telefono,
            'foto_url': fotoUrl,
            'rol': UserRole.cliente.dbValue,
          },
          onConflict: 'id',
        )
        .select()
        .maybeSingle();
  }

  static String _textoOVacio(Object? valor) =>
      valor is String ? valor.trim() : '';

  static String? _textoONulo(Object? valor) {
    if (valor is! String) return null;
    final v = valor.trim();
    return v.isEmpty ? null : v;
  }

  /// Traduce cualquier excepción a un `AppException` con un mensaje que
  /// se le puede mostrar tal cual al usuario.
  AppException _mapError(Object error) {
    // Los errores que ya hemos construido nosotros pasan intactos: si no,
    // el mensaje concreto de `fetchPerfil` se convertiría en el genérico.
    if (error is AppException) return error;

    if (error is AuthRetryableFetchException) return const NetworkException();

    if (error is AuthApiException) {
      return AuthAppException(_mensajeAuthApi(error));
    }

    if (error is AuthException) {
      return AuthAppException(error.message);
    }

    if (error is PostgrestException) {
      // 42501 = violación de política RLS; PGRST301 = JWT ausente/caducado.
      if (error.code == '42501' || error.code == 'PGRST301') {
        return const AuthAppException(
          'Tu cuenta no tiene permiso para esta operación. '
          'Puede que las políticas de seguridad no estén configuradas.',
        );
      }
      return AuthAppException(error.message);
    }

    if (error is StorageException) {
      return AuthAppException(
        'No se pudo acceder al almacenamiento de imágenes: ${error.message}',
      );
    }

    if (_pareceFalloDeRed(error)) return const NetworkException();

    return const UnknownAppException();
  }

  String _mensajeAuthApi(AuthApiException e) {
    return switch (e.code) {
      'invalid_credentials' ||
      'invalid_grant' =>
        'Email o contraseña incorrectos.',
      'email_not_confirmed' =>
        'Todavía no has confirmado tu email. Revisa tu bandeja de entrada.',
      'user_already_exists' ||
      'email_exists' =>
        'Ya existe una cuenta con ese email. Prueba a iniciar sesión.',
      'weak_password' => 'La contraseña es demasiado débil. Usa al menos '
          '${Validators.minPasswordLength} caracteres, '
          'con letras y números.',
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' =>
        'Demasiados intentos seguidos. Espera unos minutos y vuelve a probar.',
      'validation_failed' => 'Revisa los datos introducidos.',
      'user_banned' => 'Esta cuenta está deshabilitada.',
      // Cualquier código que no hayamos previsto: mejor el mensaje de
      // Supabase (en inglés, pero concreto) que un "error inesperado".
      _ => e.message,
    };
  }

  /// `dart:io` no existe en web, así que no podemos comprobar
  /// `e is SocketException` sin romper la compilación del navegador;
  /// inspeccionamos el texto, que es estable en la práctica.
  bool _pareceFalloDeRed(Object error) {
    final texto = error.toString();
    return texto.contains('SocketException') ||
        texto.contains('Failed host lookup') ||
        texto.contains('ClientException') ||
        texto.contains('Connection closed') ||
        texto.contains('Connection refused');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
