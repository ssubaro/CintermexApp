import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/event_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedScreen extends StatefulWidget {
  final VoidCallback? onExplore;
  const SavedScreen({super.key, this.onExplore});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Event> _savedEvents = [];
  List<Event> _historyEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final allEvents = await _supabaseService.getMyEvents();
      final now = DateTime.now();

      final saved = allEvents.where((e) => e.startDate.isAfter(now) || e.startDate.isAtSameMomentAs(now)).toList();
      final history = allEvents.where((e) => e.startDate.isBefore(now)).toList();

      if (mounted) {
        setState(() {
          _savedEvents = saved;
          _historyEvents = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching saved events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              if (widget.onExplore != null) {
                widget.onExplore!();
              } else {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text("Explorar eventos", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events, String emptyMessage) {
    if (events.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventCard(event: events[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Guardados")),
        body: _buildEmptyState("Inicia sesión para ver tus eventos"),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tus Eventos", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Guardados"),
              Tab(text: "Historial"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _buildEventList(_savedEvents, "Aún no tienes eventos guardados"),
                  _buildEventList(_historyEvents, "No has asistido a eventos recientes"),
                ],
              ),
      ),
    );
  }
}
