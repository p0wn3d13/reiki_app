import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/error_banner.dart';
import 'widgets/auth_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_emailCtrl.text);
      if (!mounted) return;
      setState(() => _enviado = true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enviado) {
      return AuthShell(
        titulo: 'Correo enviado',
        mostrarVolver: true,
        children: [
          // Mensaje deliberadamente genérico: no confirmamos si el email
          // está registrado o no, para no dar pistas a quien vaya
          // probando direcciones ajenas.
          SuccessBanner(
            mensaje:
                'Si ${_emailCtrl.text.trim()} corresponde a una cuenta, '
                'recibirás un enlace para elegir una contraseña nueva. '
                'Revisa también la carpeta de spam.',
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
      titulo: 'Recuperar contraseña',
      subtitulo:
          'Escribe tu email y te enviamos un enlace para restablecerla.',
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
                controller: _emailCtrl,
                enabled: !_enviando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'tu@email.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: Validators.email,
                onFieldSubmitted: (_) => _enviar(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar enlace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
