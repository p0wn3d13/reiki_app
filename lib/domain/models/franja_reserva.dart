import 'package:flutter/foundation.dart';

@immutable
class FranjaReserva {
  const FranjaReserva({
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.plazasTotales,
    required this.plazasOcupadas,
  });

  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final int plazasTotales;
  final int plazasOcupadas;

  int get plazasLibres => plazasTotales - plazasOcupadas;

  factory FranjaReserva.fromMap(Map<String, dynamic> map) {
    return FranjaReserva(
      diaSemana: (map['dia_semana'] as num).toInt(),
      horaInicio: (map['hora_inicio'] as String).substring(0, 5),
      horaFin: (map['hora_fin'] as String).substring(0, 5),
      plazasTotales: (map['plazas_totales'] as num).toInt(),
      plazasOcupadas: (map['plazas_ocupadas'] as num).toInt(),
    );
  }
}
