import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/status_dialog.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Category> _allCategories = [];
  List<String> _selectedCategoryIds = [];
  bool _savingInterests = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final results = await Future.wait([
        _supabaseService.getProfile(user.id),
        _supabaseService.getCategories(),
        _supabaseService.getUserInterests(user.id),
      ]);

      _profile = results[0] as Map<String, dynamic>?;
      _allCategories = results[1] as List<Category>;
      _selectedCategoryIds = results[2] as List<String>;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInterests() async {
    setState(() => _savingInterests = true);
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;
      await _supabaseService.updateUserInterests(user.id, _selectedCategoryIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intereses actualizados'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _savingInterests = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _supabaseService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Eliminar Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'Esta acción eliminará tu perfil y no podrás recuperar tu cuenta ni registrarte con el mismo correo. ¿Estás seguro?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            child: const Text('Sí, Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await _supabaseService.deleteAccount();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } catch (e) {
        await StatusDialog.show(
          context: context,
          title: 'Error',
          message: 'No se pudo eliminar la cuenta: $e',
          icon: Icons.error_outline,
          iconColor: AppColors.primaryRed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _profile?['display_name'] ?? _profile?['full_name'] ?? 'Usuario';
    final email = user?.email ?? '';
    final fullName = _profile?['full_name'] ?? '';
    final phone = _profile?['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar + Nombre
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primaryRed,
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tarjeta con datos
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _profileDataRow(Icons.person, 'Nombre', fullName.isNotEmpty ? fullName : 'No especificado'),
                        const Divider(color: Colors.white12, height: 24),
                        _profileDataRow(Icons.email, 'Correo', email),
                        if (phone.isNotEmpty) ...[
                          const Divider(color: Colors.white12, height: 24),
                          _profileDataRow(Icons.phone, 'Teléfono', phone),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón editar datos
                  _actionButton(
                    icon: Icons.edit_outlined,
                    label: 'Editar mis datos',
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            initialFullName: fullName,
                            initialDisplayName: _profile?['display_name'] ?? '',
                            initialPhone: phone,
                          ),
                        ),
                      );
                      if (updated == true) _loadProfileData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Cambiar intereses
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: const [
                              Icon(Icons.interests_outlined, color: AppColors.primaryRed),
                              SizedBox(width: 12),
                              Text('Mis Intereses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ]),
                            TextButton(
                              onPressed: _savingInterests ? null : _saveInterests,
                              child: _savingInterests
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Guardar', style: TextStyle(color: AppColors.primaryRed)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allCategories.map((cat) {
                            final isSelected = _selectedCategoryIds.contains(cat.id);
                            return FilterChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: AppColors.primaryRed.withOpacity(0.25),
                              checkmarkColor: AppColors.primaryRed,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) _selectedCategoryIds.add(cat.id);
                                  else _selectedCategoryIds.remove(cat.id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cerrar Sesión
                  _actionButton(
                    icon: Icons.logout,
                    label: 'Cerrar Sesión',
                    color: Colors.orange,
                    onTap: _confirmLogout,
                  ),
                  const SizedBox(height: 12),

                  // Eliminar cuenta
                  _actionButton(
                    icon: Icons.delete_forever_outlined,
                    label: 'Eliminar Cuenta',
                    color: Colors.red[300]!,
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _profileDataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white70),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 16, color: color ?? Colors.white70)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
