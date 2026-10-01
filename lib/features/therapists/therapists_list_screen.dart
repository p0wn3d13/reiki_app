import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/therapist_repository.dart';
import '../../domain/models/terapeuta.dart';
import '../../shared/widgets/error_banner.dart';

final therapistsListProvider = FutureProvider.autoDispose<List<Terapeuta>>((ref) {
  return ref.watch(therapistRepositoryProvider).getTherapists();
});

class TherapistsListScreen extends ConsumerWidget {
  const TherapistsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapistsAsync = ref.watch(therapistsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir Terapeuta'),
      ),
      body: therapistsAsync.when(
        data: (therapists) {
          if (therapists.isEmpty) {
            return const Center(
              child: Text(
                'No hay terapeutas disponibles en este momento.',
                style: AppTheme.bodyText,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: therapists.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final terapeuta = therapists[index];
              return _TherapistCard(terapeuta: terapeuta);
            },
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

class _TherapistCard extends StatelessWidget {
  const _TherapistCard({required this.terapeuta});

  final Terapeuta terapeuta;

  @override
  Widget build(BuildContext context) {
    final nombre = terapeuta.perfil?.nombreVisible ?? 'Terapeuta sin nombre';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.therapistDetail.replaceAll(':id', terapeuta.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: AppTheme.subtitleText.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.availableBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            terapeuta.especialidad,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.availableText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Ver disponibilidad',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
