import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/terapeuta.dart';
import '../../domain/models/disponibilidad.dart';
import '../services/supabase_service.dart';

class TherapistRepository {
  TherapistRepository(this._client);

  final SupabaseClient _client;

  /// Obtiene la lista de todos los terapeutas con sus perfiles (nombre, email).
  Future<List<Terapeuta>> getTherapists() async {
    try {
      final response = await _client
          .from('terapeutas')
          .select('*, perfiles(*)')
          .eq('activo', true);

      return (response as List).map((json) => Terapeuta.fromMap(json)).toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Obtiene los detalles de un terapeuta específico.
  Future<Terapeuta> getTherapist(String id) async {
    try {
      final response = await _client
          .from('terapeutas')
          .select('*, perfiles(*)')
          .eq('id', id)
          .single();

      return Terapeuta.fromMap(response);
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Obtiene la disponibilidad semanal de un terapeuta.
  Future<List<Disponibilidad>> getAvailability(String terapeutaId) async {
    try {
      final response = await _client
          .from('disponibilidad')
          .select()
          .eq('terapeuta_id', terapeutaId)
          .order('dia_semana', ascending: true)
          .order('hora_inicio', ascending: true);

      return (response as List)
          .map((json) => Disponibilidad.fromMap(json))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<Terapeuta?> getCurrentTherapist() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final row = await _client
          .from('terapeutas')
          .select('*, perfiles(*)')
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : Terapeuta.fromMap(row);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> setAvailability({
    required String terapeutaId,
    required int day,
    required String start,
    required String end,
    required bool enabled,
  }) async {
    try {
      final existing = await _client
          .from('disponibilidad')
          .select('id')
          .eq('terapeuta_id', terapeutaId)
          .eq('dia_semana', day)
          .eq('hora_inicio', start)
          .eq('hora_fin', end)
          .maybeSingle();

      if (enabled && existing == null) {
        await _client.from('disponibilidad').insert({
          'terapeuta_id': terapeutaId,
          'dia_semana': day,
          'hora_inicio': start,
          'hora_fin': end,
        });
      } else if (!enabled && existing != null) {
        await _client.from('disponibilidad').delete().eq('id', existing['id']);
      }
    } catch (error) {
      throw _mapError(error);
    }
  }

  AppException _mapError(Object error) {
    if (error is PostgrestException) {
      return ServerAppException('Error del servidor: ${error.message}');
    }
    return const UnknownAppException();
  }
}

final therapistRepositoryProvider = Provider<TherapistRepository>((ref) {
  return TherapistRepository(ref.watch(supabaseClientProvider));
});
