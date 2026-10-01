// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reiki_app/core/theme/app_theme.dart';
import 'package:reiki_app/features/auth/login_screen.dart';

void main() {
  testWidgets('la pantalla de login se monta y muestra el formulario principal',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
