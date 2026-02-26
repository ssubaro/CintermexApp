import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Event>> getEvents() async {
    final response = await _client
        .from('events')
        .select()
        .order('start_date', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Event>> getEventsByMonth(int month, int year) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final response = await _client
        .from('events')
        .select()
        .gte('start_date', startOfMonth.toIso8601String())
        .lte('start_date', endOfMonth.toIso8601String())
        .order('start_date', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Ticket>> getMyTickets() async {
    final userId = _client.auth.currentUser?.id;
    // Si no hay usuario, retornamos lista vacía o manejamos error
    if (userId == null) return [];

    // Hacemos join con events para traer los datos del evento asociado al ticket
    final response = await _client
        .from('tickets')
        .select('*, events(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Ticket.fromJson(json)).toList();
  }

  // Eventos donde el usuario tiene tickets
  Future<List<Event>> getMyEvents() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('tickets')
        .select('events(*)')
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    // Extraemos el objeto 'events' y lo convertimos, eliminando duplicados
    final events = data
        .map((json) => Event.fromJson(json['events']))
        .toSet()
        .toList();
    
    return events;
  }
}
