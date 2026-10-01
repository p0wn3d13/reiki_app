import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/error_banner.dart';
import 'widgets/auth_shell.dart';

/// Registro de clientes.
///
/// Solo crea cuentas con rol `cliente`; las cuentas de terapeuta las da
/// de alta la asociación desde Supabase (ver `AuthRepository.signUp`).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  bool _enviando = false;
  bool _verPassword = false;
  String? _error;

  /// Se activa cuando Supabase tiene la confirmación por email
  /// encendida: la cuenta existe pero no hay sesión todavía.
  bool _pendienteConfirmacion = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_enviando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final resultado = await ref.read(authRepositoryProvider).signUp(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            nombre: _nombreCtrl.text,
            telefono: _telefonoCtrl.text,
          );

      if (!mounted) return;

      // Con `sesionIniciada` no hacemos nada: el guard del router ve la
      // sesión nueva y lleva directamente al inicio del cliente.
      if (resultado == ResultadoRegistro.confirmacionPendiente) {
        setState(() => _pendienteConfirmacion = true);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendienteConfirmacion) {
      return AuthShell(
        titulo: 'Revisa tu correo',
        mostrarVolver: true,
        children: [
          SuccessBanner(
            mensaje: 'Te hemos enviado un email a ${_emailCtrl.text.trim()} '
                'con un enlace para confirmar tu cuenta. Después podrás '
                'iniciar sesión.',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      );
    }

    return AuthShell(
      titulo: 'Crear cuenta',
      subtitulo: 'Necesitamos unos datos para poder reservar tus sesiones.',
      mostrarVolver: true,
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
                controller: _nombreCtrl,
                enabled: !_enviando,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nombre y apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: Validators.nombre,
              ),
              const SizedBox(height: 16),
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
                controller: _telefonoCtrl,
                enabled: !_enviando,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: '600 00 00 00',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.telefonoOpcional,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                enabled: !_enviando,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  helperText:
                      'Mínimo ${Validators.minPasswordLength} caracteres.',
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
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password2Ctrl,
                enabled: !_enviando,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Repite la contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    Validators.passwordRepetida(v, _passwordCtrl.text),
                onFieldSubmitted: (_) => _registrar(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enviando ? null : _registrar,
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Crear cuenta'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _enviando
                    ? null
                    : () async {
                        setState(() {
                          _enviando = true;
                          _error = null;
                        });
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .signInWithGoogle();
                        } on AppException catch (e) {
                          if (!mounted) return;
                          setState(() => _error = e.message);
                        } finally {
                          if (mounted) setState(() => _enviando = false);
                        }
                      },
                icon: const Icon(Icons.g_translate_rounded),
                label: const Text('Registrarse con Google'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
