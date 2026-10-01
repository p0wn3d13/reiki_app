import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES');
  await initSupabase();

  // TODO(Fase 11): inicializar Firebase.initializeApp() y
  // NotificationService().init() aquí, una vez se añadan los ficheros
  // de configuración de Firebase (google-services.json / GoogleService-Info.plist).

  runApp(const ProviderScope(child: ReikiApp()));
}

class ReikiApp extends ConsumerWidget {
  const ReikiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Reiki Pablo Partido',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
