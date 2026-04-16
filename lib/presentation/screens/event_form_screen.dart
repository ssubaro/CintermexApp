import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/venue_model.dart';
import '../../data/services/supabase_service.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;
  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7, hours: 2));
  
  List<Category> _allCategories = [];
  List<String> _selectedCategoryIds = [];
  List<VenueLocation> _allVenues = [];
  String? _selectedVenueId;
  
  List<Map<String, dynamic>> _schedules = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _imageUrlController = TextEditingController(text: widget.event?.imageUrl ?? '');
    _priceController = TextEditingController(text: widget.event?.price.toString() ?? '0');
    _capacityController = TextEditingController(text: widget.event?.capacity.toString() ?? '100');
    
    if (widget.event != null) {
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _selectedCategoryIds = widget.event!.categoriesList?.map((c) => c.id).toList() ?? [];
      _selectedVenueId = widget.event!.venueLocationId;
      _schedules = widget.event!.schedules?.map((s) => s.toJson()).toList() ?? [];
    }
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabaseService.getCategories(),
        _supabaseService.getAllVenues(),
      ]);
      
      setState(() {
        _allCategories = results[0] as List<Category>;
        _allVenues = results[1] as List<VenueLocation>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading form data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
      );
      if (time != null) {
        setState(() {
          if (isStart) {
            _startDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 2));
            }
          } else {
            _endDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          }
        });
      }
    }
  }

  void _addSchedule() {
    setState(() {
      _schedules.add({
        'title': '',
        'start_time': _startDate.toIso8601String(),
        'speaker': '',
        'location_detail': '',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Crear Evento' : 'Editar Evento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título del Evento', prefixIcon: Icon(Icons.title)),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.description)),
              maxLines: 3,
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'URL de Imagen', prefixIcon: Icon(Icons.image)),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Inicio'),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_startDate)),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_endDate)),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedVenueId,
              decoration: const InputDecoration(labelText: 'Lugar (Sala/Área)', prefixIcon: Icon(Icons.location_on)),
              items: _allVenues.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
              onChanged: (val) => setState(() => _selectedVenueId = val),
              validator: (val) => val == null ? 'Selecciona un lugar' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Ubicación General (Ej: Cintermex, Mty)', prefixIcon: Icon(Icons.map)),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Precio', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(labelText: 'Capacidad', prefixIcon: Icon(Icons.people)),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Wrap(
              spacing: 8,
              children: _allCategories.map((cat) {
                final isSelected = _selectedCategoryIds.contains(cat.id);
                return FilterChip(
                  label: Text(cat.slug),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategoryIds.add(cat.id);
                      } else {
                        _selectedCategoryIds.remove(cat.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agenda / Horarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(onPressed: _addSchedule, icon: const Icon(Icons.add), label: const Text('Agregar Item')),
              ],
            ),
            ..._schedules.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> sched = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: sched['title'],
                              decoration: const InputDecoration(labelText: 'Actividad'),
                              onChanged: (val) => sched['title'] = val,
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _schedules.removeAt(idx))),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: sched['speaker'],
                              decoration: const InputDecoration(labelText: 'Ponente'),
                              onChanged: (val) => sched['speaker'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              title: const Text('Hora'),
                              subtitle: Text(DateFormat('HH:mm').format(DateTime.parse(sched['start_time']))),
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (time != null) {
                                  setState(() {
                                    final now = DateTime.parse(sched['start_time']);
                                    sched['start_time'] = DateTime(now.year, now.month, now.day, time.hour, time.minute).toIso8601String();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.event == null ? 'ENVIAR PARA APROBACIÓN' : 'GUARDAR CAMBIOS', 
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('No session');

      final eventData = {
        if (widget.event != null) 'id': widget.event!.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'location': _locationController.text.trim(),
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'capacity': int.tryParse(_capacityController.text) ?? 100,
        'venue_location_id': _selectedVenueId,
        'organizer_id': user.id,
        'status': widget.event?.status ?? 'pending',
      };

      await _supabaseService.saveEvent(
        eventData: eventData,
        categoryIds: _selectedCategoryIds,
        schedules: _schedules,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operación exitosa'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primaryRed));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
