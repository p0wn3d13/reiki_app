import 'package:flutter_test/flutter_test.dart';
import 'package:reiki_app/domain/models/perfil.dart';
import 'package:reiki_app/domain/models/user_role.dart';

void main() {
  group('Perfil.fromMap', () {
    test('carga la foto del perfil desde foto_url', () {
      final perfil = Perfil.fromMap({
        'id': '123',
        'email': 'mario@example.com',
        'nombre': 'Mario',
        'rol': 'cliente',
        'telefono': '600123456',
        'foto_url': 'https://cdn.example.com/avatar.jpg',
      });

      expect(perfil.rol, UserRole.cliente);
      expect(perfil.fotoUrl, 'https://cdn.example.com/avatar.jpg');
    });
  });
}
