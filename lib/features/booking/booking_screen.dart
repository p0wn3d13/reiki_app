import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/therapist_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/app_navigation_bar.dart';

// Generar una lista de horas disponibles a partir de la disponibilidad y las citas
final availableSlotsProvider = FutureProvider.family
    .autoDispose<List<DateTime>, _BookingParams>((ref, params) async {
  final availability = await ref
      .watch(therapistRepositoryProvider)
      .getAvailability(params.terapeutaId);
  final appointments = await ref
      .watch(bookingRepositoryProvider)
      .getAppointmentsForDate(params.terapeutaId, params.date);

  // 1=Lunes, 7=Domingo en la bd
  final diaSemana = params.date.weekday;

  // Buscar la disponibilidad para este día de la semana
  final dispList = availability.where((d) => d.diaSemana == diaSemana).toList();

  if (dispList.isEmpty) return [];

  final List<DateTime> slots = [];

  // Para cada bloque de disponibilidad, generamos slots cada hora (simplificación)
  for (final disp in dispList) {
    var currentSlot = DateTime(
      params.date.year,
      params.date.month,
      params.date.day,
      disp.horaInicio.hour,
      disp.horaInicio.minute,
    );

    final endSlot = DateTime(
      params.date.year,
      params.date.month,
      params.date.day,
      disp.horaFin.hour,
      disp.horaFin.minute,
    );

    while (currentSlot.isBefore(endSlot)) {
      // Verificamos si este slot ya está ocupado (asumiendo slots de 1h para este MVP)
      final isOccupied = appointments.any((c) =>
          c.fechaHora.year == currentSlot.year &&
          c.fechaHora.month == currentSlot.month &&
          c.fechaHora.day == currentSlot.day &&
          c.fechaHora.hour == currentSlot.hour &&
          c.fechaHora.minute == currentSlot.minute);

      // Si la cita es en el futuro y no está ocupada
      if (!isOccupied && currentSlot.isAfter(DateTime.now())) {
        slots.add(currentSlot);
      }

      currentSlot = currentSlot.add(const Duration(hours: 1));
    }
  }

  return slots;
});

class _BookingParams {
  const _BookingParams(this.terapeutaId, this.date);
  final String terapeutaId;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BookingParams &&
          runtimeType == other.runtimeType &&
          terapeutaId == other.terapeutaId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => terapeutaId.hashCode ^ date.year ^ date.month ^ date.day;
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.terapeutaId});

  final String terapeutaId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedTime;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final params = _BookingParams(widget.terapeutaId, _selectedDate);
    final slotsAsync = ref.watch(availableSlotsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Cita'),
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Selecciona un día',
              style: AppTheme.subtitleText,
            ),
            const SizedBox(height: 16),
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedTime = null; // Reset time when date changes
                });
              },
            ),
            const SizedBox(height: 32),
            const Text(
              '2. Selecciona una hora',
              style: AppTheme.subtitleText,
            ),
            const SizedBox(height: 16),
            slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Text(
                    'No hay horas disponibles para este día. Prueba con otra fecha.',
                    style: AppTheme.bodyText,
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: slots.map((time) {
                    final isSelected = _selectedTime == time;
                    final timeStr = DateFormat.Hm().format(time); // HH:mm

                    return ChoiceChip(
                      label: Text(timeStr),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTime = selected ? time : null;
                        });
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const ErrorBanner(
                mensaje: 'No se pudo cargar la disponibilidad.',
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTime != null && !_isSubmitting
                    ? _confirmBooking
                    : null,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmar Reserva'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (_selectedTime == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(bookingRepositoryProvider).bookAppointment(
            terapeutaId: widget.terapeutaId,
            fechaHora: _selectedTime!,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita reservada correctamente')),
      );

      // Volver a la pantalla de inicio
      context.go(AppRoutes.patientHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
