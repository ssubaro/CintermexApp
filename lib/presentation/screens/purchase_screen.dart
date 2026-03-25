import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';
import '../../data/models/ticket_type_model.dart';
import '../../data/models/order_model.dart';
import '../../data/services/supabase_service.dart';
import '../../core/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseScreen extends StatefulWidget {
  final Event event;

  const PurchaseScreen({super.key, required this.event});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  int _quantity = 1;
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
    _fetchTicketTypes();
  }

  Future<void> _fetchTicketTypes() async {
    try {
      final types = await _supabaseService.getTicketTypes(widget.event.id);
      setState(() {
        _ticketTypes = types;
        if (_ticketTypes.isNotEmpty) {
          _selectedTicketType = _ticketTypes.first;
        }
        _isLoadingTypes = false;
      });
    } catch (e) {
      print('Error fetching ticket types: $e');
      setState(() => _isLoadingTypes = false);
    }
  }

  double get _unitPrice => _selectedTicketType?.price ?? widget.event.price;
  double get _totalPrice => _unitPrice * _quantity;

  void _increment() {
    if (_quantity < 10) {
      setState(() => _quantity++);
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

      // 1. Crear la Orden en estado 'pending'
      final order = await _supabaseService.createOrder(
        eventId: widget.event.id,
        ticketTypeId: _selectedTicketType?.id,
        quantity: _quantity,
        unitPrice: _unitPrice,
      );

      // 2. Crear el Ticket asociado a la Orden
      await _supabaseService.purchaseTicket(
        eventId: widget.event.id,
        quantity: _quantity,
        pricePaid: _totalPrice,
        orderId: order.id,
      );

      final checkoutUrl = await _supabaseService.createConektaCheckout(
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        unitPrice: _unitPrice,
        quantity: _quantity,
        customerEmail: user.email ?? '',
        userId: user.id,
        selectedDate: _selectedDate!.toIso8601String(),
      );

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.darkGrey,
              title: const Text('Pago en proceso',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                'Se ha abierto la página de pago de Conekta. Una vez completado, tus boletos aparecerán en "Mis Boletos".',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('ENTENDIDO',
                      style: TextStyle(color: AppColors.primaryRed)),
                ),
              ],
            ),
          );
        }
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
                      _buildQuantityButton(Icons.remove, _decrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      _buildQuantityButton(Icons.add, _increment),
                    ],
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
                      onPressed: _isProcessing ? null : _handlePurchase,
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

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
