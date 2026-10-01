import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/reiki_brand.dart';

/// Envoltorio común de las tres pantallas de acceso (login, registro y
/// recuperación de contraseña): logo, título y una columna centrada con
/// ancho máximo.
///
/// El `SingleChildScrollView` no es decorativo: sin él, al abrirse el
/// teclado en un móvil pequeño el formulario desborda y Flutter pinta la
/// franja amarilla de overflow.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.titulo,
    required this.children,
    this.subtitulo,
    this.mostrarVolver = false,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> children;

  /// Botón de volver, para las pantallas a las que se llega desde el
  /// login (registro y recuperación).
  final bool mostrarVolver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: mostrarVolver
          ? AppBar(leading: const BackButton(), title: const Text(''))
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -90,
              right: -70,
              child: _BackdropShape(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  // En web y tablet el formulario se quedaría absurdamente
                  // ancho; 420 es el ancho de un móvil grande.
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ReikiBrandMark(size: 110, showText: true),
                      const SizedBox(height: 22),
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitulo!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 28),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marca de la asociación.
///
/// La identidad visual real se centraliza en el widget compartido
/// `ReikiBrandMark`, que se usa también en la splash y en otros puntos.
class _BackdropShape extends StatelessWidget {
  const _BackdropShape();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
