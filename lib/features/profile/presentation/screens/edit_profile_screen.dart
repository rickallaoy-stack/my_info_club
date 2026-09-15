import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  File? _pickedAvatar;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);

    try {
      if (_pickedAvatar != null) {
        final ext = _pickedAvatar!.path.split('.').last;
        await repo.uploadAvatar(await _pickedAvatar!.readAsBytes(), ext);
      }
      await repo.updateProfile(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );
      ref.invalidate(userProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Pré-remplissage une seule fois, quand le profil arrive.
    if (!_initialized && profileAsync.hasValue) {
      _nameController.text = profileAsync.value!.fullName;
      _bioController.text = profileAsync.value!.bio ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Erreur : $err')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: _pickedAvatar != null
                          ? FileImage(_pickedAvatar!)
                          : (profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : null) as ImageProvider?,
                      child: _pickedAvatar == null && profile.avatarUrl == null
                          ? Icon(AppIcons.profile,
                              size: 44, color: colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio (optionnel)'),
            ),
          ],
        ),
      ),
    );
  }
}
