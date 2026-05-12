import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/event_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/announcement_model.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/event_card.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'event_detail_screen.dart';
import '../widgets/estacionamiento_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Category> _categories = [];
  final List<String> _selectedCategoryIds = [];
  List<Event> _forYouEvents = [];
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  int _currentSlide = 0;

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

      start = DateTime(_selectedYear, selectedMonth, 1);
      // El día 0 del mes siguiente es el último día del mes actual
      end = DateTime(_selectedYear, selectedMonth + 1, 0, 23, 59, 59);
    } else {
      start = DateTime.now();
      end = null;
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
        _supabaseService.getForYouEvents(),
        _supabaseService.getAnnouncements(),
      ]);
      setState(() {
        _categories = futures[0] as List<Category>;
        _forYouEvents = futures[1] as List<Event>;
        _announcements = futures[2] as List<Announcement>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Widget> _buildSliderItems() {
    List<Widget> items = [];
    
    for (var event in _forYouEvents) {
      items.add(_buildEventSlide(event));
    }

    for (var aviso in _announcements) {
      items.add(_buildAnnouncementSlide(aviso));
    }

    if (items.isEmpty) {
      items.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: const Center(
          child: Text("Explora eventos próximos", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ));
    }

    items.add(Builder(
      builder: (BuildContext context) {
        // Envolvemos el widget existente en tap o simplemente lo mostramos. Ya tiene botones.
        return const EstacionamientoWidget();
      },
    ));

    return items;
  }

  Widget _buildEventSlide(Event event) {
    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)));
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(14.0),
              image: DecorationImage(
                image: NetworkImage(event.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.0),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0xFF0F0F0F).withOpacity(0.95)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category?.toUpperCase() ?? "DESTACADO",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("${event.startDate.day}/${event.startDate.month}/${event.startDate.year} • ${event.location}", style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementSlide(Announcement aviso) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(14.0),
            image: DecorationImage(
              image: NetworkImage(aviso.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.0),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, const Color(0xFF0F0F0F).withOpacity(0.95)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.announcement,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "AVISO",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(aviso.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDotsIndicator() {
    int totalItems = _forYouEvents.length + _announcements.length + 1;
    if (totalItems <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalItems, (index) {
        bool isParking = index == totalItems - 1;
        bool isAnnouncement = !isParking && index >= _forYouEvents.length;
        Color activeColor = AppColors.primary;
        if (isParking) {
          activeColor = Colors.grey;
        } else if (isAnnouncement) activeColor = AppColors.announcement;

        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentSlide == index ? activeColor : Colors.grey.withOpacity(0.3),
          ),
        );
      }),
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
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
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
            Column(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    enlargeCenterPage: true,
                    viewportFraction: 0.9,
                    aspectRatio: 2.0,
                    onPageChanged: (index, reason) {
                      setState(() => _currentSlide = index);
                    },
                  ),
                  items: _buildSliderItems(),
                ),
                _buildDotsIndicator(),
              ],
            ),

            // Month Filter Section
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _months.length + 1, // +1 for "Todos"
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final isSelected = isAll ? _selectedMonthIndex == null : (index - 1) == _selectedMonthIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonthIndex = isAll ? null : (index - 1);
                        });
                        _updateEvents();
                      },
                      child: Container(
                        width: 42,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isAll)
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                              )
                            else
                              Text(
                                '$index', // Basic 1-12 mapping for month numbers
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            Text(
                              isAll ? 'All' : _months[index - 1],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Category Filter Section
            if (_isLoading)
               const Center(child: Padding(
                 padding: EdgeInsets.all(8.0),
                 child: CircularProgressIndicator(color: AppColors.primaryRed),
               ))
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  height: 30, // Fit the new categories styling
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final isSelected = isAll ? _selectedCategoryIds.isEmpty : _selectedCategoryIds.contains(_categories[index - 1].id);
                      final label = isAll ? 'Todos' : _categories[index - 1].slug;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isAll) {
                              _selectedCategoryIds.clear();
                            } else {
                              final catId = _categories[index - 1].id;
                              if (_selectedCategoryIds.contains(catId)) {
                                _selectedCategoryIds.remove(catId);
                              } else {
                                _selectedCategoryIds.add(catId);
                              }
                            }
                          });
                          _updateEvents();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.15),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                  return const Center(child: Text('Error cargando eventos'));
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: EventCard(event: event),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

  }
}
