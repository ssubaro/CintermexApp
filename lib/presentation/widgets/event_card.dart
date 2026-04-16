import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../screens/event_detail_screen.dart';
import '../../core/app_colors.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({
    super.key,
    required this.event,
  });

  Color _getCategoryColor(String? categoryId) {
    if (categoryId == null) return AppColors.categoryDefault;
    final int hash = categoryId.hashCode;
    final colors = [
      AppColors.categoryAnime,
      AppColors.categoryFood,
      AppColors.categoryTech,
      AppColors.categoryArt,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    Color tagColor;
    Color tagBgColor;
    String tagText;

    if (event.requiresTicket) {
      if (event.startDate.isAfter(DateTime.now().add(const Duration(days: 30)))) {
        tagColor = const Color(0xFFEF9F27);
        tagBgColor = const Color(0xFFEF9F27).withOpacity(0.15);
        tagText = 'Próximamente';
      } else {
        tagColor = const Color(0xFFE24B4A);
        tagBgColor = const Color(0xFFE24B4A).withOpacity(0.15);
        tagText = 'Requiere boleto';
      }
    } else {
      tagColor = const Color(0xFF1D9E75);
      tagBgColor = const Color(0xFF1D9E75).withOpacity(0.15);
      tagText = 'Entrada libre';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      event.imageUrl,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 104,
                        height: 104,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(event.categoryId),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_formatShortDate(event)} ${event.location.isNotEmpty ? '• ${event.location}' : ''}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tagText,
                              style: TextStyle(
                                color: tagColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShortDate(Event event) {
    final start = event.startDate;
    final end = event.endDate;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return DateFormat("d MMM", 'es').format(start);
    }
    
    return "${DateFormat("d", 'es').format(start)}-${DateFormat("d MMM", 'es').format(end)}";
  }
}
