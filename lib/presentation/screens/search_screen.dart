import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/event_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEvents = List.from(_allEvents);
      } else {
        _filteredEvents = _allEvents.where((event) {
          return event.title.toLowerCase().contains(query) ||
              event.location.toLowerCase().contains(query) ||
              (event.category?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _supabaseService.getAllActiveEvents();
      if (mounted) {
        setState(() {
          _allEvents = events;
          _filteredEvents = List.from(events);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching events for search: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildResultsInfo(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const Text(
            'Buscar',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54),
              onPressed: _fetchEvents,
              tooltip: 'Recargar',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focusNode.hasFocus
                ? AppColors.primary.withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
            width: 1.5,
          ),
          boxShadow: _focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Buscar eventos, lugares, categorías...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _focusNode.hasFocus
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.4),
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white54),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _focusNode.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onTap: () => setState(() {}),
          onEditingComplete: () {
            _focusNode.unfocus();
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    if (_isLoading) return const SizedBox.shrink();

    String infoText;
    if (_searchQuery.isEmpty) {
      infoText = '${_allEvents.length} eventos · Ordenados A-Z';
    } else {
      infoText =
          '${_filteredEvents.length} resultado${_filteredEvents.length != 1 ? 's' : ''} para "$_searchQuery"';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.sort_by_alpha : Icons.filter_list,
            size: 14,
            color: Colors.white.withOpacity(0.35),
          ),
          const SizedBox(width: 6),
          Text(
            infoText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.35),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    // Group by first letter for alphabetical sections
    if (_searchQuery.isEmpty) {
      return _buildAlphabeticalList();
    }

    // Filtered results: simple list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        return EventCard(event: _filteredEvents[index]);
      },
    );
  }

  Widget _buildAlphabeticalList() {
    // Group events by first letter
    final Map<String, List<Event>> grouped = {};
    for (var event in _filteredEvents) {
      final letter = event.title.isNotEmpty
          ? event.title[0].toUpperCase()
          : '#';
      final key = RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(letter) ? letter : '#';
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final letter = sortedKeys[index];
        final events = grouped[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letter header
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${events.length} evento${events.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ],
              ),
            ),
            // Event cards
            ...events.map((event) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EventCard(event: event),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty
                  ? Icons.event_busy
                  : Icons.search_off_rounded,
              size: 40,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? 'No hay eventos disponibles'
                : 'Sin resultados',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Vuelve más tarde para descubrir nuevos eventos'
                : 'Intenta con otro término de búsqueda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _focusNode.unfocus();
              },
              child: const Text(
                'Limpiar búsqueda',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
