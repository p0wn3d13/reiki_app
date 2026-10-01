import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/therapist_repository.dart';
import '../../domain/models/terapeuta.dart';
import '../../domain/models/disponibilidad.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/app_navigation_bar.dart';

final therapistDetailProvider =
    FutureProvider.family.autoDispose<Terapeuta, String>((ref, id) {
  return ref.watch(therapistRepositoryProvider).getTherapist(id);
});

final therapistAvailabilityProvider =
    FutureProvider.family.autoDispose<List<Disponibilidad>, String>((ref, id) {
  return ref.watch(therapistRepositoryProvider).getAvailability(id);
});

class TherapistDetailScreen extends ConsumerWidget {
  const TherapistDetailScreen({super.key, required this.terapeutaId});

  final String terapeutaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapistAsync = ref.watch(therapistDetailProvider(terapeutaId));
    final availabilityAsync =
        ref.watch(therapistAvailabilityProvider(terapeutaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Terapeuta'),
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: therapistAsync.when(
        data: (terapeuta) {
          final nombre = terapeuta.perfil?.nombreVisible ?? 'Sin nombre';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    nombre,
                    style: AppTheme.headline,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    terapeuta.especialidad,
                    style: AppTheme.subtitleText
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),
                if (terapeuta.bio != null && terapeuta.bio!.isNotEmpty) ...[
                  const Text(
                    'Sobre mí',
                    style: AppTheme.subtitleText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    terapeuta.bio!,
                    style: AppTheme.bodyText,
                  ),
                  const SizedBox(height: 32),
                ],
                const Text(
                  'Horario habitual',
                  style: AppTheme.subtitleText,
                ),
                const SizedBox(height: 16),
                availabilityAsync.when(
                  data: (availability) {
                    if (availability.isEmpty) {
                      return const Text(
                        'Este terapeuta aún no ha configurado su disponibilidad.',
                        style: AppTheme.bodyText,
                      );
                    }
                    return _AvailabilityList(availability: availability);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorBanner(
                    mensaje: error.toString(),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        'booking',
                        pathParameters: {'id': terapeuta.id},
                      );
                    },
                    child: const Text('Reservar Cita'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            mensaje: error.toString(),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityList extends StatelessWidget {
  const _AvailabilityList({required this.availability});

  final List<Disponibilidad> availability;

  static const dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: availability.map((disp) {
        final diaStr = disp.diaSemana >= 1 && disp.diaSemana <= 7
            ? dias[disp.diaSemana - 1]
            : 'Desconocido';

        final inicio =
            '${disp.horaInicio.hour.toString().padLeft(2, '0')}:${disp.horaInicio.minute.toString().padLeft(2, '0')}';
        final fin =
            '${disp.horaFin.hour.toString().padLeft(2, '0')}:${disp.horaFin.minute.toString().padLeft(2, '0')}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                diaStr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('$inicio - $fin'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
