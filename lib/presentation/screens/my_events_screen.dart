import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/event_card.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Eventos"),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Event>>(
        future: supabaseService.getMyEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text("Aún no tienes eventos guardados o tickets."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                title: event.title,
                date: "${event.startDate.day}/${event.startDate.month}/${event.startDate.year}",
                location: event.location,
                imageUrl: event.imageUrl,
              );
            },
          );
        },
      ),
    );
  }
}
