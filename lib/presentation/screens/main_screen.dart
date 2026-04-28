import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'home_screen.dart';
import 'agenda_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<Widget> _screens;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const AgendaScreen(),
      const SearchScreen(),
      SavedScreen(onExplore: () => setState(() => _currentIndex = 0)),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.surfaceLight,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.white.withOpacity(0.30),
          selectedFontSize: 9,
          unselectedFontSize: 9,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border_rounded),
              label: 'Guardados',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
