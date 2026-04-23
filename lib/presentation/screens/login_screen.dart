import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/services/supabase_service.dart';
import '../../data/models/category_model.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/status_dialog.dart';

class LoginScreen extends StatefulWidget {
  final bool isRegister;
  final String? initialRole;

  const LoginScreen({
    super.key,
    this.isRegister = false,
    this.initialRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'cliente'; // Default role for sign up
  bool _isRoleSelected = false; // State to toggle pages

  List<Category> _categories = [];
  final List<String> _selectedCategoryIds = [];

  // Validation states
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isFullNameValid = false;
  bool _isPhoneValid = false;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Track if user has interacted
  bool _isEmailDirty = false;
  bool _isPasswordDirty = false;
  bool _isFullNameDirty = false;

  bool _validateEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.isRegister;
    if (widget.initialRole != null) {
      _selectedRole = widget.initialRole!;
      _isRoleSelected = true;
    } else if (widget.isRegister) {
      // Si es registro y no hay rol, por defecto mostramos el form de cliente
      _selectedRole = 'cliente';
      _isRoleSelected = true;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _supabaseService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos')),
      );
      return;
    }

    // Validación de formato antes de mandar
    if (!_validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un correo válido')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    if (!_isLogin && !_isFullNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre completo es muy corto')),
      );
      return;
    }

    if (!_isLogin && !_isConfirmPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final res = await _supabaseService.signIn(email, password);
        final user = res.user;
        if (user != null) {
          final role = await _supabaseService.getUserRole(user.id);
          if (mounted) {
            if (role == 'admin') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen()),
                (route) => false,
              );
              return;
            }
          }
        }
      } else {
        final res = await _supabaseService.signUp(
          email: email,
          password: password,
          role: _selectedRole,
          fullName: _fullNameController.text.isNotEmpty
              ? _fullNameController.text.trim()
              : null,
          displayName: _displayNameController.text.isNotEmpty
              ? _displayNameController.text.trim()
              : null,
          phone: _phoneController.text.isNotEmpty
              ? _phoneController.text.trim()
              : null,
          selectedCategoryIds: _selectedCategoryIds,
        );
        // Supabase requiere confirmación de email por defecto.
        // Si session es nulo pero user no, es porque falta confirmar.
        if (res.session == null && res.user != null) {
          if (mounted) {
            await StatusDialog.show(
              context: context,
              title: '¡Verifica tu correo!',
              message:
                  'Registro exitoso. Te hemos enviado un enlace de confirmación a tu correo electrónico para activar tu cuenta.',
              icon: Icons.mark_email_read_outlined,
              iconColor: Colors.blueAccent,
            );
            setState(() {
              _isLoading = false;
              _isLogin = true; // Cambiamos a login tras registro
            });
          }
          return;
        }
      }

      if (mounted) {
        // Volver al inicio limpio tras el inicio de sesión si no fue admin
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isRoleSelected
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isRoleSelected = false; // Regresa al selector
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () =>
                    Navigator.of(context).pop(), // Sale de login_screen
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: !_isRoleSelected ? _buildRoleSelection() : _buildAuthForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'images/cintermex-logo.png', // Logo de Cintermex
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.business,
              size: 100,
              color: AppColors.primaryRed,
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 64),
        const Text(
          'Selecciona tu tipo de cuenta',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.primaryRed),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedRole = 'cliente';
              _isRoleSelected = true;
              _isLogin = true; // Empieza asumiendo login
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 28),
              SizedBox(width: 12),
              Text('Soy Cliente / Usuario',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedRole = 'organizador';
              _isRoleSelected = true;
              _isLogin = true; // Organizador solo login por ahora
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryRed,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primaryRed, width: 2),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 28),
              SizedBox(width: 12),
              Text('Soy Organizador',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedRole = 'cliente';
              _isRoleSelected = true;
              _isLogin = false; // Va directo a crear cuenta
            });
          },
          child: const Text(
            '¿Aún no tienes cuenta? Regístrate',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo pequeño
        Image.asset(
          'images/cintermex-logo.png', // Logo de Cintermex
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.business,
              size: 60,
              color: AppColors.primaryRed,
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          _selectedRole == 'cliente' ? 'Acceso Cliente' : 'Acceso Organizador',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Ingresa tus datos' : 'Crea una cuenta nueva',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),

        // Campos Adicionales (Solo Registro)
        if (!_isLogin) ...[
          TextField(
            controller: _fullNameController,
            onChanged: (val) {
              setState(() {
                _isFullNameDirty = true;
                _isFullNameValid = val.trim().length >= 3;
              });
            },
            decoration: InputDecoration(
              labelText: 'Nombre Completo',
              prefixIcon: const Icon(Icons.person),
              suffixIcon: _isFullNameDirty
                  ? Icon(_isFullNameValid ? Icons.check_circle : Icons.error,
                      color: _isFullNameValid ? Colors.green : Colors.red)
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isFullNameDirty
                      ? (_isFullNameValid ? Colors.green : Colors.red)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            onChanged: (val) {
              setState(() {
                // Reutilizamos el estado de nombre completo o creamos uno si es necesario
                // Para simplificar, validaremos que no esté vacío
              });
            },
            decoration: InputDecoration(
              labelText: 'Nombre de Usuario',
              prefixIcon: const Icon(Icons.badge),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (val) {
              setState(() {
                _isPhoneValid = val.trim().length >= 10;
              });
            },
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: _phoneController.text.isNotEmpty
                  ? Icon(_isPhoneValid ? Icons.check_circle : Icons.error,
                      color: _isPhoneValid ? Colors.green : Colors.red)
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _phoneController.text.isNotEmpty
                      ? (_isPhoneValid ? Colors.green : Colors.red)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Form Fields
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (val) {
            setState(() {
              _isEmailDirty = true;
              _isEmailValid = _validateEmail(val.trim());
            });
          },
          decoration: InputDecoration(
            labelText: 'Correo Electrónico',
            prefixIcon: const Icon(Icons.email),
            suffixIcon: _isEmailDirty
                ? Icon(_isEmailValid ? Icons.check_circle : Icons.error,
                    color: _isEmailValid ? Colors.green : Colors.red)
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isEmailDirty
                    ? (_isEmailValid ? Colors.green : Colors.red)
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (val) {
            setState(() {
              _isPasswordDirty = true;
              _isPasswordValid = val.length >= 6;
              // También re-validar confirmación si ya tenía algo
              _isConfirmPasswordValid = val == _confirmPasswordController.text;
            });
          },
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                if (_isPasswordDirty)
                  Icon(_isPasswordValid ? Icons.check_circle : Icons.error, 
                       color: _isPasswordValid ? Colors.green : Colors.red),
                const SizedBox(width: 8),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isPasswordDirty
                    ? (_isPasswordValid ? Colors.green : Colors.red)
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirmar Contraseña (Solo Registro)
        if (!_isLogin) ...[
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            onChanged: (val) {
              setState(() {
                _isConfirmPasswordValid = val == _passwordController.text;
              });
            },
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  if (_confirmPasswordController.text.isNotEmpty)
                    Icon(_isConfirmPasswordValid ? Icons.check_circle : Icons.error, 
                         color: _isConfirmPasswordValid ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _confirmPasswordController.text.isNotEmpty
                      ? (_isConfirmPasswordValid ? Colors.green : Colors.red)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 8),

        // Olvidaste contraseña (solo en login)
        if (_isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(color: AppColors.primaryRed, fontSize: 13),
              ),
            ),
          ),

        // Intereses Selector (Solo Registro)
        if (!_isLogin && _categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Intereses (Opcional):',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primaryRed),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategoryIds.contains(cat.id);
              return FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                selectedColor: AppColors.primaryRed.withOpacity(0.2),
                checkmarkColor: AppColors.primaryRed,
                onSelected: (bool selected) {
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
          const SizedBox(height: 32),
        ] else ...[
          const SizedBox(height: 32),
        ],

        // Submit Button
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Toggle Button (solo clientes pueden registrarse)
        if (_selectedRole == 'cliente')
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(
              _isLogin
                  ? '¿No tienes cuenta? Regístrate aquí'
                  : '¿Ya tienes cuenta? Inicia sesión',
              style: const TextStyle(color: Colors.white70),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Solo los clientes pueden crear cuentas.\nLos organizadores deben solicitar acceso a soporte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
