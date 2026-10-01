import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/models/perfil.dart';
import '../../domain/models/user_role.dart';

/// Perfil del usuario autenticado, o `null` si no hay sesión.
///
/// Se reconstruye solo cuando cambia el id de usuario (ver
/// `currentUserIdProvider`), no en cada refresco de token.
final currentPerfilProvider = FutureProvider<Perfil?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return ref
      .watch(authRepositoryProvider)
      .fetchPerfil(userId)
      .timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'La carga del perfil ha tardado demasiado. '
          'Comprueba tu conexión e inténtalo de nuevo.',
        ),
      );
});

/// Rol del usuario autenticado. `null` mientras se carga el perfil,
/// si falla la carga o si no hay sesión.
///
/// Es el provider que consulta el guard del router: devolver `null`
/// significa "todavía no lo sé", y el guard responde dejando al usuario
/// en el splash en vez de adivinar.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentPerfilProvider).valueOrNull?.rol;
});

/// `true` si hay sesión abierta en Supabase.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});
