import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/event_card.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isListView = true; // true = Lista, false = Calendario
  
  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    // Fetch all future events (assuming current month forwards)
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    
    // Simplification for the example: fetch all upcoming and current month
    // You could paginate this or adjust it in a real app
    _supabaseService.refreshEvents(startDate: start);
    _supabaseService.eventsStream.listen((events) {
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return (event.startDate.year == day.year &&
              event.startDate.month == day.month &&
              event.startDate.day == day.day) ||
             (day.isAfter(event.startDate) && day.isBefore(event.endDate.add(const Duration(days: 1))));
    }).toList();
  }

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Toggle Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isListView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isListView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Lista",
                          style: TextStyle(
                            color: _isListView ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isListView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isListView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Calendario",
                          style: TextStyle(
                            color: !_isListView ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _isListView ? _buildListView() : _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_events.isEmpty) {
      return const Center(child: Text("No hay eventos próximos", style: TextStyle(color: Colors.grey)));
    }

    // Sort events by date
    final sortedEvents = List<Event>.from(_events)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Group by month
    final Map<int, List<Event>> grouped = {};
    for (var event in sortedEvents) {
      int monthKey = event.startDate.year * 100 + event.startDate.month;
      grouped.putIfAbsent(monthKey, () => []).add(event);
    }

    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final monthEvents = grouped[key]!;
        final monthName = monthNames[key % 100];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                monthName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...monthEvents.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: EventCard(event: e),
            )),
          ],
        );
      },
    );
  }

  Widget _buildCalendarView() {
    final selectedDayEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Event>[];

    return Column(
      children: [
        TableCalendar<Event>(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; 
            });
          },
          eventLoader: _getEventsForDay,
          rowHeight: 64,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mes',
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(color: Colors.white),
            weekendTextStyle: const TextStyle(color: Colors.white70),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          headerStyle: const HeaderStyle(
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
            formatButtonVisible: false,
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.grey),
            weekendStyle: TextStyle(color: Colors.grey),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox();
              
              final firstEvent = events.first;
              final catColor = _getCategoryColor(firstEvent.categoryId);
              
              String title = firstEvent.title;
              if (title.length > 12) {
                title = '${title.substring(0, 10)}...';
              }
              
              return Positioned(
                bottom: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(color: catColor, fontSize: 7),
                      ),
                    ),
                    if (events.length > 1) ...[
                      const SizedBox(height: 1),
                      Text(
                        '+${events.length - 1} más',
                        style: const TextStyle(color: Colors.grey, fontSize: 7),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: selectedDayEvents.isEmpty
            ? const Center(child: Text("No hay eventos en este día", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: selectedDayEvents.length,
                itemBuilder: (context, index) {
                  return EventCard(event: selectedDayEvents[index]);
                },
              ),
        ),
      ],
    );
  }
}
