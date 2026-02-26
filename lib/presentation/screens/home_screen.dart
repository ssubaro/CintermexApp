import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/event_model.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _bannerImages = [
    'https://www.ticketopolis.com/files/0f05c982-86f6-4b27-9e91-e3e2057028be/img/2026-02-03T21:34:50.649Z-f9813e2f-404d-4617-96fd-dc40f148ac32_header.jpg',
    'https://cifam.mx/wp-content/uploads/2025/09/CIFAM_MTY2026Positivo_horizontal@4x-scaled-e1759196025410-1024x406.png',
    'https://via.placeholder.com/800x400/EC2227/FFFFFF?text=Feria+Del+Libro',
  ];

  int _selectedMonthIndex = DateTime.now().month - 1; // 0-based index

  final List<String> _months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  // Stream de eventos desde Supabase
  final _supabase = Supabase.instance.client;

  Stream<List<Event>> _getEventsStream(int monthIndex) {
    final year = DateTime.now().year; // Asumimos año actual
    final startOfMonth = DateTime(year, monthIndex + 1, 1);
    final endOfMonth = DateTime(year, monthIndex + 2, 0);

    return _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('start_date')
        .map((data) {
          final events = data.map((e) => Event.fromJson(e)).toList();
          // Filtrado manual del stream si no se usa filtro en query directo
          return events.where((e) => 
            e.startDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
            e.startDate.isBefore(endOfMonth.add(const Duration(days: 1)))
          ).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: AppColors.primaryRed,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Section
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                aspectRatio: 2.0,
              ),
              items: _bannerImages.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: NetworkImage(i),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            
            // Month Filter Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _months.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedMonthIndex;
                    return ChoiceChip(
                      label: Text(_months[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedMonthIndex = index;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            // Events List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Eventos de ${_months[_selectedMonthIndex]}",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
            ),

            // Events List StreamBuilder
            StreamBuilder<List<Event>>(
              stream: _getEventsStream(_selectedMonthIndex),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  ));
                }
                
                if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}"));
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "No hay eventos para este mes",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      title: event.title,
                      date: "${event.startDate.day} de ${_months[event.startDate.month - 1]}",
                      location: event.location,
                      imageUrl: event.imageUrl,
                    );
                  },
                );
              },
            ),

            // Footer Section
            Container(
              color: AppColors.darkGrey,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.facebook, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.add_ic_call_sharp, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.web, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () {}, child: const Text("Términos y Condiciones", style: TextStyle(color: Colors.white70))),
                  TextButton(onPressed: () {}, child: const Text("Aviso de Privacidad", style: TextStyle(color: Colors.white70))),
                  TextButton(onPressed: () {}, child: const Text("Acerca de Nosotros", style: TextStyle(color: Colors.white70))),
                  const SizedBox(height: 10),
                  const Text("© 2026 Cintermex. Todos los derechos reservados.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
