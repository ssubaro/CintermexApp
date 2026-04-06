import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'purchase_screen.dart';
import '../../data/services/supabase_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isSaved = false;
  bool _isLoadingSave = false;
  final _supabaseService = SupabaseService();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _selectedDay = widget.event.startDate;
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
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: _isLoadingSave 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_isSaved ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                onPressed: _toggleSave,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported,
                          size: 100, color: Colors.white54),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppColors.darkGrey,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.event.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryRed),
                      ),
                      child: Text(
                        widget.event.category!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: _formatEventDate(widget.event),
                    subtitle:
                        'Horario: ${timeFormat.format(widget.event.startDate)} - ${timeFormat.format(widget.event.endDate)}',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    context,
                    icon: Icons.confirmation_number_outlined,
                    title: widget.event.isFree
                        ? 'Gratis'
                        : NumberFormat.simpleCurrency(locale: 'es_MX')
                            .format(widget.event.price),
                    subtitle:
                        widget.event.isFree ? 'Entrada libre' : 'Precio por boleto',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on_rounded,
                    title: widget.event.location,
                    subtitle: 'Cintermex, Monterrey',
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Sobre el evento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (widget.event.venue != null) ...[
                    const Text(
                      'Lugar del evento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRowSimple(Icons.meeting_room, widget.event.venue!.name),
                    if (widget.event.venue!.floor != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                        child: Text(
                          'Piso: ${widget.event.venue!.floor}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                  _buildDaySelector(),
                  const SizedBox(height: 16),
                  _buildAgendaList(),
                  const SizedBox(height: 40),
                  if (widget.event.isFree)
                    Container(
                      width: double.infinity,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primaryRed.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'ENTRADA LIBRE',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleProtectedAction(context, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PurchaseScreen(event: widget.event),
                            ),
                          );
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'ADQUIRIR BOLETOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = widget.event.getDaysList();
    if (days.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Días del evento',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = _selectedDay != null &&
                  day.year == _selectedDay!.year &&
                  day.month == _selectedDay!.month &&
                  day.day == _selectedDay!.day;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(DateFormat('EEE, d MMM', 'es').format(day).toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primaryRed,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDay = day;
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaList() {
    if (widget.event.schedules == null || widget.event.schedules!.isEmpty) {
      return const SizedBox.shrink();
    }

    final filteredSchedules = widget.event.schedules!.where((s) {
      if (_selectedDay == null) return true;
      return s.startTime.year == _selectedDay!.year &&
             s.startTime.month == _selectedDay!.month &&
             s.startTime.day == _selectedDay!.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Agenda del día',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (widget.event.getDaysList().length > 1 && _selectedDay != null)
              Text(
                DateFormat('d MMMM', 'es').format(_selectedDay!),
                style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredSchedules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'No hay actividades programadas para este día',
                style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSchedules.length,
            itemBuilder: (context, index) {
              final schedule = filteredSchedules[index];
              return _buildScheduleItem(schedule);
            },
          ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowSimple(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(EventSchedule item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('HH:mm').format(item.startTime),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? 'Sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                if (item.speaker != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Ponente: ${item.speaker}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                if (item.locationDetail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.locationDetail!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14),
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

  String _formatEventDate(Event event) {
    final start = event.startDate;
    final end = event.endDate;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return DateFormat("EEEE, d 'de' MMMM", 'es').format(start);
    }
    
    if (start.year == end.year && start.month == end.month) {
      final month = DateFormat('MMMM', 'es').format(start);
      return "Del ${start.day} al ${end.day} de $month";
    }
    
    final startStr = DateFormat("d 'de' MMM", 'es').format(start);
    final endStr = DateFormat("d 'de' MMM", 'es').format(end);
    return "Del $startStr al $endStr";
  }
}
