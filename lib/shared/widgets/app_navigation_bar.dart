import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_role.dart';
import '../../features/auth/auth_providers.dart';

class AppNavigationBar extends ConsumerWidget {
  const AppNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final path = GoRouterState.of(context).uri.path;

    final destinations = switch (role) {
      UserRole.admin => const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      UserRole.terapeuta => const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Horarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      _ => const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Reservar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
    };

    final routes = switch (role) {
      UserRole.admin => [AppRoutes.adminDashboard, AppRoutes.profile],
      UserRole.terapeuta => [
          AppRoutes.therapistDashboard,
          AppRoutes.therapistAvailability,
          AppRoutes.profile,
        ],
      _ => [AppRoutes.patientHome, AppRoutes.therapistsList, AppRoutes.profile],
    };

    var selectedIndex = routes.indexWhere((route) {
      return path == route || path.startsWith('$route/');
    });
    if (selectedIndex < 0) selectedIndex = 0;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index < routes.length && path != routes[index]) {
          context.go(routes[index]);
        }
      },
      destinations: destinations,
      backgroundColor: AppColors.surface,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 0,
    );
  }
}
