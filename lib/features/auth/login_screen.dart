import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/error_banner.dart';
import 'widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _enviando = false;
  bool _verPassword = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_enviando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Cerrar el teclado antes de la llamada: si no, el error aparece
    // tapado por él en un móvil.
    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      // No navegamos aquí: el guard de `appRouterProvider` reacciona al
      // cambio de sesión y lleva al inicio que corresponda al rol.
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      debugPrint('[LoginScreen] Error inesperado: $e');
      if (!mounted) return;
      setState(() => _error = 'Ha ocurrido un error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      titulo: 'Bienvenido',
      subtitulo: 'Entra para gestionar tus sesiones de Reiki.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                ErrorBanner(mensaje: _error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailCtrl,
                enabled: !_enviando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'tu@email.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                enabled: !_enviando,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    tooltip: _verPassword
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: () =>
                        setState(() => _verPassword = !_verPassword),
                  ),
                ),
                validator: Validators.passwordLogin,
                onFieldSubmitted: (_) => _entrar(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _enviando
                      ? null
                      : () => context.push(AppRoutes.forgotPassword),
                  child: const Text('¿Has olvidado la contraseña?'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _enviando ? null : _entrar,
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _enviando ? null : () async {
                  setState(() {
                    _enviando = true;
                    _error = null;
                  });
                  try {
                    await ref.read(authRepositoryProvider).signInWithGoogle();
                  } on AppException catch (e) {
                    if (!mounted) return;
                    setState(() => _error = e.message);
                  } finally {
                    if (mounted) setState(() => _enviando = false);
                  }
                },
                icon: const Icon(Icons.g_translate_rounded),
                label: const Text('Continuar con Google'),
              ),
              const SizedBox(height: 20),
              // Wrap y no Row: en un móvil estrecho, o con el tamaño de
              // letra del sistema aumentado, el texto y el botón no
              // caben en una línea y un Row desbordaría.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '¿Todavía no tienes cuenta?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: _enviando
                        ? null
                        : () => context.push(AppRoutes.register),
                    child: const Text('Regístrate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
