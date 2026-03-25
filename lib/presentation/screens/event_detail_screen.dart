import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'purchase_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  void _handleProtectedAction(BuildContext context, VoidCallback action) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with transparent AppBar and Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported,
                          size: 100, color: Colors.white54),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppColors.darkGrey,
          ),

          // Event Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag if available
                  if (event.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryRed),
                      ),
                      child: Text(
                        event.category!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Event Info Row (Date & Time)
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: dateFormat.format(event.startDate),
                    subtitle:
                        'De ${timeFormat.format(event.startDate)} a ${timeFormat.format(event.endDate)}',
                  ),
                  const SizedBox(height: 20),

                  // Price Row
                  _buildInfoRow(
                    context,
                    icon: Icons.confirmation_number_outlined,
                    title: NumberFormat.simpleCurrency(locale: 'es_MX')
                        .format(event.price),
                    subtitle: 'Precio por boleto',
                  ),
                  const SizedBox(height: 20),

                  // Location Row
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on_rounded,
                    title: event.location,
                    subtitle: 'Cintermex, Monterrey',
                  ),
                  const SizedBox(height: 32),

                  // Description Section
                  const Text(
                    'Sobre el evento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Venue Section
                  if (event.venue != null) ...[
                    const Text(
                      'Lugar del evento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRowSimple(
                        Icons.meeting_room, event.venue!.name),
                    if (event.venue!.floor != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                        child: Text(
                          'Piso: ${event.venue!.floor}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],

                  // Schedule Section
                  if (event.schedules != null && event.schedules!.isNotEmpty) ...[
                    const Text(
                      'Agenda del evento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: event.schedules!.length,
                      itemBuilder: (context, index) {
                        final schedule = event.schedules![index];
                        return _buildScheduleItem(schedule);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],

                  // Tickets Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleProtectedAction(context, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PurchaseScreen(event: event),
                          ),
                        );
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'ADQUIRIR BOLETOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowSimple(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(EventSchedule item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('HH:mm').format(item.startTime),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? 'Sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                if (item.speaker != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Ponente: ${item.speaker}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                if (item.locationDetail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.locationDetail!,
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
