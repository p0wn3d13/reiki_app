/// Validadores de formulario reutilizables.
///
/// Devuelven `null` cuando el valor es válido y el mensaje de error en
/// caso contrario, que es exactamente el contrato que espera
/// `TextFormField.validator`.
class Validators {
  Validators._();

  /// Deliberadamente permisivo: solo descarta lo que es claramente no
  /// un email. La comprobación real la hace Supabase al enviar el
  /// correo de confirmación; un regex estricto aquí solo produce falsos
  /// negativos con dominios legítimos.
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  /// Caracteres admitidos en un teléfono escrito por una persona:
  /// dígitos, espacios, guiones, puntos, paréntesis y `+`. La cuenta de
  /// dígitos se comprueba aparte, para que esto no acepte `+++++++++`.
  static final _telefonoRegex = RegExp(r'^[\d\s\-().+]+$');

  /// Mínimo que exige Supabase Auth por defecto.
  static const minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu email.';
    if (!_emailRegex.hasMatch(v)) return 'Ese email no parece válido.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Escribe tu contraseña.';
    if (v.length < minPasswordLength) {
      return 'Al menos $minPasswordLength caracteres.';
    }
    return null;
  }

  /// Para el login no tiene sentido exigir longitud mínima: si la
  /// contraseña guardada es antigua y más corta, el usuario quedaría
  /// bloqueado sin poder ni intentarlo.
  static String? passwordLogin(String? value) {
    if ((value ?? '').isEmpty) return 'Escribe tu contraseña.';
    return null;
  }

  static String? passwordRepetida(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Repite la contraseña.';
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  static String? nombre(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu nombre.';
    if (v.length < 2) return 'Nombre demasiado corto.';
    return null;
  }

  /// El teléfono es opcional en `perfiles` (la columna admite null).
  ///
  /// Se valida en dos pasos porque la gente escribe el prefijo de
  /// muchas formas —`+34 600...`, `(+34) 600-123-456`, `0034...`— y lo
  /// único constante es cuántos dígitos hay: de 9 (fijo o móvil
  /// nacional) a 15 (máximo del estándar E.164).
  static String? telefonoOpcional(String? value) {
    const invalido = 'Ese teléfono no parece válido.';

    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_telefonoRegex.hasMatch(v)) return invalido;

    final digitos = v.replaceAll(RegExp(r'\D'), '').length;
    if (digitos < 9 || digitos > 15) return invalido;

    return null;
  }
}
