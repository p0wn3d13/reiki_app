import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/perfil.dart';
import '../../shared/widgets/app_navigation_bar.dart';
import '../auth/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _subirFoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);

    try {
      final fotoUrl = await ref.read(authRepositoryProvider).uploadProfilePhoto(file);
      await ref.read(authRepositoryProvider).updateProfile(
        nombre: _nameController.text,
        telefono: _phoneController.text,
        fotoUrl: fotoUrl,
      );
      ref.invalidate(currentPerfilProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _loadProfile(Perfil profile) {
    if (_loaded) return;
    _nameController.text = profile.nombre;
    _phoneController.text = profile.telefono ?? '';
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentPerfilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      bottomNavigationBar: const AppNavigationBar(),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudo cargar tu perfil: $error'),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No hay una sesión activa.'));
          }
          _loadProfile(profile);
          return _ProfileForm(
            profile: profile,
            formKey: _formKey,
            nameController: _nameController,
            phoneController: _phoneController,
            saving: _saving,
            uploadingPhoto: _uploadingPhoto,
            onSave: _save,
            onPickPhoto: _subirFoto,
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            nombre: _nameController.text,
            telefono: _phoneController.text,
          );
      ref.invalidate(currentPerfilProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.profile,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.saving,
    required this.uploadingPhoto,
    required this.onSave,
    required this.onPickPhoto,
  });

  final Perfil profile;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool saving;
  final bool uploadingPhoto;
  final VoidCallback onSave;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryDark,
                backgroundImage: profile.fotoUrl != null && profile.fotoUrl!.isNotEmpty
                    ? NetworkImage(profile.fotoUrl!)
                    : null,
                child: profile.fotoUrl == null || profile.fotoUrl!.isEmpty
                    ? Text(
                        profile.primerNombre.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  onPressed: uploadingPhoto ? null : onPickPhoto,
                  icon: uploadingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(profile.rol.label,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 28),
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre y apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Introduce tu nombre'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: profile.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
