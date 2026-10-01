import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// Inicializa Supabase. Se llama una única vez desde main() antes de runApp.
Future<void> initSupabase() async {
  Env.assertConfigured();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseKey,
  );
}

/// Cliente de Supabase disponible en toda la app vía Riverpod.
/// Todos los repositorios dependen de este provider, nunca acceden
/// a Supabase.instance.client directamente (Fase 2, punto 4).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Expone el usuario autenticado actual (o null) de forma reactiva,
/// para que los guards de navegación y la UI puedan reaccionar a
/// cambios de sesión (login, logout, expiración de token).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// La sesión actual, de forma sincrónica.
///
/// `authStateProvider` arranca en `AsyncLoading` hasta que
/// `onAuthStateChange` emite su primer evento. Mientras carga, leemos
/// `currentSession`, que `Supabase.initialize()` ya ha restaurado del
/// almacenamiento local. Sin este fallback, al abrir la app con sesión
/// guardada el router vería `null` durante unos frames y haría un salto
/// visible a `/login` antes de volver.
final currentSessionProvider = Provider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider);

  return authState.maybeWhen(
    data: (state) => state.session,
    orElse: () => client.auth.currentSession,
  );
});

/// UUID del usuario autenticado (el mismo que `perfiles.id`).
///
/// Depender de esto en lugar de la sesión completa evita recargas
/// innecesarias: Supabase refresca el token cada hora y emite una
/// sesión nueva, pero el id no cambia, así que un `Provider<String?>`
/// no notifica y el perfil no se vuelve a pedir.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});
