import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../models/category_model.dart';
import '../models/ticket_type_model.dart';
import '../models/order_model.dart';
import '../models/venue_model.dart';
import '../models/announcement_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Stream de eventos usando rxdart para reactividad con joins
  final BehaviorSubject<List<Event>> _eventsSubject =
      BehaviorSubject<List<Event>>();
  Stream<List<Event>> get eventsStream => _eventsSubject.stream;

  Future<void> refreshEvents({
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getEvents(
        categoryIds: categoryIds,
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

  /// Envía el email de recuperación de contraseña.
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Establece una nueva contraseña cuando el usuario ya tiene sesión activa
  /// (después de seguir el link del email de recuperación).
  Future<void> updatePasswordWithToken(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Crea un nuevo usuario mediante una Edge Function (solo para admins)
  /// Esto evita que el administrador pierda su sesión actual.
  Future<void> adminCreateUser({
    required String email,
    required String password,
    required String role,
    String? fullName,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('No hay sesión activa');

    final response = await _client.functions.invoke(
      'admin-create-user',
      body: {
        'email': email,
        'password': password,
        'role': role,
        'full_name': fullName,
      },
    );

    if (response.status != 200) {
      throw Exception(
          'Error al crear usuario: ${response.data['error'] ?? 'Desconocido'}');
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
    String? displayName,
    String? phone,
    List<String>? selectedCategoryIds,
  }) async {
    // Pasamos todos los datos como metadata para que el trigger de Supabase
    // los pueda leer automáticamente al confirmar el correo.
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': role,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    // También intentamos insertar el perfil directamente (por si el trigger no está activo
    // o si la confirmación de correo está desactivada).
    final user = response.user;
    if (user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'role': role,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (displayName != null && displayName.isNotEmpty)
            'display_name': displayName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        });

        // Insertar intereses si hay
        if (selectedCategoryIds != null && selectedCategoryIds.isNotEmpty) {
          final interestsData = selectedCategoryIds
              .map((categoryId) => {
                    'user_id': user.id,
                    'category_id': categoryId,
                  })
              .toList();
          await _client.from('user_interests').insert(interestsData);
        }
      } catch (e) {
        // El insert puede fallar si RLS bloquea la escritura antes de confirmación.
        // El trigger de Supabase lo compensará al confirmar el correo.
        print(
            'Note: Direct profile insert failed (expected if email confirm pending): $e');
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

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final response =
        await _client.from('profiles').select().order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _client.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? displayName,
    String? phone,
  }) async {
    await _client.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
    }).eq('id', userId);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) throw Exception('No hay sesión activa');

    // Re-autenticar para verificar contraseña actual
    await _client.auth
        .signInWithPassword(email: email, password: currentPassword);
    // Cambiar contraseña
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay sesión activa');

    // Borrar intereses
    await _client.from('user_interests').delete().eq('user_id', userId);
    // Borrar perfil (el usuario queda sin acceso)
    await _client.from('profiles').delete().eq('id', userId);
    // Cerrar sesión
    await _client.auth.signOut();
  }

  Future<List<String>> getUserInterests(String userId) async {
    final response = await _client
        .from('user_interests')
        .select('category_id')
        .eq('user_id', userId);
    final data = response;
    return data.map((item) => item['category_id'] as String).toList();
  }

  Future<void> updateUserInterests(
      String userId, List<String> categoryIds) async {
    // 1. Eliminar intereses actuales
    await _client.from('user_interests').delete().eq('user_id', userId);

    // 2. Insertar nuevos intereses
    if (categoryIds.isNotEmpty) {
      final interestsData = categoryIds
          .map((categoryId) => {
                'user_id': userId,
                'category_id': categoryId,
              })
          .toList();

      await _client.from('user_interests').insert(interestsData);
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return response;
  }

  // --- Events & Tickets ---

  Future<List<Event>> getEvents({
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String eventCategoriesSelect =
        (categoryIds != null && categoryIds.isNotEmpty)
            ? 'event_categories!inner(category_id, categories(*))'
            : 'event_categories(categories(*))';

    var query = _client.from('events').select('''
          *,
          venue_locations(*),
          event_schedules(*),
          $eventCategoriesSelect
        ''');

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query = query.inFilter('event_categories.category_id', categoryIds);
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
    // !inner filters the query results to only parent records that have a match in the related table
    final response = await _client
        .from('categories')
        .select('*, event_categories!inner(event_id)')
        .order('name');
    final data = response as List<dynamic>;

    // We unique them in Dart to be safe, as results for many-to-many
    // through junction tables can sometimes return duplicates if not handled.
    final categories = data.map((json) => Category.fromJson(json)).toList();
    final seen = <String>{};
    return categories.where((c) => seen.add(c.id)).toList();
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .eq('active', true)
          .order('created_at', ascending: false);
      final data = response as List<dynamic>;
      return data.map((json) => Announcement.fromJson(json)).toList();
    } catch (e) {
      print('Avisos no encontrados o tabla inexistente: $e');
      return []; // Return empty list gracefully
    }
  }

  Future<List<Event>> getForYouEvents() async {
    final userId = _client.auth.currentUser?.id;
    List<String> userCategories = [];

    if (userId != null) {
      userCategories = await getUserInterests(userId);
    }

    var query = _client.from('events').select('''
          *,
          venue_locations(*),
          event_schedules(*),
          event_categories!inner(category_id, categories(*))
        ''').gte('start_date', DateTime.now().toIso8601String());

    if (userCategories.isNotEmpty) {
      query = query.inFilter('event_categories.category_id', userCategories);
      final response =
          await query.order('start_date', ascending: true).limit(5);
      final data = response as List<dynamic>;
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      final response = await query.limit(20);
      final data = response as List<dynamic>;
      final events = data.map((json) => Event.fromJson(json)).toList();
      events.shuffle(); // Shuffle in dart for pseudo-random
      return events.take(5).toList();
    }
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
        .eq('payment_status', 'completed')
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Ticket.fromJson(json)).toList();
  }

  Future<int> getEventTicketCount(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('tickets')
        .select('quantity')
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('payment_status', 'completed');

    final data = response as List<dynamic>;
    int count = 0;
    for (var item in data) {
      count += (item['quantity'] as int? ?? 0);
    }
    return count;
  }

  // Eventos donde el usuario tiene tickets O los ha guardado
  Future<List<Event>> getMyEvents() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. Obtener eventos con tickets completados
    final ticketResponse = await _client
        .from('tickets')
        .select('events(*)')
        .eq('user_id', userId)
        .eq('payment_status', 'completed');

    // 2. Obtener eventos guardados
    final savedResponse = await _client
        .from('saved_events')
        .select('events(*)')
        .eq('user_id', userId);

    final List<dynamic> ticketData = ticketResponse as List<dynamic>;
    final List<dynamic> savedData = savedResponse as List<dynamic>;

    // Combinar y eliminar duplicados usando el ID del evento
    final Map<String, Event> allEvents = {};

    for (var item in ticketData) {
      if (item['events'] != null) {
        final event = Event.fromJson(item['events']);
        event.isTicket = true;
        allEvents[event.id] = event;
      }
    }

    for (var item in savedData) {
      if (item['events'] != null) {
        final eventId = item['events']['id'] as String;
        if (allEvents.containsKey(eventId)) {
          allEvents[eventId]!.isSaved = true;
        } else {
          final event = Event.fromJson(item['events']);
          event.isSaved = true;
          allEvents[event.id] = event;
        }
      }
    }

    return allEvents.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<bool> isEventSaved(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('saved_events')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .maybeSingle();

    return response != null;
  }

  Future<void> toggleSaveEvent(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Inicia sesión para guardar eventos');

    final isSaved = await isEventSaved(eventId);

    if (isSaved) {
      await _client
          .from('saved_events')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
    } else {
      await _client.from('saved_events').insert({
        'user_id': userId,
        'event_id': eventId,
      });
    }
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

  Future<String> createConektaCheckout({
    required String eventId,
    required String eventTitle,
    required double unitPrice,
    required int quantity,
    required String customerEmail,
    required String customerName,
    required String userId,
    required String selectedDate,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw Exception('Sesión expirada o no válida');

      final response = await _client.functions.invoke(
        'create-conekta-checkout',
        body: {
          'event_id': eventId,
          'event_title': eventTitle,
          'unit_price': unitPrice,
          'quantity': quantity,
          'customer_email': customerEmail,
          'customer_name': customerName,
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

  // --- Organizer & Admin Extension ---

  Future<List<Event>> getOrganizerEvents(String organizerId) async {
    final response = await _client
        .from('events')
        .select(
            '*, venue_locations(*), event_schedules(*), event_categories(categories(*))')
        .eq('organizer_id', organizerId)
        .order('start_date', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Event>> getPendingEvents() async {
    final response = await _client
        .from('events')
        .select(
            '*, venue_locations(*), event_schedules(*), event_categories(categories(*))')
        .eq('status', 'pending')
        .order('start_date', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Event.fromJson(json)).toList();
  }

  Future<void> updateEventStatus(String eventId, String status) async {
    await _client.from('events').update({'status': status}).eq('id', eventId);
  }

  Future<Event> saveEvent({
    required Map<String, dynamic> eventData,
    List<String>? categoryIds,
    List<Map<String, dynamic>>? schedules,
  }) async {
    final isNew = eventData['id'] == null;

    dynamic response;
    if (isNew) {
      response =
          await _client.from('events').insert(eventData).select().single();
    } else {
      response = await _client
          .from('events')
          .update(eventData)
          .eq('id', eventData['id'])
          .select()
          .single();
    }

    final eventId = response['id'] as String;

    // Handle categories
    if (categoryIds != null) {
      // Clear old categories if updating
      if (!isNew) {
        await _client.from('event_categories').delete().eq('event_id', eventId);
      }

      if (categoryIds.isNotEmpty) {
        final catData = categoryIds
            .map((catId) => {
                  'event_id': eventId,
                  'category_id': catId,
                })
            .toList();
        await _client.from('event_categories').insert(catData);
      }
    }

    // Handle schedules
    if (schedules != null) {
      // Clear old schedules if updating
      if (!isNew) {
        await _client.from('event_schedules').delete().eq('event_id', eventId);
      }

      if (schedules.isNotEmpty) {
        final schedData = schedules
            .map((s) => {
                  ...s,
                  'event_id': eventId,
                })
            .toList();
        await _client.from('event_schedules').insert(schedData);
      }
    }

    return Event.fromJson(response);
  }

  Future<void> deleteEvent(String eventId) async {
    // Delete dependencies first if RLS/OnDelete Cascade is not set
    await _client.from('event_categories').delete().eq('event_id', eventId);
    await _client.from('event_schedules').delete().eq('event_id', eventId);
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<List<VenueLocation>> getAllVenues() async {
    final response =
        await _client.from('venue_locations').select().order('name');
    final data = response as List<dynamic>;
    return data.map((json) => VenueLocation.fromJson(json)).toList();
  }
}
