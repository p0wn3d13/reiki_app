import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/therapist_repository.dart';
import '../../domain/models/disponibilidad.dart';
import '../../shared/widgets/app_navigation_bar.dart';
import '../../shared/widgets/cuenta_menu.dart';

final therapistOwnAvailabilityProvider =
    FutureProvider.autoDispose<List<Disponibilidad>>((ref) async {
  final therapist =
      await ref.watch(therapistRepositoryProvider).getCurrentTherapist();
  if (therapist == null) return [];
  return ref.watch(therapistRepositoryProvider).getAvailability(therapist.id);
});

class TherapistAvailabilityScreen extends ConsumerWidget {
  const TherapistAvailabilityScreen({super.key});

  static const _options = [
    (
      day: 3,
      start: '10:00:00',
      end: '12:00:00',
      label: 'Miércoles mañana',
      time: '10:00 - 12:00'
    ),
    (
      day: 3,
      start: '16:00:00',
      end: '18:00:00',
      label: 'Miércoles tarde',
      time: '16:00 - 18:00'
    ),
    (
      day: 4,
      start: '10:00:00',
      end: '12:00:00',
      label: 'Jueves mañana',
      time: '10:00 - 12:00'
    ),
    (
      day: 4,
      start: '16:00:00',
      end: '18:00:00',
      label: 'Jueves tarde',
      time: '16:00 - 18:00'
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(therapistOwnAvailabilityProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis horarios'),
        actions: const [CuentaMenu()],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Apúntate a tus franjas',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Los clientes podrán reservarte cuando estés disponible. Cada franja dura dos horas.'),
          const SizedBox(height: 24),
          availability.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Text('No se pudieron cargar tus horarios: $error'),
            data: (items) => Column(
              children: [
                for (final option in _options)
                  _AvailabilityTile(
                    option: option,
                    active: items.any((item) =>
                        item.diaSemana == option.day &&
                        _time(item.horaInicio) ==
                            option.start.substring(0, 5) &&
                        _time(item.horaFin) == option.end.substring(0, 5)),
                    onChanged: (enabled) =>
                        _toggle(context, ref, option, enabled),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'La capacidad de cada franja se actualiza automáticamente según los terapeutas apuntados.',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, dynamic option, bool enabled) async {
    try {
      final therapist =
          await ref.read(therapistRepositoryProvider).getCurrentTherapist();
      if (therapist == null) {
        throw const AuthAppException(
          'No tienes una ficha de terapeuta configurada.',
        );
      }
      await ref.read(therapistRepositoryProvider).setAvailability(
            terapeutaId: therapist.id,
            day: option.day,
            start: option.start,
            end: option.end,
            enabled: enabled,
          );
      ref.invalidate(therapistOwnAvailabilityProvider);
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: AppColors.error),
      );
    }
  }

  static String _time(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile(
      {required this.option, required this.active, required this.onChanged});

  final dynamic option;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile.adaptive(
        value: active,
        onChanged: onChanged,
        secondary: Icon(active ? Icons.event_available : Icons.event_busy,
            color: AppColors.primary),
        title: Text(option.label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(option.time),
      ),
    );
  }
}
