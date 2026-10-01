import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Representa la disponibilidad de un terapeuta para un día de la semana.
@immutable
class Disponibilidad {
  const Disponibilidad({
    required this.id,
    required this.terapeutaId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  final String id;
  final String terapeutaId;
  /// Día de la semana (1 = Lunes, 7 = Domingo)
  final int diaSemana;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;

  factory Disponibilidad.fromMap(Map<String, dynamic> map) {
    return Disponibilidad(
      id: map['id'] as String,
      terapeutaId: map['terapeuta_id'] as String,
      diaSemana: map['dia_semana'] as int,
      horaInicio: _parseTime(map['hora_inicio'] as String),
      horaFin: _parseTime(map['hora_fin'] as String),
    );
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Disponibilidad &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          terapeutaId == other.terapeutaId &&
          diaSemana == other.diaSemana &&
          horaInicio == other.horaInicio &&
          horaFin == other.horaFin;

  @override
  int get hashCode =>
      id.hashCode ^
      terapeutaId.hashCode ^
      diaSemana.hashCode ^
      horaInicio.hashCode ^
      horaFin.hashCode;
}
