import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Aviso de error en línea, dentro del formulario.
///
/// Se usa en lugar de un `SnackBar` para los errores de validación del
/// servidor: el mensaje se queda a la vista mientras el usuario corrige
/// los campos, en vez de desaparecer a los cuatro segundos.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 20,
            color: AppColors.warningText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de operación correcta (registro enviado, email de recuperación
/// enviado...). Mismo formato que [ErrorBanner] para que la pantalla no
/// dé saltos al cambiar de uno a otro.
class SuccessBanner extends StatelessWidget {
  const SuccessBanner({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.availableBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.availableText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.availableText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
