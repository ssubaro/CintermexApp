import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/event_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/services/supabase_service.dart';
import '../../core/app_theme.dart';
import 'login_screen.dart';
import 'purchase_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _supabaseService = SupabaseService();
  bool _isSaved = false;
  bool _isLoadingSave = false;
  DateTime? _selectedDay;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    final days = widget.event.getDaysList();
    if (days.isNotEmpty) {
      _selectedDay = days.first;
    }
  }

  Future<void> _checkIfSaved() async {
    final saved = await _supabaseService.isEventSaved(widget.event.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  void _handleProtectedAction(BuildContext context, VoidCallback action) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      action();
    }
  }

  Future<void> _toggleSave() async {
    _handleProtectedAction(context, () async {
      setState(() => _isLoadingSave = true);
      try {
        await _supabaseService.toggleSaveEvent(widget.event.id);
        setState(() {
          _isSaved = !_isSaved;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSaved ? 'Evento guardado' : 'Evento elminado de guardados'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingSave = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: _isLoadingSave
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_isSaved ? Icons.favorite : Icons.favorite_border,
                      color: _isSaved ? AppColors.primaryRed : Colors.white, size: 20),
            ),
            onPressed: _toggleSave,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                _buildInfoStrip(),
                const SizedBox(height: 24),
                _buildDescription(),
                const SizedBox(height: 32),
                _buildAgenda(),
                const SizedBox(height: 48), // Extra padding at bottom
              ],
            ),
          ),
          _buildFixedBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Hero(
      tag: 'event_image_${widget.event.id}',
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.network(
            widget.event.imageUrl,
            width: double.infinity,
            height: 380,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 380,
              color: Colors.grey[900],
              child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.white54)),
            ),
          ),
          Container(
            height: 380,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  const Color(0xFF111111),
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.event.category != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.event.category!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                Material(
                  type: MaterialType.transparency,
                  child: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.event.venue?.name ?? widget.event.location,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoCol(Icons.calendar_month, _formatDatesStrip()),
            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
            _buildInfoCol(Icons.access_time, _formatHoursStrip()),
            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
            _buildInfoCol(Icons.local_activity, _formatPriceStrip()),
          ],
        ),
      ),
    );
  }

  String _formatDatesStrip() {
    final start = widget.event.startDate;
    final end = widget.event.endDate;
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return DateFormat('d MMM', 'es').format(start);
    }
    return '${start.day} – ${DateFormat('d MMM', 'es').format(end)}';
  }

  String _formatHoursStrip() {
    return '${DateFormat('HH:mm').format(widget.event.startDate)} – ${DateFormat('HH:mm').format(widget.event.endDate)}';
  }

  String _formatPriceStrip() {
    if (widget.event.isFree) return 'Gratis';
    final format = NumberFormat.simpleCurrency(locale: 'es_MX');
    return 'Desde ${format.format(widget.event.price)}';
  }

  Widget _buildInfoCol(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 24),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (widget.event.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre el evento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final style = TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.white.withOpacity(0.55),
              );

              // Use TextPainter to determine if the text exceeds 3 lines
              final textPainter = TextPainter(
                text: TextSpan(text: widget.event.description, style: style),
                maxLines: 3,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final isOverflowing = textPainter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.event.description,
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  if (isOverflowing) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? 'Ver menos' : 'Ver más',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgenda() {
    final days = widget.event.getDaysList();
    if (days.isEmpty || widget.event.schedules == null || widget.event.schedules!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Agenda por día',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (days.length > 1)
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = _selectedDay != null &&
                    day.year == _selectedDay!.year &&
                    day.month == _selectedDay!.month &&
                    day.day == _selectedDay!.day;
                
                final df = DateFormat('E d MMM', 'es').format(day);
                final formatted = '${df.substring(0, 1).toUpperCase()}${df.substring(1)}';

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryRed : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryRed : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        formatted,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        _buildTimeline(),
      ],
    );
  }

  Widget _buildTimeline() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final filtered = widget.event.schedules!.where((s) {
      return s.startTime.year == _selectedDay!.year &&
             s.startTime.month == _selectedDay!.month &&
             s.startTime.day == _selectedDay!.day;
    }).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          'No hay actividades programadas para este día.',
          style: TextStyle(color: Colors.white.withOpacity(0.55)),
        ),
      );
    }

    // Grouping by time
    final Map<String, List<EventSchedule>> grouped = {};
    for (var s in filtered) {
      final timeStr = DateFormat('HH:mm').format(s.startTime);
      if (!grouped.containsKey(timeStr)) grouped[timeStr] = [];
      grouped[timeStr]!.add(s);
    }

    final sortedTimes = grouped.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: List.generate(sortedTimes.length, (index) {
          final timeStr = sortedTimes[index];
          final schedulesForTime = grouped[timeStr]!;
          final isLast = index == sortedTimes.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline left column
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF111111), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.5),
                              blurRadius: 4,
                            )
                          ]
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      if (isLast)
                        const SizedBox(height: 24), // Add some padding if it's the last element
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Timeline right column (events)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0), // Space between groups
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: schedulesForTime.map((s) => _buildScheduleCard(s)).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleCard(EventSchedule s) {
    return Container(
      width: 240, // Fixed width so they pack nicely in horizontal row
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.title ?? 'Sin título',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (s.locationDetail != null && s.locationDetail!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.55)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.locationDetail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (s.speaker != null && s.speaker!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 12, color: AppColors.primaryRed),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      s.speaker!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildFixedBottomButton() {
    final label = widget.event.isFree 
        ? 'Adquirir boletos · Gratis' 
        : 'Adquirir boletos · desde ${NumberFormat.simpleCurrency(locale: 'es_MX').format(widget.event.price)}';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24).copyWith(bottom: 24 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF111111).withOpacity(0.0),
              const Color(0xFF111111).withOpacity(0.8),
              const Color(0xFF111111),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: ElevatedButton(
          onPressed: () => _handleProtectedAction(context, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PurchaseScreen(event: widget.event),
              ),
            );
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            elevation: 8,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
