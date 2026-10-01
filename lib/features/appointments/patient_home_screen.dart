import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/models/cita.dart';
import '../../shared/widgets/cuenta_menu.dart';
import '../../shared/widgets/app_navigation_bar.dart';
import '../../shared/widgets/error_banner.dart';
import '../auth/auth_providers.dart';

final patientAppointmentsProvider =
    FutureProvider.autoDispose<List<Cita>>((ref) {
  return ref.watch(bookingRepositoryProvider).getPatientAppointments();
});

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(currentPerfilProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;
    final citasAsync = ref.watch(patientAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: const [CuentaMenu()],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              perfil == null ? 'Hola' : 'Hola, ${perfil.primerNombre}',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aquí verás tus próximas sesiones.',
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Citas',
                  style: AppTheme.subtitleText,
                ),
                TextButton.icon(
                  onPressed: () {
                    debugPrint('[PatientHome] Nueva Reserva pulsada');
                    context.go(AppRoutes.therapistsList);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Nueva Reserva'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: citasAsync.when(
                data: (citas) {
                  if (citas.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tienes ninguna cita programada.',
                        style: AppTheme.bodyText,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: citas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cita = citas[index];
                      return _CitaCard(
                        cita: cita,
                        onCancelada: () =>
                            ref.invalidate(patientAppointmentsProvider),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const ErrorBanner(
                  mensaje: 'Error al cargar tus citas.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  const _CitaCard({required this.cita, required this.onCancelada});

  final Cita cita;
  final VoidCallback onCancelada;

  @override
  Widget build(BuildContext context) {
    final terapeutaNombre =
        cita.terapeuta?.perfil?.nombreVisible ?? 'Terapeuta';

    final Color estadoColor;
    final IconData estadoIcon;
    switch (cita.estado) {
      case 'confirmada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle_outline;
        break;
      case 'cancelada':
        estadoColor = AppColors.error;
        estadoIcon = Icons.cancel_outlined;
        break;
      default:
        estadoColor = Colors.orange;
        estadoIcon = Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: estadoColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(estadoIcon, color: estadoColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      cita.estado.toUpperCase(),
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat("d 'de' MMMM, yyyy", 'es_ES')
                      .format(cita.fechaHora),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  radius: 24,
                  child: const Icon(Icons.spa, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        terapeutaNombre,
                        style: AppTheme.subtitleText.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(cita.fechaHora),
                        style: AppTheme.bodyText.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cita.estado == 'pendiente')
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppColors.error),
                    tooltip: 'Cancelar cita',
                    onPressed: () => _confirmarCancelacion(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCancelacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Seguro que quieres cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await ProviderScope.containerOf(context, listen: false)
          .read(bookingRepositoryProvider)
          .cancelAppointment(cita.id);
      if (!context.mounted) return;
      onCancelada();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada correctamente')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cancelar la cita.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
