import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../data/services/supabase_service.dart';
import '../screens/my_events_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../screens/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  void _requireAuth(BuildContext context, Widget protectedScreen) {
    final user = Supabase.instance.client.auth.currentUser;
    Navigator.pop(context); // Cerrar drawer
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => protectedScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? "Inicia sesión para ver tus eventos";
    final supabaseService = SupabaseService();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryRed),
            accountName: Text(user != null ? "Usuario" : "Invitado"),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AppColors.primaryRed),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Mis Eventos'),
            onTap: () => _requireAuth(context, const MyEventsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Mis Boletos'),
            onTap: () => _requireAuth(context, const MyTicketsScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar a configuración
            },
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await supabaseService.signOut();
                // Opcional: recargar vista o mostrar mensaje
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión cerrada')),
                  );
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Iniciar Sesión'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}
