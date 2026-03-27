import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/status_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialFullName;
  final String? initialDisplayName;
  final String? initialPhone;

  const EditProfileScreen({
    super.key,
    this.initialFullName,
    this.initialDisplayName,
    this.initialPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName ?? '');
    _displayNameController = TextEditingController(text: widget.initialDisplayName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      // Actualizar datos de perfil
      await _supabaseService.updateProfile(
        userId: user.id,
        fullName: _fullNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // Cambiar contraseña solo si se llenó la sección
      if (_currentPasswordController.text.isNotEmpty) {
        await _supabaseService.updatePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
      }

      if (mounted) {
        await StatusDialog.show(
          context: context,
          title: '¡Datos Actualizados!',
          message: 'Tu información ha sido guardada correctamente.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
        Navigator.of(context).pop(true); // Retorna true para refrescar
      }
    } catch (e) {
      if (mounted) {
        await StatusDialog.show(
          context: context,
          title: 'Error',
          message: 'No se pudo actualizar: ${e.toString().replaceAll('Exception: ', '')}',
          icon: Icons.error_outline,
          iconColor: AppColors.primaryRed,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mis Datos'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección datos personales
              _sectionTitle('Información Personal'),
              const SizedBox(height: 16),
              _buildField(
                controller: _fullNameController,
                label: 'Nombre Completo',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _displayNameController,
                label: 'Nombre de Usuario',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Sección contraseña
              _sectionTitle('Cambiar Contraseña'),
              const SizedBox(height: 8),
              const Text(
                'Deja estos campos vacíos si no quieres cambiar tu contraseña.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Contraseña Actual',
                show: _showCurrentPassword,
                onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                validator: (val) {
                  if (_newPasswordController.text.isNotEmpty && (val == null || val.isEmpty)) {
                    return 'Ingresa tu contraseña actual para cambiarla';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nueva Contraseña',
                show: _showNewPassword,
                onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmar Nueva Contraseña',
                show: _showConfirmPassword,
                onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                validator: (val) {
                  if (_newPasswordController.text.isNotEmpty && val != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
