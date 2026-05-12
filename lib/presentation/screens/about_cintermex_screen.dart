import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';

class AboutCintermexScreen extends StatelessWidget {
  const AboutCintermexScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Acerca de Cintermex'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "C", 
                  style: TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cintermex',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.bodyLarge?.color
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color, 
                fontSize: 16
              ),
            ),
            const SizedBox(height: 40),
            
            // --- Sitio Web ---
            Text(
              'SITIO WEB',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color, 
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkCard(
              context: context,
              icon: Icons.language,
              title: 'cintermex.com',
              onTap: () => _launchUrl('https://cintermex.com/'),
            ),
            const SizedBox(height: 32),

            // --- Redes Sociales ---
            Text(
              'SÍGUENOS',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color, 
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkCard(
              context: context,
              icon: Icons.alternate_email,
              title: 'X (Twitter)',
              onTap: () => _launchUrl('https://x.com/cintermexmty'),
            ),
            _buildLinkCard(
              context: context,
              icon: Icons.facebook,
              title: 'Facebook',
              onTap: () => _launchUrl('https://www.facebook.com/cintermex'),
            ),
            _buildLinkCard(
              context: context,
              icon: Icons.camera_alt_outlined,
              title: 'Instagram',
              onTap: () => _launchUrl('https://www.instagram.com/cintermex/'),
            ),
            _buildLinkCard(
              context: context,
              icon: Icons.play_circle_outline,
              title: 'YouTube',
              onTap: () => _launchUrl('https://www.youtube.com/user/CintermexMonterrey'),
            ),
            _buildLinkCard(
              context: context,
              icon: Icons.music_note,
              title: 'TikTok',
              onTap: () => _launchUrl('https://www.tiktok.com/@Cintermex'),
            ),
            _buildLinkCard(
              context: context,
              icon: Icons.work_outline,
              title: 'LinkedIn',
              onTap: () => _launchUrl('https://www.linkedin.com/company/cintermex/mycompany/?viewAsMember=true'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard({
    required BuildContext context, 
    required IconData icon, 
    required String title, 
    required VoidCallback onTap
  }) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryRed),
        title: Text(
          title, 
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)
        ),
        trailing: Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
        onTap: onTap,
      ),
    );
  }
}
