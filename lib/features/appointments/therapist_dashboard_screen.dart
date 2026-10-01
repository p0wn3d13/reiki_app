import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/models/cita.dart';
import '../../shared/widgets/cuenta_menu.dart';
import '../../shared/widgets/app_navigation_bar.dart';
import '../../shared/widgets/error_banner.dart';
import '../auth/auth_providers.dart';

final therapistAppointmentsProvider =
    FutureProvider.autoDispose<List<Cita>>((ref) {
  return ref.watch(bookingRepositoryProvider).getTeamAppointments();
});

class TherapistDashboardScreen extends ConsumerWidget {
  const TherapistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(currentPerfilProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;
    final citasAsync = ref.watch(therapistAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            const SizedBox(height: 4),
            if (perfil != null)
              Text(perfil.rol.label, style: textTheme.bodySmall),
            const SizedBox(height: 24),
            const Text(
              'Agenda compartida',
              style: AppTheme.subtitleText,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: citasAsync.when(
                data: (citas) {
                  if (citas.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay clientes apuntados a tus franjas.',
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
                        onCanceled: () =>
                            ref.refresh(therapistAppointmentsProvider),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const ErrorBanner(
                  mensaje: 'Error al cargar tu agenda.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitaCard extends ConsumerStatefulWidget {
  const _CitaCard({required this.cita, required this.onCanceled});

  final Cita cita;
  final VoidCallback onCanceled;

  @override
  ConsumerState<_CitaCard> createState() => _CitaCardState();
}

class _CitaCardState extends ConsumerState<_CitaCard> {
  bool _isCanceling = false;

  @override
  Widget build(BuildContext context) {
    final clienteNombre = widget.cita.cliente?.nombreVisible ?? 'Cliente';
    final formatter = DateFormat('dd MMM yyyy, HH:mm');

    Color estadoColor;
    switch (widget.cita.estado) {
      case 'confirmada':
        estadoColor = Colors.green;
        break;
      case 'cancelada':
        estadoColor = AppColors.error;
        break;
      default:
        estadoColor = Colors.orange;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatter.format(widget.cita.fechaHora),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.cita.estado.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cliente: $clienteNombre', style: AppTheme.bodyText),
            if (widget.cita.notas != null && widget.cita.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notas: ${widget.cita.notas}', style: AppTheme.bodySmall),
            ],
            if (widget.cita.estado != 'cancelada') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isCanceling ? null : _cancelarCita,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: _isCanceling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cancelar Cita'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelarCita() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text(
            '¿Estás seguro de que quieres cancelar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar Cita'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCanceling = true);

    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelAppointment(widget.cita.id);
      widget.onCanceled();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
      setState(() => _isCanceling = false);
    }
  }
}
