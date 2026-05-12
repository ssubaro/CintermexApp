import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/services/supabase_service.dart';
import 'login_screen.dart';
import '../../data/models/event_model.dart';
import '../widgets/event_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _profiles = [];
  List<Event> _pendingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadProfiles(),
      _loadPendingEvents(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPendingEvents() async {
    try {
      final events = await _supabaseService.getPendingEvents();
      setState(() {
        _pendingEvents = events;
      });
    } catch (e) {
      debugPrint('Error loading pending events: $e');
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _supabaseService.getAllProfiles();
      setState(() {
        _profiles = profiles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando usuarios: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.primaryRed),
        );
      }
    }
  }

  Future<void> _changeRole(String userId, String currentRole) async {
    final newRole = currentRole == 'cliente' ? 'organizador' : 'cliente';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambio de rol'),
        content: Text('¿Cambiar rol a "$newRole"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateUserRole(userId, newRole);
      await _loadProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado con éxito'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error actualizando rol: $e'), backgroundColor: AppColors.primaryRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEventsList() {
    if (_pendingEvents.isEmpty) {
      return const Center(child: Text('No hay eventos pendientes de aprobación', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) {
        final event = _pendingEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              EventCard(event: event),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _moderateEvent(event.id, 'rejected'),
                      child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _moderateEvent(event.id, 'active'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _moderateEvent(String eventId, String status) async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateEventStatus(eventId, status);
      await _loadPendingEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'active' ? 'Evento aprobado' : 'Evento rechazado'),
          backgroundColor: status == 'active' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.event_note), text: 'Aprobaciones'),
            ],
            indicatorColor: AppColors.primaryRed,
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: Colors.grey,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Recargar',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _supabaseService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : TabBarView(
              children: [
                _profiles.isEmpty
                    ? const Center(child: Text('No hay perfiles disponibles', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _profiles.length,
                        separatorBuilder: (ctx, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          final role = profile['role'] ?? 'cliente';
                          final isSelf = _supabaseService.currentUser?.id == profile['id'];
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: role == 'admin' ? Colors.black : (role == 'organizador' ? Colors.blue : Colors.grey),
                              child: Icon(
                                role == 'admin' ? Icons.security : (role == 'organizador' ? Icons.business : Icons.person), 
                                color: Colors.white
                              ),
                            ),
                            title: Text(profile['email'] ?? 'Sin correo', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Rol: ${role.toUpperCase()}'),
                            trailing: isSelf || role == 'admin'
                              ? const Chip(label: Text('Admin'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              : IconButton(
                                  icon: const Icon(Icons.edit_document, color: AppColors.primaryRed),
                                  onPressed: () => _changeRole(profile['id'], role),
                                  tooltip: 'Cambiar Rol',
                                ),
                          );
                        },
                      ),
                _buildEventsList(),
              ],
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddUserDialog,
          backgroundColor: AppColors.primaryRed,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'organizador';
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 car.)', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 24),
                const Text('Asignar Rol:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'organizador', child: Text('Organizador')),
                    DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
              onPressed: isSaving ? null : () async {
                if (emailController.text.isEmpty || passwordController.text.length < 8) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres')));
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  await _supabaseService.adminCreateUser(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    role: selectedRole,
                    fullName: nameController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado con éxito'), backgroundColor: Colors.green));
                    _loadProfiles();
                  }
                } catch (e) {
                  if (mounted) {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primaryRed));
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Crear Usuario', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
