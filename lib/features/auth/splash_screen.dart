import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/reiki_brand.dart';
import 'auth_providers.dart';
import 'widgets/auth_shell.dart';

/// Pantalla de espera entre "hay sesión" y "sé qué rol tiene".
///
/// El guard del router manda aquí a cualquier usuario autenticado
/// mientras `currentPerfilProvider` está cargando, y también si esa
/// carga falla — de ahí que además de un spinner tenga que saber
/// mostrar el error y ofrecer una salida.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(currentPerfilProvider);

    return perfil.when(
      loading: () => const _Cargando(),
      // `data` con perfil resuelto es un estado de paso: el guard ya
      // está redirigiendo al inicio del rol correspondiente, así que lo
      // único sensato que se puede pintar durante ese frame es el
      // spinner.
      data: (_) => const _Cargando(),
      error: (error, _) => _ErrorDePerfil(mensaje: error.toString()),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ReikiBrandMark(size: 120),
            const SizedBox(height: 18),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorDePerfil extends ConsumerStatefulWidget {
  const _ErrorDePerfil({required this.mensaje});

  final String mensaje;

  @override
  ConsumerState<_ErrorDePerfil> createState() => _ErrorDePerfilState();
}

class _ErrorDePerfilState extends ConsumerState<_ErrorDePerfil> {
  bool _saliendo = false;

  Future<void> _cerrarSesion() async {
    setState(() => _saliendo = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      // Sin sesión, el guard del router lleva a /login por su cuenta.
    } finally {
      if (mounted) setState(() => _saliendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      titulo: 'No hemos podido cargar tu perfil',
      children: [
        ErrorBanner(mensaje: widget.mensaje),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saliendo
              ? null
              : () => ref.invalidate(currentPerfilProvider),
          child: const Text('Reintentar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _saliendo ? null : _cerrarSesion,
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
