import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reiki_app/core/theme/app_theme.dart';
import 'package:reiki_app/features/auth/login_screen.dart';

/// La pantalla se monta suelta, sin router y sin Supabase: la
/// validación del formulario ocurre antes de tocar el repositorio, así
/// que estos casos no necesitan backend.
Future<void> _montarLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pulsarEntrar(WidgetTester tester) async {
  final boton = find.widgetWithText(ElevatedButton, 'Entrar');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pump();
}

void main() {
  testWidgets('pinta el formulario de acceso', (tester) async {
    await _montarLogin(tester);

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);
    expect(find.text('¿Has olvidado la contraseña?'), findsOneWidget);
  });

  testWidgets('con los campos vacíos avisa y no llama a Supabase',
      (tester) async {
    await _montarLogin(tester);
    await _pulsarEntrar(tester);

    expect(find.text('Escribe tu email.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
  });

  testWidgets('rechaza un email mal escrito', (tester) async {
    await _montarLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'esto-no-es-un-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto123',
    );
    await _pulsarEntrar(tester);

    expect(find.text('Ese email no parece válido.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsNothing);
  });

  testWidgets('el ojo alterna la visibilidad de la contraseña',
      (tester) async {
    await _montarLogin(tester);

    Finder ojo() => find.byTooltip('Mostrar contraseña');
    expect(ojo(), findsOneWidget);

    await tester.tap(ojo());
    await tester.pump();

    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    expect(ojo(), findsNothing);
  });
}
