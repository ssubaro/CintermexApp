import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/models/ticket_model.dart';
import '../../data/services/supabase_service.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Boletos"),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Ticket>>(
        future: supabaseService.getMyTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const Center(
              child: Text("No tienes boletos activos."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventTitle ?? "Evento Desconocido",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Fecha: ${ticket.eventDate?.toString().split(' ')[0] ?? 'N/A'}"),
                      Text("Ubicación: ${ticket.eventLocation ?? 'N/A'}"),
                      const Divider(),
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2, size: 100),
                            Text(
                              "ID: ${ticket.id.substring(0, 8)}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
