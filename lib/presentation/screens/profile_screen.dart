import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/services/supabase_service.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'my_tickets_screen.dart';
import 'reset_password_screen.dart';
import 'login_screen.dart';
import '../../core/app_theme.dart';

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
  bool _notificationsEnabled = true;
  final String _selectedLanguage = 'Español';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _supabaseService.getProfile(user.id),
        _supabaseService.getCategories(),
        _supabaseService.getUserInterests(user.id),
      ]);

      _profile = results[0] as Map<String, dynamic>?;
      _allCategories = results[1] as List<Category>;
      _selectedCategoryIds = results[2] as List<String>;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInterests() async {
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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 100, color: Colors.white24),
                const SizedBox(height: 24),
                const Text(
                  "Tu Perfil",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Inicia sesión para gestionar tus boletos, guardar eventos y personalizar tus intereses.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: const Text(
                    "INICIAR SESIÓN",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate directly to registration form
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isRegister: true, initialRole: 'cliente')));
                  },
                  child: const Text(
                    "¿No tienes cuenta? Regístrate",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayName = _profile?['display_name'] ?? _profile?['full_name'] ?? 'Usuario';
    final email = user.email ?? '';
    final fullName = _profile?['full_name'] ?? '';
    final phone = _profile?['phone'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // --- Header ---
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                          label: const Text('Editar perfil', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Mis Boletos ---
                  const Text('MIS BOLETOS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  _buildSectionContainer(
                    child: ListTile(
                      leading: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      title: const Text('Boletos Comprados', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Preferencias ---
                  const Text('PREFERENCIAS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  _buildSectionContainer(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Notificaciones Push', style: TextStyle(color: Colors.white)),
                          activeThumbColor: AppColors.primary,
                          value: _notificationsEnabled,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        ListTile(
                          title: const Text('Idioma', style: TextStyle(color: Colors.white)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedLanguage, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.white54),
                            ],
                          ),
                          onTap: () {},
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        ExpansionTile(
                          title: const Text('Categorías de interés', style: TextStyle(color: Colors.white)),
                          iconColor: AppColors.primary,
                          collapsedIconColor: Colors.white54,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _allCategories.map((category) {
                                  final isSelected = _selectedCategoryIds.contains(category.id);
                                  return FilterChip(
                                    label: Text(category.name),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary.withOpacity(0.3),
                                    checkmarkColor: AppColors.primary,
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.white30),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCategoryIds.add(category.id);
                                        } else {
                                          _selectedCategoryIds.remove(category.id);
                                        }
                                      });
                                      _saveInterests();
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Cuenta ---
                  const Text('CUENTA', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  _buildSectionContainer(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline, color: Colors.white),
                          title: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                             // Assuming standard change password flow
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
                          },
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: AppColors.primary),
                          title: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          onTap: _confirmLogout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}
