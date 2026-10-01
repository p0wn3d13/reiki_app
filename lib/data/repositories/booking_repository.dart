import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/cita.dart';
import '../../domain/models/franja_reserva.dart';
import '../services/supabase_service.dart';

class BookingRepository {
  BookingRepository(this._client);

  final SupabaseClient _client;

  Future<List<FranjaReserva>> getSharedSlots(DateTime date) async {
    try {
      final therapists =
          await _client.from('terapeutas').select('id').eq('activo', true);
      final therapistIds =
          (therapists as List).map((row) => row['id'] as String).toList();

      if (therapistIds.isEmpty) return [];

      final availability = await _client
          .from('disponibilidad')
          .select('dia_semana, hora_inicio, hora_fin, terapeuta_id')
          .eq('dia_semana', date.weekday)
          .inFilter('terapeuta_id', therapistIds);

      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final appointments = await _client
          .from('citas')
          .select('fecha_hora, estado')
          .gte('fecha_hora', start.toUtc().toIso8601String())
          .lt('fecha_hora', end.toUtc().toIso8601String())
          .inFilter('estado', ['pendiente', 'confirmada']);

      final counts = <String, int>{};
      for (final row in appointments as List) {
        final time = DateTime.parse(row['fecha_hora'] as String).toLocal();
        final key =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      final totals = <String, int>{};
      final ends = <String, String>{};
      for (final row in availability as List) {
        final startTime = (row['hora_inicio'] as String).substring(0, 5);
        final endTime = (row['hora_fin'] as String).substring(0, 5);
        totals[startTime] = (totals[startTime] ?? 0) + 1;
        ends[startTime] = endTime;
      }

      return totals.entries
          .map((entry) => FranjaReserva(
                diaSemana: date.weekday,
                horaInicio: entry.key,
                horaFin: ends[entry.key]!,
                plazasTotales: entry.value,
                plazasOcupadas: counts[entry.key] ?? 0,
              ))
          .where((slot) => slot.plazasLibres > 0)
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  /// Obtiene las citas de un cliente.
  Future<List<Cita>> getPatientAppointments() async {
    try {
      final response = await _client
          .from('citas')
          .select('*, terapeutas(*, perfiles(*))')
          .eq('cliente_id', _client.auth.currentUser!.id)
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) => Cita.fromMap(json)).toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Obtiene las citas de un terapeuta (para su dashboard).
  Future<List<Cita>> getTherapistAppointments() async {
    try {
      // Primero encontramos el terapeuta_id correspondiente al usuario actual
      final terapeutaResponse = await _client
          .from('terapeutas')
          .select('id')
          .eq('user_id', _client.auth.currentUser!.id)
          .maybeSingle();

      if (terapeutaResponse == null) {
        return [];
      }

      final terapeutaId = terapeutaResponse['id'] as String;

      final response = await _client
          .from('citas')
          .select('*, perfiles(*)') // Perfiles del cliente
          .eq('terapeuta_id', terapeutaId)
          .order('fecha_hora', ascending: true);

      return (response as List).map((json) {
        // El JOIN con perfiles lo metemos como cliente
        final map = Map<String, dynamic>.from(json);
        return Cita.fromMap(map);
      }).toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<Cita>> getTeamAppointments() async {
    try {
      final response = await _client
          .from('citas')
          .select('*, perfiles(*), terapeutas(*, perfiles(*))')
          .inFilter('estado', ['confirmada', 'completada']).order('fecha_hora',
              ascending: true);

      return (response as List).map((json) {
        return Cita.fromMap(Map<String, dynamic>.from(json));
      }).toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  /// Obtiene las citas de un terapeuta en un día concreto para ver qué horas están ocupadas.
  Future<List<Cita>> getAppointmentsForDate(
      String terapeutaId, DateTime date) async {
    try {
      final startOfDay =
          DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      final response = await _client
          .from('citas')
          .select()
          .eq('terapeuta_id', terapeutaId)
          .gte('fecha_hora', startOfDay)
          .lte('fecha_hora', endOfDay)
          .inFilter(
              'estado', ['pendiente', 'confirmada']); // Ignoramos canceladas

      return (response as List).map((json) => Cita.fromMap(json)).toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Reserva una cita mediante la función RPC segura.
  Future<Cita> bookAppointment({
    String? terapeutaId,
    required DateTime fechaHora,
    String? notas,
  }) async {
    try {
      final response = await _client.rpc('create_appointment_by_slot', params: {
        'p_fecha_hora': fechaHora.toUtc().toIso8601String(),
        'p_notas': notas,
      });

      final citaId = response as String;

      // Recuperar la cita recién creada con todos sus datos
      final citaResponse = await _client
          .from('citas')
          .select('*, terapeutas(*, perfiles(*))')
          .eq('id', citaId)
          .single();

      return Cita.fromMap(citaResponse);
    } catch (e) {
      if (e is PostgrestException &&
          e.message.contains('ya tiene una cita reservada')) {
        throw const SlotUnavailableException();
      }
      throw _mapError(e);
    }
  }

  /// Cancela una cita.
  Future<void> cancelAppointment(String citaId) async {
    try {
      await _client
          .from('citas')
          .update({'estado': 'cancelada'}).eq('id', citaId);
    } catch (e) {
      throw _mapError(e);
    }
  }

  AppException _mapError(Object error) {
    if (error is PostgrestException) {
      return ServerAppException('Error del servidor: ${error.message}');
    }
    return const UnknownAppException();
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(supabaseClientProvider));
});
