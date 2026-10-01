import 'package:flutter/foundation.dart';

import 'perfil.dart';
import 'terapeuta.dart';

/// Representa una reserva de cita en la plataforma.
@immutable
class Cita {
  const Cita({
    required this.id,
    required this.clienteId,
    this.terapeutaId,
    required this.fechaHora,
    required this.estado,
    this.notas,
    this.cliente,
    this.terapeuta,
  });

  final String id;
  final String clienteId;
  final String? terapeutaId;
  final DateTime fechaHora;

  /// Estado: 'pendiente', 'confirmada', 'cancelada'
  final String estado;
  final String? notas;

  /// Datos del cliente si vienen en el JOIN
  final Perfil? cliente;

  /// Datos del terapeuta si vienen en el JOIN
  final Terapeuta? terapeuta;

  factory Cita.fromMap(Map<String, dynamic> map) {
    return Cita(
      id: map['id'] as String,
      clienteId: map['cliente_id'] as String,
      terapeutaId: map['terapeuta_id'] as String?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String).toLocal(),
      estado: map['estado'] as String,
      notas: map['notas'] as String?,
      cliente: map['perfiles'] != null
          ? Perfil.fromMap(map['perfiles'] as Map<String, dynamic>)
          : null,
      terapeuta: map['terapeutas'] != null
          ? Terapeuta.fromMap(map['terapeutas'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cita &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clienteId == other.clienteId &&
          terapeutaId == other.terapeutaId &&
          fechaHora == other.fechaHora &&
          estado == other.estado &&
          notas == other.notas &&
          cliente == other.cliente &&
          terapeuta == other.terapeuta;

  @override
  int get hashCode =>
      id.hashCode ^
      clienteId.hashCode ^
      terapeutaId.hashCode ^
      fechaHora.hashCode ^
      estado.hashCode ^
      notas.hashCode ^
      cliente.hashCode ^
      terapeuta.hashCode;
}
