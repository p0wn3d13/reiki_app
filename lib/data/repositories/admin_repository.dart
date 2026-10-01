import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/perfil.dart';
import '../../domain/models/user_role.dart';
import '../services/supabase_service.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<List<Perfil>> getProfiles() async {
    try {
      final response = await _client
          .from('perfiles')
          .select()
          .order('nombre', ascending: true);

      return (response as List)
          .map((row) => Perfil.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> updateRole({
    required String profileId,
    required UserRole role,
  }) async {
    try {
      await _client
          .from('perfiles')
          .update({'rol': role.dbValue})
          .eq('id', profileId);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<Set<String>> getConfiguredTherapistProfileIds() async {
    try {
        final response = await _client.from('terapeutas').select('user_id');
      return (response as List)
          .map((row) => row['user_id'] as String)
          .toSet();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> createTherapistProfile({
    required String profileId,
    required String specialty,
    String? bio,
  }) async {
    try {
      final existing = await _client
          .from('terapeutas')
          .select('id')
          .eq('user_id', profileId)
          .maybeSingle();

      final data = {
        'user_id': profileId,
        'especialidad': specialty.trim(),
        'bio': bio?.trim(),
        'activo': true,
      };

      if (existing == null) {
        await _client.from('terapeutas').insert(data);
      } else {
        await _client
            .from('terapeutas')
            .update(data)
            .eq('id', existing['id']);
      }
    } catch (error) {
      throw _mapError(error);
    }
  }

  AppException _mapError(Object error) {
    if (error is PostgrestException) {
      return ServerAppException('No se pudo actualizar el perfil: ${error.message}');
    }
    return const UnknownAppException();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminProfilesProvider = FutureProvider.autoDispose<List<Perfil>>((ref) {
  return ref.watch(adminRepositoryProvider).getProfiles();
});

final configuredTherapistProfilesProvider =
    FutureProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(adminRepositoryProvider).getConfiguredTherapistProfileIds();
});
