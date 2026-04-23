import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/models/ticket_model.dart';
import '../../data/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  // Mapa para controlar cuáles QR están visibles (por index)
  final Map<int, bool> _qrVisible = {};
  late Future<List<Ticket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _supabaseService.getMyTickets();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _ticketsFuture = _supabaseService.getMyTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Boletos"),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryRed,
        child: FutureBuilder<List<Ticket>>(
          future: _ticketsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryRed));
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                      child: Text("Error: ${snapshot.error}",
                          textAlign: TextAlign.center)),
                ],
              );
            }

            final tickets = snapshot.data ?? [];
            if (tickets.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.confirmation_number_outlined,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No tienes boletos activos.",
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text("Desliza hacia abajo para actualizar",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final isQrVisible = _qrVisible[index] ?? false;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Cabecera roja
                      Container(
                        color: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ticket.eventTitle ?? "Evento Desconocido",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Datos del ticket
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                                Icons.calendar_today,
                                "Fecha",
                                DateFormat('EEE, d MMM y', 'es').format(
                                    ticket.selectedDate ??
                                        ticket.eventDate ??
                                        DateTime.now())),
                            const SizedBox(height: 8),
                            _infoRow(Icons.location_on_outlined, "Ubicación",
                                ticket.eventLocation ?? 'N/A'),
                            const SizedBox(height: 8),
                            _infoRow(Icons.label_important_outline, "Tipo",
                                ticket.ticketTypeName ?? 'General'),
                            const SizedBox(height: 8),
                            _infoRow(Icons.people_outline, "Cantidad",
                                "${ticket.quantity} boleto(s)"),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(),
                            ),
                            // QR con efecto blur
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _qrVisible[index] = !isQrVisible;
                                });
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // QR base (siempre renderizado)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: QrImageView(
                                        data: ticket.id,
                                        version: QrVersions.auto,
                                        size: 180.0,
                                        gapless: false,
                                      ),
                                    ),
                                  ),
                                  // Capa de blur que desaparece al tocar
                                  if (!isQrVisible)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: 196,
                                          height: 196,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.lock_outline,
                                                  size: 36,
                                                  color: AppColors.primaryRed),
                                              SizedBox(height: 8),
                                              Text(
                                                "Toca para\nrevelar el QR",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColors.darkGrey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                "TICKET: ${ticket.ticketNumber ?? ticket.id.substring(0, 8).toUpperCase()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            if (isQrVisible)
                              const Center(
                                child: Text(
                                  "Toca para ocultar",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Text("$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
