import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../screens/my_events_screen.dart';
import '../screens/my_tickets_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.primaryRed),
            accountName: Text("Invitado"),
            accountEmail: Text("Inicia sesión para ver tus eventos"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AppColors.primaryRed),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Mis Eventos'),
            onTap: () {
              Navigator.pop(context); // Cerrar drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyEventsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Mis Boletos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTicketsScreen()),
              );
            },
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
        ],
      ),
    );
  }
}
