import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/auth_providers.dart';

/// Menú de cuenta para la `AppBar`: muestra quién ha entrado y permite
/// cerrar sesión. Sirve tanto para el cliente como para el terapeuta.
class CuentaMenu extends ConsumerWidget {
  const CuentaMenu({super.key});

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que volver a entrar con tu email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // Tras el signOut el guard del router redirige a /login, no hace
    // falta navegar a mano.
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(currentPerfilProvider).valueOrNull;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Mi cuenta',
      onSelected: (valor) {
        if (valor == 'salir') _cerrarSesion(context, ref);
        if (valor == 'perfil') context.push(AppRoutes.profile);
      },
      itemBuilder: (context) => [
        if (perfil != null)
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  perfil.nombreVisible,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  perfil.rol.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (perfil != null) const PopupMenuDivider(),
        if (perfil != null)
          const PopupMenuItem<String>(
            value: 'perfil',
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 20),
                SizedBox(width: 12),
                Text('Mi perfil'),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'salir',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }
}
