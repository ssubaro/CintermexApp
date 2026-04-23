import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';
import '../../data/models/ticket_type_model.dart';
import '../../data/services/supabase_service.dart';
import '../../core/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'my_tickets_screen.dart';

class PurchaseScreen extends StatefulWidget {
  final Event event;

  const PurchaseScreen({super.key, required this.event});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  static const int MAX_TICKETS_PER_USER = 6;
  int _quantity = 1;
  int _alreadyOwnedCount = 0;
  DateTime? _selectedDate;
  List<TicketType> _ticketTypes = [];
  TicketType? _selectedTicketType;
  bool _isLoadingTypes = true;
  bool _isProcessing = false;
  final SupabaseService _supabaseService = SupabaseService();
  final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_MX');
  late List<DateTime> _availableDays;

  @override
  void initState() {
    super.initState();
    _availableDays = widget.event.getDaysList();
    if (_availableDays.isNotEmpty) {
      _selectedDate = _availableDays.first;
    }
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        _supabaseService.getTicketTypes(widget.event.id),
        _supabaseService.getEventTicketCount(widget.event.id),
      ]);

      final types = results[0] as List<TicketType>;
      final ownedCount = results[1] as int;

      setState(() {
        _ticketTypes = types;
        _alreadyOwnedCount = ownedCount;
        
        if (_ticketTypes.isNotEmpty) {
          _selectedTicketType = _ticketTypes.first;
        }

        // Si ya tiene boletos, ajustar la cantidad inicial si es necesario
        int remaining = MAX_TICKETS_PER_USER - _alreadyOwnedCount;
        if (remaining <= 0) {
          _quantity = 0;
        } else if (_quantity > remaining) {
          _quantity = remaining;
        }

        _isLoadingTypes = false;
      });
    } catch (e) {
      print('Error fetching initial data: $e');
      setState(() => _isLoadingTypes = false);
    }
  }

  double get _unitPrice => _selectedTicketType?.price ?? widget.event.price;
  double get _totalPrice => _unitPrice * _quantity;

  void _increment() {
    int remaining = MAX_TICKETS_PER_USER - _alreadyOwnedCount;
    if (_quantity < remaining) {
      setState(() => _quantity++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Límite máximo de $MAX_TICKETS_PER_USER boletos por cuenta alcanzado.')),
      );
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');


      // Obtener el nombre real del usuario del perfil
      final profile = await _supabaseService.getProfile(user.id);
      final customerName = profile?['full_name'] ?? profile?['display_name'] ?? 'Cliente Cintermex';
      final ticketTypeName = _selectedTicketType?.name ?? 'General';

      final checkoutUrl = await _supabaseService.createConektaCheckout(
        eventId: widget.event.id,
        eventTitle: '${widget.event.title} - $ticketTypeName',
        unitPrice: _unitPrice,
        quantity: _quantity,
        customerEmail: user.email ?? '',
        customerName: customerName,
        userId: user.id,
        selectedDate: _selectedDate!.toIso8601String(),
        ticketTypeId: _selectedTicketType?.id,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        final uri = Uri.parse(checkoutUrl);
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppColors.darkGrey,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 60, color: AppColors.primaryRed),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Portal de Pago Listo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Para completar tu compra de forma segura, haz clic en el botón de abajo para ir al portal oficial de Conekta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new, size: 20),
                          SizedBox(width: 10),
                          Text('IR A PAGAR AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Ya completaste tu pago?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                      );
                    },
                    child: const Text('VER MIS BOLETOS', 
                      style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCELAR', 
                      style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        throw 'No se pudo abrir la página de pago';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar el pago: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPrice;
    final dayFormat = DateFormat('EEE, d MMM', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Compra'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.darkGrey,
      body: _isLoadingTypes 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.event.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Selecciona tu Boleto',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (_ticketTypes.isEmpty)
                    Text(
                      'Precio General: ${currencyFormat.format(widget.event.price)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    )
                  else
                    Column(
                      children: _ticketTypes.map((type) {
                        return RadioListTile<TicketType>(
                          title: Text(type.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(type.description ?? '', style: const TextStyle(color: Colors.white70)),
                          secondary: Text(
                            currencyFormat.format(type.price),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed),
                          ),
                          value: type,
                          groupValue: _selectedTicketType,
                          onChanged: (val) {
                            setState(() => _selectedTicketType = val);
                          },
                          activeColor: AppColors.primaryRed,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  
                  const Divider(height: 40, color: Colors.white12),

                  // Date Selection
                  const Text(
                    'Selecciona el día',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDays.length,
                      itemBuilder: (context, index) {
                        final date = _availableDays[index];
                        final isSelected = _selectedDate == date;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(dayFormat.format(date).toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedDate = date);
                            },
                            selectedColor: AppColors.primaryRed,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Cantidad',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuantityButton(
                        Icons.remove, 
                        (_alreadyOwnedCount >= MAX_TICKETS_PER_USER || _quantity <= 1) ? null : _decrement
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          '$_quantity',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: (_alreadyOwnedCount >= MAX_TICKETS_PER_USER) ? Colors.grey : Colors.white),
                        ),
                      ),
                      _buildQuantityButton(
                        Icons.add, 
                        (_alreadyOwnedCount >= MAX_TICKETS_PER_USER) ? null : _increment
                      ),
                    ],
                  ),
                  
                  if (_alreadyOwnedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Ya tienes $_alreadyOwnedCount boletos para este evento.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ),

                  if (_alreadyOwnedCount >= MAX_TICKETS_PER_USER)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Has alcanzado el límite de $MAX_TICKETS_PER_USER boletos por cuenta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Total and Confirmation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Resumen',
                                style: TextStyle(color: Colors.white70)),
                            Text('$_quantity Boletos',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              currencyFormat.format(total),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || _alreadyOwnedCount >= MAX_TICKETS_PER_USER || _quantity == 0) 
                          ? null 
                          : _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'PAGAR CON CONEKTA',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed) {
    bool isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isEnabled ? Colors.white24 : Colors.white12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isEnabled ? Colors.white : Colors.white30, size: 28),
      ),
    );
  }
}
