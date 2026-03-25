import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/event_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/event_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  final List<String> _bannerImages = [
    'https://i.ytimg.com/vi/sI6fg4q98Is/maxresdefault.jpg',
    'https://scontent-qro1-2.xx.fbcdn.net/v/t39.30808-6/629656775_1379915637510040_3990866888935312711_n.jpg?_nc_cat=111&ccb=1-7&_nc_sid=13d280&_nc_ohc=ElCD4MPmrq8Q7kNvwGpgZeT&_nc_oc=AdmtevaND2nmp8DJL1-31saz59DXHgTgfuZB1Y8a66KF919VYhOQ8bIt76yYyNsorVA&_nc_zt=23&_nc_ht=scontent-qro1-2.xx&_nc_gid=G_S_Guw6vd1F_qzfI67onw&oh=00_AfuH7yIbysGaLaza3kyfUYh5JbTSDVIFueY_9k-LSooRg&oe=69A570E4',
    'https://tse4.mm.bing.net/th/id/OIP.brloUje5f0mZIwIzCakuAgHaGW?rs=1&pid=ImgDetMain&o=7&rm=3',
  ];

  int _selectedMonthIndex = DateTime.now().month - 1; // 0-based index

  final List<String> _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];

  void _updateEvents() {
    final year = DateTime.now().year;
    final startOfMonth = DateTime(year, _selectedMonthIndex + 1, 1);
    final endOfMonth = DateTime(year, _selectedMonthIndex + 2, 0, 23, 59, 59);

    _supabaseService.refreshEvents(
      categoryId: _selectedCategoryId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _updateEvents();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _supabaseService.getCategories(),
      ]);
      setState(() {
        _categories = futures[0] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName,
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: AppColors.primaryRed,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () {
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                // Si ya inició sesión, abrimos el Drawer donde tiene las opciones
                Scaffold.of(context).openDrawer();
              }
            },
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedMonthIndex;
                    return ChoiceChip(
                      label: Text(_months[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedMonthIndex = index;
                          });
                          _updateEvents();
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            // Category Filter Section
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed))
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1, // +1 for "All" category
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" category chip
                        final isSelected = _selectedCategoryId == null;
                        return ChoiceChip(
                          label: const Text('Todos'),
                          selected: isSelected,
                          selectedColor: AppColors.primaryRed,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _updateEvents();
                            }
                          },
                        );
                      }
                      final category = _categories[index - 1];
                      final isSelected = _selectedCategoryId == category.id;
                      return ChoiceChip(
                        label: Text(category.name),
                        selected: isSelected,
                        selectedColor: AppColors.primaryRed,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryId = category.id;
                            });
                            _updateEvents();
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
                "Eventos de ${_months[_selectedMonthIndex]} ${DateTime.now().year}",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
              ),
            ),

            // Events List StreamBuilder
            StreamBuilder<List<Event>>(
              stream: _supabaseService.eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child:
                        CircularProgressIndicator(color: AppColors.primaryRed),
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
                          const Icon(Icons.event_busy,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "No hay eventos para este mes",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(event: event);
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
                      IconButton(
                          icon: const Icon(Icons.facebook, color: Colors.white),
                          onPressed: () {}),
                      IconButton(
                          icon: const Icon(Icons.add_ic_call_sharp,
                              color: Colors.white),
                          onPressed: () {}),
                      IconButton(
                          icon: const Icon(Icons.web, color: Colors.white),
                          onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                      onPressed: () {},
                      child: const Text("Términos y Condiciones",
                          style: TextStyle(color: Colors.white70))),
                  TextButton(
                      onPressed: () {},
                      child: const Text("Aviso de Privacidad",
                          style: TextStyle(color: Colors.white70))),
                  TextButton(
                      onPressed: () {},
                      child: const Text("Acerca de Nosotros",
                          style: TextStyle(color: Colors.white70))),
                  const SizedBox(height: 10),
                  const Text("© 2026 Cintermex. Todos los derechos reservados.",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
