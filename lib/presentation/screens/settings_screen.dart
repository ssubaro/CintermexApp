import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Español';

  final String _appVersion = '1.0.0';
  final String _supportWhatsApp = 'https://wa.me/5218180000000'; // Cambia este número
  final String _supportEmail = 'soporte@cintermex.com'; // Cambia este correo

  final List<Map<String, dynamic>> _faq = [
    {
      'q': '¿Cómo compro un boleto?',
      'a': 'Selecciona el evento que te interesa, elige el tipo de boleto y completa el pago con tu tarjeta.',
    },
    {
      'q': '¿Dónde veo mis boletos comprados?',
      'a': 'En el menú lateral, selecciona "Mis Boletos" para ver todos tus tickets activos.',
    },
    {
      'q': '¿Puedo cancelar o reembolsar un boleto?',
      'a': 'Los reembolsos dependen de la política de cada evento. Contacta con soporte si necesitas ayuda.',
    },
    {
      'q': '¿Cómo cambio mi contraseña?',
      'a': 'Ve a "Mi Perfil" (ícono de arriba a la derecha) → "Editar mis datos" → sección de Cambiar Contraseña.',
    },
    {
      'q': '¿Mis datos están seguros?',
      'a': 'Sí. Tu información se almacena de forma segura utilizando los servicios de Supabase con encriptación estándar de la industria.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ─── Sección 1: Apariencia ───
          _sectionHeader(context, 'Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: AppColors.primaryRed, size: 22),
                      const SizedBox(width: 16),
                      Text('Tema de la App',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Oscuro
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isDark) context.read<ThemeProvider>().toggleTheme();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primaryRed
                                  : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.primaryRed
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.dark_mode,
                                  color: isDark ? Colors.white : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Oscuro',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Claro
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (isDark) context.read<ThemeProvider>().toggleTheme();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !isDark
                                  ? AppColors.primaryRed
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !isDark
                                    ? AppColors.primaryRed
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.light_mode,
                                  color: !isDark ? Colors.white : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Claro',
                                  style: TextStyle(
                                    color: !isDark ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _settingsTile(
            context: context,
            icon: Icons.language,
            title: 'Idioma',
            subtitle: _selectedLanguage,
            trailing: Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color),
            onTap: () => _showLanguagePicker(),
          ),

          const SizedBox(height: 8),
          // ─── Sección 2: Cuenta y Seguridad ───
          _sectionHeader(context, 'Cuenta y Seguridad'),
          _settingsTile(
            context: context,
            icon: Icons.devices_outlined,
            title: 'Administrar Sesiones',
            subtitle: 'Esta sesión está activa',
            trailing: Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color),
            onTap: () => _showSessionsInfo(),
          ),

          const SizedBox(height: 8),
          // ─── Sección 3: Ayuda y Soporte ───
          _sectionHeader(context, 'Ayuda y Soporte'),
          _settingsTile(
            context: context,
            icon: Icons.help_outline,
            title: 'Centro de Ayuda / FAQ',
            subtitle: '${_faq.length} preguntas frecuentes',
            trailing: Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color),
            onTap: () => _showFAQ(),
          ),
          _settingsTile(
            context: context,
            icon: Icons.chat_bubble_outline,
            title: 'Contacto con Soporte',
            subtitle: 'WhatsApp o correo electrónico',
            trailing: Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color),
            onTap: () => _showContactOptions(),
          ),

          const SizedBox(height: 8),
          // ─── Sección 4: Legal ───
          _sectionHeader(context, 'Legal'),
          _settingsTile(
            context: context,
            icon: Icons.article_outlined,
            title: 'Términos y Condiciones',
            trailing: Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color),
            onTap: () => _showTermsAndConditions(),
          ),

          // ─── Versión ───
          const SizedBox(height: 48),
          Text(
            'Cintermex App  v$_appVersion',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.textTheme.bodySmall?.color, fontSize: 13),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryRed,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Seleccionar Idioma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (final lang in ['Español', 'English'])
            ListTile(
              title: Text(lang),
              leading: Radio<String>(
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: AppColors.primaryRed,
                onChanged: (val) {
                  setState(() => _selectedLanguage = val!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La localización completa estará disponible próximamente')),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSessionsInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sesiones Activas', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.green),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Este dispositivo', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Sesión activa ahora', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Para mayor seguridad, cierra la sesión desde cualquier dispositivo que no reconozcas desde "Cerrar Sesión" en tu perfil.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFAQ() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Preguntas Frecuentes'),
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: _faq.map((item) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                iconColor: AppColors.primaryRed,
                title: Text(item['q'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(item['a'])],
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Contactar Soporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.chat, color: Colors.white)),
            title: const Text('WhatsApp'),
            subtitle: const Text('Respuesta en minutos'),
            onTap: () async {
              Navigator.pop(context);
              final uri = Uri.parse(_supportWhatsApp);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.primaryRed, child: const Icon(Icons.email, color: Colors.white)),
            title: const Text('Correo Electrónico'),
            subtitle: Text(_supportEmail),
            onTap: () async {
              Navigator.pop(context);
              final uri = Uri.parse('mailto:$_supportEmail?subject=Soporte Cintermex App');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Términos y Condiciones'),
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Términos y Condiciones de Uso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('Última actualización: Marzo 2026', style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 24),
                Text('1. Uso de la Aplicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Cintermex App es una plataforma destinada a la compra de boletos para eventos del Centro Internacional de Exposiciones de Monterrey. Al usarla, aceptas estos términos en su totalidad.'),
                SizedBox(height: 16),
                Text('2. Compras y Reembolsos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Todas las compras son finales a menos que el evento sea cancelado por el organizador. En caso de cancelación, el reembolso se procesará en un plazo de 5 a 10 días hábiles.'),
                SizedBox(height: 16),
                Text('3. Privacidad de Datos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Tu información personal se almacena de forma segura y no se comparte con terceros sin tu consentimiento explícito, salvo lo requerido por ley.'),
                SizedBox(height: 16),
                Text('4. Responsabilidad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Cintermex no se hace responsable por cancelaciones de eventos debidas a causas de fuerza mayor, condiciones climáticas extremas u otras circunstancias ajenas a su control.'),
                SizedBox(height: 32),
                Text('Para consultas legales, contacta a: legal@cintermex.com', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
