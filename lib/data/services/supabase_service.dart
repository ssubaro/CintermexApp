import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../models/category_model.dart';
import '../models/ticket_type_model.dart';
import '../models/order_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Stream de eventos usando rxdart para reactividad con joins
  final BehaviorSubject<List<Event>> _eventsSubject =
      BehaviorSubject<List<Event>>();
  Stream<List<Event>> get eventsStream => _eventsSubject.stream;

  Future<void> refreshEvents({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getEvents(
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );
      _eventsSubject.add(events);
    } catch (e) {
      print('Error al refrescar eventos: $e');
      _eventsSubject.addError(e);
    }
  }

  void dispose() {
    _eventsSubject.close();
  }

  // --- Authentication ---

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(
      String email, String password, String role) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    // Si el registro es exitoso y tenemos un usuario, insertamos su perfil con el rol
    final user = response.user;
    if (user != null) {
      try {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': email,
          'role': role,
        });
      } catch (e) {
        // En un caso real, querrías manejar este error (ej: borrar el auth.user si el perfil falla)
        print('Error creating profile: $e');
      }
    }

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return response['role'] as String?;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  // --- Events & Tickets ---

  Future<List<Event>> getEvents({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String eventCategoriesSelect = categoryId != null
        ? 'event_categories!inner(category_id, categories(*))'
        : 'event_categories(categories(*))';

    var query = _client.from('events').select('''
          *,
          venue_locations(*),
          event_schedules(*),
          $eventCategoriesSelect
        ''');

    if (categoryId != null) {
      query = query.eq('event_categories.category_id', categoryId);
    }

    if (startDate != null) {
      query = query.gte('start_date', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('start_date', endDate.toIso8601String());
    }

    final response = await query.order('start_date', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.from('categories').select().order('name');
    final data = response as List<dynamic>;
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<List<TicketType>> getTicketTypes(String eventId) async {
    final response = await _client
        .from('ticket_types')
        .select()
        .eq('event_id', eventId)
        .eq('is_active', true)
        .order('price');
    final data = response as List<dynamic>;
    return data.map((json) => TicketType.fromJson(json)).toList();
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

    final response =
        await _client.from('tickets').select('events(*)').eq('user_id', userId);

    final data = response as List<dynamic>;
    // Extraemos el objeto 'events' y lo convertimos, eliminando duplicados
    final events =
        data.map((json) => Event.fromJson(json['events'])).toSet().toList();

    return events;
  }

  Future<Order> createOrder({
    required String eventId,
    String? ticketTypeId,
    String? scheduleId,
    required int quantity,
    required double unitPrice,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User must be logged in');

    final subtotal = unitPrice * quantity;
    final total = subtotal; // Aquí podrías sumar service_fee si existiera

    final response = await _client
        .from('orders')
        .insert({
          'user_id': userId,
          'event_id': eventId,
          'ticket_type_id': ticketTypeId,
          'schedule_id': scheduleId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'subtotal': subtotal,
          'total': total,
          'status': 'pending',
        })
        .select()
        .single();

    return Order.fromJson(response);
  }

  Future<Ticket> purchaseTicket({
    required String eventId,
    required int quantity,
    required double pricePaid,
    String? orderId,
    String? scheduleId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null)
      throw Exception('User must be logged in to purchase tickets');

    final response = await _client
        .from('tickets')
        .insert({
          'user_id': userId,
          'event_id': eventId,
          'quantity': quantity,
          'price_paid': pricePaid,
          'status': 'active',
          'payment_status': 'completed',
          'order_id': orderId,
          'schedule_id': scheduleId,
          'ticket_number': 'TICK-${DateTime.now().millisecondsSinceEpoch}',
        })
        .select('*, events(*)')
        .single();

    return Ticket.fromJson(response);
  }

  Future<String> createConektaCheckout({
    required String eventId,
    required String eventTitle,
    required double unitPrice,
    required int quantity,
    required String customerEmail,
    required String userId,
    required String selectedDate,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw Exception('Sesión expirada o no válida');

      final response = await _client.functions.invoke(
        'create-conekta-checkout',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: {
          'event_id': eventId,
          'event_title': eventTitle,
          'unit_price': unitPrice,
          'quantity': quantity,
          'customer_email': customerEmail,
          'user_id': userId,
          'selected_date': selectedDate,
        },
      );

      if (response.status != 200) {
        throw Exception('Error en la función: ${response.data}');
      }

      return response.data['url'] as String;
    } on FunctionException catch (fe) {
      print('Error de Supabase Function: ${fe.status} - ${fe.details}');
      rethrow;
    } catch (e) {
      print('Error en createConektaCheckout: $e');
      rethrow;
    }
  }
}
