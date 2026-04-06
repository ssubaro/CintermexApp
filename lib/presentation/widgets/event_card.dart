import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../screens/event_detail_screen.dart';
import '../../core/app_theme.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 32),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  event.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                  ),
                ),
                if (event.category != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.category!,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (event.isFree)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GRATIS',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // Indicadores de Estado (Guardado / Ticket)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      if (event.isSaved)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.favorite, color: AppColors.primaryRed, size: 16),
                        ),
                      if (event.isTicket)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.confirmation_num, color: Colors.green, size: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryRed),
                      const SizedBox(width: 8),
                      Text(
                        _formatEventDate(event),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const Spacer(),
                      Icon(
                        event.requiresTicket ? Icons.confirmation_number_outlined : Icons.door_front_door_outlined,
                        size: 14,
                        color: event.requiresTicket ? Colors.blueAccent : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.requiresTicket ? 'Requiere boleto' : 'Entrada libre',
                        style: TextStyle(
                          color: event.requiresTicket ? Colors.blueAccent : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primaryRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(Event event) {
    final start = event.startDate;
    final end = event.endDate;
    
    // Si la fecha de fin es igual a la de inicio (mismo día)
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return DateFormat("d 'de' MMMM", 'es').format(start);
    }
    
    // Si es el mismo mes
    if (start.year == end.year && start.month == end.month) {
      final month = DateFormat('MMMM', 'es').format(start);
      return "${start.day} al ${end.day} de $month";
    }
    
    // Si son meses distintos
    final monthStart = DateFormat('MMM', 'es').format(start);
    final monthEnd = DateFormat('MMM', 'es').format(end);
    return "${start.day} de $monthStart al ${end.day} de $monthEnd";
  }
}
