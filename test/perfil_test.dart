import 'package:flutter_test/flutter_test.dart';
import 'package:reiki_app/domain/models/perfil.dart';
import 'package:reiki_app/domain/models/user_role.dart';

void main() {
  group('Perfil.fromMap', () {
    test('lee una fila real de la tabla perfiles', () {
      // Fila tal y como la devuelve PostgREST en el proyecto de Supabase.
      final perfil = Perfil.fromMap({
        'id': '086b6de9-0b5f-47c2-a11e-8a8e7a128976',
        'email': 'mario@example.com',
        'nombre': 'Mario Sánchez',
        'telefono': null,
        'rol': 'cliente',
        'expo_push_token': null,
        'created_at': '2026-09-05T00:00:11.600782+00:00',
      });

      expect(perfil.id, '086b6de9-0b5f-47c2-a11e-8a8e7a128976');
      expect(perfil.email, 'mario@example.com');
      expect(perfil.nombre, 'Mario Sánchez');
      expect(perfil.telefono, isNull);
      expect(perfil.rol, UserRole.cliente);
      expect(perfil.createdAt?.year, 2026);
    });

    test('cae al email cuando la columna nombre viene vacía', () {
      final perfil = Perfil.fromMap({
        'id': 'x',
        'email': 'mario@example.com',
        'nombre': '',
        'rol': 'cliente',
      });

      expect(perfil.nombreVisible, 'mario@example.com');
      expect(perfil.primerNombre, 'mario@example.com');
    });

    test('primerNombre corta por el primer espacio', () {
      final perfil = Perfil.fromMap({
        'id': 'x',
        'email': 'm@e.com',
        'nombre': 'Mario Sánchez Barroso',
        'rol': 'terapeuta',
      });

      expect(perfil.primerNombre, 'Mario');
    });

    test('tolera columnas ausentes sin lanzar', () {
      final perfil = Perfil.fromMap({'id': 'x'});

      expect(perfil.email, '');
      expect(perfil.rol, UserRole.cliente);
      expect(perfil.createdAt, isNull);
    });
  });

  group('UserRole', () {
    test('mapea los valores en español de la base de datos', () {
      expect(UserRole.fromDb('cliente'), UserRole.cliente);
      expect(UserRole.fromDb('terapeuta'), UserRole.terapeuta);
      expect(UserRole.fromDb('admin'), UserRole.admin);
    });

    test('un rol desconocido degrada a cliente, no a terapeuta', () {
      // Si la BD gana un rol nuevo, una app antigua no debe concederse
      // permisos de más por accidente.
      expect(UserRole.fromDb('rol_del_futuro'), UserRole.cliente);
      expect(UserRole.fromDb(null), UserRole.cliente);
      expect(UserRole.fromDb('patient'), UserRole.cliente);
    });

    test('isStaff distingue quién ve el dashboard', () {
      expect(UserRole.cliente.isStaff, isFalse);
      expect(UserRole.terapeuta.isStaff, isTrue);
      expect(UserRole.admin.isStaff, isTrue);
    });
  });
}
