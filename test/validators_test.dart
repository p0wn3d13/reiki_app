import 'package:flutter_test/flutter_test.dart';
import 'package:reiki_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('acepta emails normales', () {
      expect(Validators.email('mario@example.com'), isNull);
      expect(Validators.email('  con.espacios@example.co.uk  '), isNull);
      expect(Validators.email('nombre+etiqueta@example.org'), isNull);
    });

    test('rechaza vacío y formatos claramente inválidos', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('sin-arroba'), isNotNull);
      expect(Validators.email('sin@dominio'), isNotNull);
      expect(Validators.email('dos@@arrobas.com'), isNotNull);
      expect(Validators.email('con espacio@example.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('exige la longitud mínima al registrarse', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('en el login no exige longitud, solo que no esté vacía', () {
      // Una contraseña antigua más corta que el mínimo actual debe poder
      // intentarse: el rechazo lo decide Supabase, no el formulario.
      expect(Validators.passwordLogin('abc'), isNull);
      expect(Validators.passwordLogin(''), isNotNull);
    });

    test('compara la repetición', () {
      expect(Validators.passwordRepetida('secreto1', 'secreto1'), isNull);
      expect(Validators.passwordRepetida('secreto1', 'secreto2'), isNotNull);
      expect(Validators.passwordRepetida('', 'secreto1'), isNotNull);
    });
  });

  group('Validators.telefonoOpcional', () {
    test('vacío es válido, porque la columna admite null', () {
      expect(Validators.telefonoOpcional(''), isNull);
      expect(Validators.telefonoOpcional(null), isNull);
      expect(Validators.telefonoOpcional('   '), isNull);
    });

    test('acepta formatos españoles e internacionales', () {
      expect(Validators.telefonoOpcional('600123456'), isNull);
      expect(Validators.telefonoOpcional('600 12 34 56'), isNull);
      expect(Validators.telefonoOpcional('+34 600 123 456'), isNull);
      expect(Validators.telefonoOpcional('(+34) 600-123-456'), isNull);
    });

    test('rechaza lo que no es un teléfono', () {
      expect(Validators.telefonoOpcional('123'), isNotNull);
      expect(Validators.telefonoOpcional('no soy un telefono'), isNotNull);
    });
  });

  group('Validators.nombre', () {
    test('exige algo más que un carácter', () {
      expect(Validators.nombre('Mario Sánchez'), isNull);
      expect(Validators.nombre('  '), isNotNull);
      expect(Validators.nombre('M'), isNotNull);
    });
  });
}
