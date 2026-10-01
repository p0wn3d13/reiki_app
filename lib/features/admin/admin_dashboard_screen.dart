import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/models/perfil.dart';
import '../../domain/models/user_role.dart';
import '../../shared/widgets/cuenta_menu.dart';
import '../../shared/widgets/app_navigation_bar.dart';
import '../../shared/widgets/error_banner.dart';
import '../auth/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(currentPerfilProvider).valueOrNull;
    final profiles = ref.watch(adminProfilesProvider);
    final configuredTherapists =
        ref.watch(configuredTherapistProfilesProvider).valueOrNull ??
            <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: const [CuentaMenu()],
      ),
      bottomNavigationBar: const AppNavigationBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminProfilesProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              perfil == null
                  ? 'Panel de control'
                  : 'Hola, ${perfil.primerNombre}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Gestiona las cuentas y los permisos de la asociación.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Personas registradas',
              count: profiles.valueOrNull?.length,
            ),
            const SizedBox(height: 12),
            profiles.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const ErrorBanner(
                mensaje: 'No se han podido cargar los perfiles.',
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProfileTile(
                              profile: item,
                              isCurrentUser:
                                  item.id == ref.read(currentUserIdProvider),
                              isConfiguredTherapist:
                                  configuredTherapists.contains(item.id),
                              onRoleChanged: (role) => _changeRole(
                                context,
                                ref,
                                item,
                                role,
                              ),
                              onConfigureTherapist: () =>
                                  _configureTherapist(context, ref, item),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    Perfil profile,
    UserRole role,
  ) async {
    if (role == profile.rol) return;

    try {
      await ref.read(adminRepositoryProvider).updateRole(
            profileId: profile.id,
            role: role,
          );
      ref.invalidate(adminProfilesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.nombreVisible}: rol actualizado')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _configureTherapist(
    BuildContext context,
    WidgetRef ref,
    Perfil profile,
  ) async {
    final specialtyController = TextEditingController();
    final bioController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ficha de ${profile.nombreVisible}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Especialidad',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica una especialidad'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Presentación (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar ficha'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      specialtyController.dispose();
      bioController.dispose();
      return;
    }

    try {
      await ref.read(adminRepositoryProvider).createTherapistProfile(
            profileId: profile.id,
            specialty: specialtyController.text,
            bio: bioController.text,
          );
      ref.invalidate(configuredTherapistProfilesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha de terapeuta creada')),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: AppColors.error),
      );
    } finally {
      specialtyController.dispose();
      bioController.dispose();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isCurrentUser,
    required this.isConfiguredTherapist,
    required this.onRoleChanged,
    required this.onConfigureTherapist,
  });

  final Perfil profile;
  final bool isCurrentUser;
  final bool isConfiguredTherapist;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onConfigureTherapist;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primaryDark,
              child: Text(profile.primerNombre.characters.first.toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nombreVisible,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DropdownButton<UserRole>(
                  value: profile.rol,
                  underline: const SizedBox.shrink(),
                  onChanged: isCurrentUser
                      ? null
                      : (role) {
                          if (role != null) onRoleChanged(role);
                        },
                  items: [
                    for (final role in UserRole.values)
                      DropdownMenuItem(
                        value: role,
                        child: Text(role.label),
                      ),
                  ],
                ),
                if (profile.rol == UserRole.terapeuta && !isConfiguredTherapist)
                  TextButton(
                    onPressed: onConfigureTherapist,
                    child: const Text('Configurar ficha'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: Text('Todavía no hay perfiles registrados.')),
    );
  }
}
