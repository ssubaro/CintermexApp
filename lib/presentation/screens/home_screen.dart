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
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Category> _categories = [];
  List<String> _selectedCategoryIds = [];
  bool _isLoading = true;

  final List<String> _bannerImages = [
    'https://i.ytimg.com/vi/sI6fg4q98Is/maxresdefault.jpg',
    'https://scontent-qro1-2.xx.fbcdn.net/v/t39.30808-6/629656775_1379915637510040_3990866888935312711_n.jpg?_nc_cat=111&ccb=1-7&_nc_sid=13d280&_nc_ohc=ElCD4MPmrq8Q7kNvwGpgZeT&_nc_oc=AdmtevaND2nmp8DJL1-31saz59DXHgTgfuZB1Y8a66KF919VYhOQ8bIt76yYyNsorVA&_nc_zt=23&_nc_ht=scontent-qro1-2.xx&_nc_gid=G_S_Guw6vd1F_qzfI67onw&oh=00_AfuH7yIbysGaLaza3kyfUYh5JbTSDVIFueY_9k-LSooRg&oe=69A570E4',
    'https://tse4.mm.bing.net/th/id/OIP.brloUje5f0mZIwIzCakuAgHaGW?rs=1&pid=ImgDetMain&o=7&rm=3',
  ];

  int? _selectedMonthIndex = DateTime.now().month - 1; // 0-based index
  int _selectedYear = DateTime.now().year;

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
    DateTime? start;
    DateTime? end;

    if (_selectedMonthIndex != null) {
      final now = DateTime.now();
      _selectedYear = now.year;
      final selectedMonth = _selectedMonthIndex! + 1; // 1-based

      // Si el mes seleccionado ya pasó en el año actual, buscamos en el siguiente año
      if (selectedMonth < now.month) {
        _selectedYear++;
      }

      start = DateTime(_selectedYear, selectedMonth, 1);
      // El día 0 del mes siguiente es el último día del mes actual
      end = DateTime(_selectedYear, selectedMonth + 1, 0, 23, 59, 59);
    }

    _supabaseService.refreshEvents(
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
      startDate: start,
      endDate: end,
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
        _categories = futures[0];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showMultiSelectCategories() {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Esto es super importante para que el teclado no tape el menú
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filtrar categorias en tiempo real
            final currentCategories = _categories.where((cat) {
              return cat.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                     cat.slug.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seleccionar Categorías',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategoryIds.clear();
                              searchQuery = ''; // Limpiar la busqueda
                            });
                            setState(() {});
                            _updateEvents();
                          },
                          child: const Text('Limpiar', style: TextStyle(color: Colors.grey)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Búsqueda
                    TextField(
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar categoría...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryRed),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryRed),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: currentCategories.isEmpty 
                        ? const Center(child: Text('No se encontraron categorías', style: TextStyle(color: Colors.grey))) 
                        : ListView.builder(
                          itemCount: currentCategories.length,
                          itemBuilder: (context, index) {
                            final cat = currentCategories[index];
                            final isSelected = _selectedCategoryIds.contains(cat.id);
                            return CheckboxListTile(
                              title: Text(cat.slug, style: const TextStyle(fontSize: 16)),
                              value: isSelected,
                              activeColor: AppColors.primaryRed,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    _selectedCategoryIds.add(cat.id);
                                  } else {
                                    _selectedCategoryIds.remove(cat.id);
                                  }
                                });
                                setState(() {}); // Update main UI
                                _updateEvents(); // Fetch new data
                              },
                            );
                          },
                        ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName,
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                }
              },
            ),
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
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: (_selectedMonthIndex == null) 
                          ? AppColors.primaryRed 
                          : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_alt_off, 
                        color: (_selectedMonthIndex == null)
                            ? Colors.white
                            : Colors.white70,
                      ),
                      tooltip: 'Todos los meses',
                      onPressed: () {
                        setState(() {
                          _selectedMonthIndex = null;
                        });
                        _updateEvents();
                      },
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 56,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelStyle: TextStyle(
                              fontSize: 16,
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
                ],
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
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.checklist, color: Colors.white),
                        tooltip: 'Filtro avanzado',
                        onPressed: _showMultiSelectCategories,
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length + 1,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected = _selectedCategoryIds.isEmpty;
                              return ChoiceChip(
                                label: const Text('Todos'),
                                selected: isSelected,
                                selectedColor: AppColors.primaryRed,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategoryIds.clear();
                                    });
                                    _updateEvents();
                                  }
                                },
                              );
                            }
                            final category = _categories[index - 1];
                            final isSelected = _selectedCategoryIds.contains(category.id);
                            return ChoiceChip(
                              label: Text(category.slug),
                              selected: isSelected,
                              selectedColor: AppColors.primaryRed,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              labelStyle: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategoryIds.add(category.id);
                                  } else {
                                    _selectedCategoryIds.remove(category.id);
                                  }
                                });
                                _updateEvents();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Events List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _selectedMonthIndex != null 
                    ? "Eventos de ${_months[_selectedMonthIndex!]} $_selectedYear"
                    : "Todos los eventos",
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
