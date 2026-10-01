import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/models/franja_reserva.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/app_navigation_bar.dart';

final sharedSlotsProvider = FutureProvider.family
    .autoDispose<List<FranjaReserva>, DateTime>((ref, date) {
  return ref.watch(bookingRepositoryProvider).getSharedSlots(date);
});

class SharedBookingScreen extends ConsumerStatefulWidget {
  const SharedBookingScreen({super.key});

  @override
  ConsumerState<SharedBookingScreen> createState() =>
      _SharedBookingScreenState();
}

class _SharedBookingScreenState extends ConsumerState<SharedBookingScreen> {
  DateTime _date = _nextBookingDay(DateTime.now());
  FranjaReserva? _selected;
  bool _sending = false;

  static DateTime _nextBookingDay(DateTime date) {
    var result = DateTime(date.year, date.month, date.day);
    while (result.weekday != DateTime.wednesday &&
        result.weekday != DateTime.thursday) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(sharedSlotsProvider(_date));
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      bottomNavigationBar: const AppNavigationBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text('Elige una franja',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text(
              'La app te asignará automáticamente un terapeuta disponible.'),
          const SizedBox(height: 20),
          CalendarDatePicker(
            initialDate: _date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
            selectableDayPredicate: (date) =>
                date.weekday == DateTime.wednesday ||
                date.weekday == DateTime.thursday,
            onDateChanged: (date) => setState(() {
              _date = date;
              _selected = null;
            }),
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat("EEEE d 'de' MMMM", 'es_ES').format(_date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          slots.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorBanner(mensaje: error.toString()),
            data: (items) => items.isEmpty
                ? const Text('No quedan plazas para ese día.')
                : Column(
                    children: items
                        .map((slot) => _SlotTile(
                              slot: slot,
                              selected: _selected == slot,
                              onTap: () => setState(() => _selected = slot),
                            ))
                        .toList()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selected == null || _sending ? null : _book,
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Confirmar reserva'),
          ),
        ],
      ),
    );
  }

  Future<void> _book() async {
    final slot = _selected!;
    final parts = slot.horaInicio.split(':');
    final dateTime = DateTime(_date.year, _date.month, _date.day,
        int.parse(parts[0]), int.parse(parts[1]));
    setState(() => _sending = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .bookAppointment(fechaHora: dateTime);
      if (!mounted) return;
      setState(() => _sending = false);
      context.go(AppRoutes.patientHome);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted && _sending) setState(() => _sending = false);
    }
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile(
      {required this.slot, required this.selected, required this.onTap});

  final FranjaReserva slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? AppColors.primaryLight : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(selected ? Icons.check_circle : Icons.schedule,
            color: AppColors.primary),
        title: Text('${slot.horaInicio} - ${slot.horaFin}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${slot.plazasLibres} ${slot.plazasLibres == 1 ? 'plaza libre' : 'plazas libres'} de ${slot.plazasTotales}'),
        trailing: selected
            ? const Icon(Icons.radio_button_checked)
            : const Icon(Icons.radio_button_off),
      ),
    );
  }
}
