/// Errores de dominio de la app (Fase 2, punto 3).
///
/// Los repositorios traducen aquí cualquier excepción de Supabase
/// (PostgrestException, AuthException, errores de red...) para que
/// la capa de presentación nunca tenga que conocer tipos de librerías
/// externas.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class SlotUnavailableException extends AppException {
  const SlotUnavailableException()
      : super('Ese horario ya no está disponible.');
}

class NetworkException extends AppException {
  const NetworkException() : super('No hay conexión a internet.');
}

class AuthAppException extends AppException {
  const AuthAppException(super.message);
}

class ValidationAppException extends AppException {
  const ValidationAppException(super.message);
}

class UnknownAppException extends AppException {
  const UnknownAppException()
      : super('Ha ocurrido un error inesperado. Inténtalo de nuevo.');
}

class ServerAppException extends AppException {
  const ServerAppException(super.message);
}
