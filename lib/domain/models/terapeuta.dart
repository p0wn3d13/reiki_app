import 'package:flutter/foundation.dart';

import 'perfil.dart';

/// Representa a un terapeuta en la plataforma.
@immutable
class Terapeuta {
  const Terapeuta({
    required this.id,
    required this.perfilId,
    required this.especialidad,
    this.bio,
    this.perfil,
  });

  final String id;
  final String perfilId;
  final String especialidad;
  final String? bio;

  /// El perfil asociado (nombre, foto, etc.), si se ha incluido en la consulta (JOIN).
  final Perfil? perfil;

  factory Terapeuta.fromMap(Map<String, dynamic> map) {
    return Terapeuta(
      id: map['id'] as String,
      perfilId: map['user_id'] as String,
      especialidad: map['especialidad'] as String,
      bio: map['bio'] as String?,
      perfil: map['perfiles'] != null
          ? Perfil.fromMap(map['perfiles'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Terapeuta &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          perfilId == other.perfilId &&
          especialidad == other.especialidad &&
          bio == other.bio &&
          perfil == other.perfil;

  @override
  int get hashCode =>
      id.hashCode ^
      perfilId.hashCode ^
      especialidad.hashCode ^
      bio.hashCode ^
      perfil.hashCode;

  @override
  String toString() {
    return 'Terapeuta{id: $id, especialidad: $especialidad, perfil: $perfil}';
  }
}
