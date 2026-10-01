/// Roles de usuario tal y como están guardados en la columna
/// `perfiles.rol` de Supabase.
///
/// Importante: el esquema de la base de datos está en **español**
/// (`cliente`, no `patient`), así que `dbValue` es la única fuente de
/// verdad para hablar con Postgres; el resto de la app usa el enum.
enum UserRole {
  cliente('cliente'),
  terapeuta('terapeuta'),
  admin('admin');

  const UserRole(this.dbValue);

  /// Valor literal almacenado en `perfiles.rol`.
  final String dbValue;

  /// Convierte el valor de la base de datos al enum.
  ///
  /// Ante un valor desconocido o nulo devuelve [cliente], que es el rol
  /// con menos privilegios: si algún día se añade un rol nuevo en la BD,
  /// una app antigua degrada a cliente en vez de conceder permisos de
  /// terapeuta por accidente.
  static UserRole fromDb(String? value) {
    for (final role in UserRole.values) {
      if (role.dbValue == value) return role;
    }
    return UserRole.cliente;
  }

  /// `true` para los roles del equipo de la asociación, que comparten
  /// el dashboard de terapeuta.
  bool get isStaff => this == UserRole.terapeuta || this == UserRole.admin;

  String get label => switch (this) {
        UserRole.cliente => 'Cliente',
        UserRole.terapeuta => 'Terapeuta',
        UserRole.admin => 'Administrador',
      };
}
