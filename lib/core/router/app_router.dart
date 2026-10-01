import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/appointments/patient_home_screen.dart';
import '../../features/appointments/therapist_dashboard_screen.dart';
import '../../features/appointments/therapist_availability_screen.dart';
import '../../features/therapists/therapist_detail_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/booking/shared_booking_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../domain/models/user_role.dart';

/// Rutas con nombre, para poder navegar sin strings sueltas repetidas
/// por toda la app y para poder construir deep links desde una
/// notificación push (Fase 11) apuntando a una ruta concreta.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/registro';
  static const forgotPassword = '/recuperar-password';
  static const patientHome = '/patient';
  static const therapistDashboard = '/therapist';
  static const therapistAvailability = '/therapist/horarios';
  static const adminDashboard = '/admin';
  static const profile = '/perfil';
  static const therapistsList = '/therapists';
  static const therapistDetail = '/therapists/:id';
  static const booking = '/therapists/:id/booking';
}

Page<void> _menuTransitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.025, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

/// Rutas accesibles sin sesión. El splash no está aquí a propósito: es
/// la sala de espera de un usuario que **sí** tiene sesión pero cuyo
/// perfil todavía no se ha resuelto.
const _rutasPublicas = <String>{
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  // GoRouter necesita un Listenable para reevaluar `redirect`. Este
  // contador hace de puente: cada cambio en la sesión o en el perfil lo
  // incrementa y GoRouter vuelve a preguntar. Así el router se construye
  // una sola vez, en vez de recrearse (y perder el historial) en cada
  // evento de autenticación.
  final refresco = ValueNotifier<int>(0);
  ref.onDispose(refresco.dispose);

  ref.listen(isLoggedInProvider, (prev, next) {
    debugPrint('[Router] isLoggedIn cambió: $prev → $next');
    refresco.value++;
  });
  ref.listen(currentPerfilProvider, (prev, next) {
    debugPrint('[Router] currentPerfil cambió: $prev → $next');
    refresco.value++;
  });
  ref.listen(currentUserRoleProvider, (prev, next) {
    debugPrint('[Router] currentUserRole cambió: $prev → $next');
    refresco.value++;
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresco,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.patientHome,
        pageBuilder: (context, state) =>
            _menuTransitionPage(state, const PatientHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistDashboard,
        pageBuilder: (context, state) =>
            _menuTransitionPage(state, const TherapistDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistAvailability,
        pageBuilder: (context, state) =>
            _menuTransitionPage(state, const TherapistAvailabilityScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        pageBuilder: (context, state) =>
            _menuTransitionPage(state, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) =>
            _menuTransitionPage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistsList,
        name: 'therapists_list',
        pageBuilder: (context, state) =>
            _menuTransitionPage(state, const SharedBookingScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistDetail,
        name: 'therapist_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TherapistDetailScreen(terapeutaId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.booking,
        name: 'booking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingScreen(terapeutaId: id);
        },
      ),
    ],
    // Guard central de la app: decide sesión y rol en un único sitio,
    // para que ninguna pantalla tenga que comprobar permisos por su
    // cuenta.
    redirect: (context, state) {
      final destino = state.matchedLocation;
      final esPublica = _rutasPublicas.contains(destino);
      final loggedIn = ref.read(isLoggedInProvider);
      final rol = ref.read(currentUserRoleProvider);
      final perfilState = ref.read(currentPerfilProvider);

      debugPrint('[Router] redirect: destino=$destino, loggedIn=$loggedIn, '
          'rol=$rol, perfilState=$perfilState');

      if (!loggedIn) {
        final r = esPublica ? null : AppRoutes.login;
        debugPrint('[Router] → no loggedIn, redirigiendo a: $r');
        return r;
      }

      if (rol == null) {
        final r = destino == AppRoutes.splash ? null : AppRoutes.splash;
        debugPrint('[Router] → rol null, redirigiendo a: $r');
        return r;
      }

      final inicio = switch (rol) {
        UserRole.admin => AppRoutes.adminDashboard,
        UserRole.terapeuta => AppRoutes.therapistDashboard,
        UserRole.cliente => AppRoutes.patientHome,
      };

      if (esPublica || destino == AppRoutes.splash) {
        debugPrint('[Router] → redirigiendo a inicio: $inicio');
        return inicio;
      }

      final esDashboardTerapeuta = destino == AppRoutes.therapistDashboard ||
          destino.startsWith('${AppRoutes.therapistDashboard}/');
      final esDashboardAdmin = destino == AppRoutes.adminDashboard ||
          destino.startsWith('${AppRoutes.adminDashboard}/');
      final esInicioCliente = destino == AppRoutes.patientHome ||
          destino.startsWith('${AppRoutes.patientHome}/');

      if (esDashboardTerapeuta && !rol.isStaff) {
        debugPrint('[Router] → guard: no es staff, a patientHome');
        return AppRoutes.patientHome;
      }
      if (esDashboardTerapeuta && rol == UserRole.admin) {
        debugPrint('[Router] → guard: admin, a adminDashboard');
        return AppRoutes.adminDashboard;
      }
      if (esDashboardAdmin && rol != UserRole.admin) {
        debugPrint('[Router] → guard: no es admin, a inicio');
        return inicio;
      }
      if (esDashboardAdmin && rol == UserRole.admin) {
        return null;
      }
      if (esInicioCliente && rol.isStaff) {
        debugPrint('[Router] → guard: es staff, a therapistDashboard');
        return inicio;
      }

      debugPrint('[Router] → sin redirección (null)');
      return null;
    },
  );
});
