import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_service.dart';
import '../screens/home_screen.dart';
import '../screens/admin_dashboard_screen.dart';


class RootWrapper extends StatefulWidget {
  const RootWrapper({super.key});

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  Widget? _homeScreen;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _homeScreen = const HomeScreen();
        _isLoading = false;
      });
      return;
    }

    try {
      final role = await _supabaseService.getUserRole(user.id);
      setState(() {
        if (role == 'admin') {
          _homeScreen = const AdminDashboardScreen();
        } else {
          _homeScreen = const HomeScreen();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _homeScreen = const HomeScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }
    return _homeScreen ?? const HomeScreen();
  }
}
