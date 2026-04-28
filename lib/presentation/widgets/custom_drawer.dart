import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../screens/login_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../widgets/estacionamiento_widget.dart';
import '../screens/mapa_cintermex_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _launchMaps() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=25.6782303,-100.2879791');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final url = Uri.parse('mailto:soporte@cintermex.com?subject=Soporte%20CintermexGO');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchSocial(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final hasSession = user != null;

    return Drawer(
      backgroundColor: const Color(0xFF161616),
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("C", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSession) ...[
                          Text(user.email?.split('@').first ?? 'Usuario', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(user.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ] else ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            },
                            child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white12, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // --- MI CUENTA ---
                  if (hasSession) ...[
                    _buildSectionTitle('MI CUENTA'),
                    _buildDrawerItem(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Mis boletos',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'Historial de eventos',
                      onTap: () {
                        Navigator.pop(context);
                        // Using DefaultTabController's index trick or just go to SavedScreen.
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedScreen()));
                      },
                    ),
                    const Divider(color: Colors.white12, height: 24),
                  ],

                  // --- VENUE ---
                  _buildSectionTitle('VENUE'),
                  _buildDrawerItem(
                    icon: Icons.map_outlined,
                    title: 'Mapa de Cintermex',
                    onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaCintermexScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.directions_outlined,
                    title: 'Cómo llegar',
                    onTap: () {
                      Navigator.pop(context);
                      _launchMaps();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.local_parking_outlined,
                    title: 'Estacionamiento',
                    onTap: () {
                       Navigator.pop(context);
                       EstacionamientoWidget.launchParco(context);
                    },
                  ),
                  const Divider(color: Colors.white12, height: 24),

                  // --- SOPORTE ---
                  _buildSectionTitle('SOPORTE'),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Preguntas Frecuentes',
                    onTap: () {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQs próximamente')));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bug_report_outlined,
                    title: 'Reportar problema',
                    onTap: () {
                      Navigator.pop(context);
                      _launchEmail();
                    },
                  ),
                  const Divider(color: Colors.white12, height: 24),

                  // --- REDES SOCIALES ---
                  _buildSectionTitle('SÍGUENOS'),
                  _buildDrawerItem(
                    icon: Icons.alternate_email,
                    title: 'X (Twitter)',
                    onTap: () => _launchSocial('https://x.com/cintermexmty'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.facebook,
                    title: 'Facebook',
                    onTap: () => _launchSocial('https://www.facebook.com/cintermex'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Instagram',
                    onTap: () => _launchSocial('https://www.instagram.com/cintermex/'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.play_circle_outline,
                    title: 'YouTube',
                    onTap: () => _launchSocial('https://www.youtube.com/user/CintermexMonterrey'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.music_note,
                    title: 'TikTok',
                    onTap: () => _launchSocial('https://www.tiktok.com/@Cintermex'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.work_outline,
                    title: 'LinkedIn',
                    onTap: () => _launchSocial('https://www.linkedin.com/company/cintermex/mycompany/?viewAsMember=true'),
                  ),
                  const Divider(color: Colors.white12, height: 24),

                  // --- APP ---
                  _buildSectionTitle('APP'),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'Acerca de Cintermex',
                    onTap: () {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Versión 1.0.0')));
                    },
                  ),
                  
                  if (hasSession) ...[
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Cerrar sesión',
                      color: const Color(0xFFE24B4A),
                      onTap: () async {
                        Navigator.pop(context);
                        _confirmLogout(context);
                      },
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que deseas salir?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
            }, 
            child: const Text('Salir', style: TextStyle(color: Color(0xFFE24B4A))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: onTap,
    );
  }
}
