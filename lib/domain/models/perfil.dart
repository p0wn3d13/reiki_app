import 'user_role.dart';

/// Fila de la tabla `perfiles` de Supabase.
///
/// Columnas reales verificadas contra el proyecto
/// (`id`, `email`, `nombre`, `telefono`, `rol`, `expo_push_token`,
/// `created_at`). El `id` es el mismo UUID que `auth.users.id`.
///
/// Escrito a mano en vez de con freezed para que el proyecto compile sin
/// tener que pasar por `build_runner`; el modelo es inmutable igualmente.
class Perfil {
  const Perfil({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    this.telefono,
    this.fotoUrl,
    this.pushToken,
    this.createdAt,
  });

  final String id;
  final String email;
  final String nombre;
  final UserRole rol;
  final String? telefono;
  final String? fotoUrl;

  /// Token de notificaciones push. La columna se llama
  /// `expo_push_token` porque el esquema se creó pensando en Expo; esta
  /// app usa FCM (Fase 11), así que ahí se guardará el token de Firebase.
  final String? pushToken;

  final DateTime? createdAt;

  /// Nombre para mostrar en la UI. La columna `nombre` puede estar
  /// vacía en filas creadas antes de la Fase 8, así que caemos al email
  /// para no pintar un hueco en blanco.
  String get nombreVisible {
    final n = nombre.trim();
    return n.isEmpty ? email : n;
  }

  /// Primer nombre, para saludos del tipo "Hola, Mario".
  String get primerNombre => nombreVisible.split(' ').first;

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as String,
      email: (map['email'] as String?) ?? '',
      nombre: (map['nombre'] as String?) ?? '',
      rol: UserRole.fromDb(map['rol'] as String?),
      telefono: map['telefono'] as String?,
      fotoUrl: map['foto_url'] as String?,
      pushToken: map['expo_push_token'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? ''),
    );
  }

  /// Solo las columnas que la app escribe. `id` va aparte porque en un
  /// `upsert` actúa de clave y en un `update` no debe tocarse.
  Map<String, dynamic> toUpdateMap() {
    return {
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'foto_url': fotoUrl,
    };
  }

  Perfil copyWith({
    String? nombre,
    String? telefono,
    String? fotoUrl,
    String? pushToken,
  }) {
    return Perfil(
      id: id,
      email: email,
      nombre: nombre ?? this.nombre,
      rol: rol,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      pushToken: pushToken ?? this.pushToken,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Perfil &&
      other.id == id &&
      other.email == email &&
      other.nombre == nombre &&
      other.rol == rol &&
      other.telefono == telefono &&
      other.fotoUrl == fotoUrl &&
      other.pushToken == pushToken;

  @override
  int get hashCode => Object.hash(id, email, nombre, rol, telefono, fotoUrl, pushToken);

  @override
  String toString() => 'Perfil($email, ${rol.dbValue})';
}
