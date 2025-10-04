import 'package:flutter/material.dart';
import 'package:admin_therophonobot/constants/widgets/app_bar.dart';
import 'package:admin_therophonobot/features/home/views/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscureText = true;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validation
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = response.user;
      final Session? session = response.session;

      if (user == null || session == null) {
        throw Exception('Authentication failed - no user or session returned');
      }

      // Check if email is verified (if your Supabase requires email verification)
      if (user.emailConfirmedAt == null) {
        throw Exception('Please verify your email before logging in');
      }

      // Successfully logged in
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on AuthException catch (e) {
      _handleAuthError(e.message);
    } on Exception catch (e) {
      _handleGenericError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email address');
      return false;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters long');
      return false;
    }

    return true;
  }

  void _handleAuthError(String message) {
    String userFriendlyMessage;

    switch (message) {
      case 'Invalid login credentials':
        userFriendlyMessage = 'Invalid email or password';
        break;
      case 'Email not confirmed':
        userFriendlyMessage = 'Please verify your email before logging in';
        break;
      case 'User already registered':
        userFriendlyMessage = 'An account with this email already exists';
        break;
      case 'Too many requests':
        userFriendlyMessage = 'Too many login attempts. Please try again later';
        break;
      case 'Network error':
        userFriendlyMessage =
            'Network connection failed. Please check your internet';
        break;
      default:
        userFriendlyMessage = 'Authentication failed: $message';
    }

    _showError(userFriendlyMessage);
  }

  void _handleGenericError(Exception e) {
    String errorMessage = 'An unexpected error occurred';

    if (e.toString().contains('socket') ||
        e.toString().contains('network') ||
        e.toString().contains('connection')) {
      errorMessage = 'Network error. Please check your internet connection';
    } else if (e.toString().contains('timeout')) {
      errorMessage = 'Request timeout. Please try again';
    } else {
      errorMessage = 'Error: ${e.toString()}';
    }

    _showError(errorMessage);
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar(showBackButton: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width > 600 ? 400 : width * 0.9,
            ),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Admin Login',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _textField(
                      controller: _emailController,
                      hint: 'Admin Email',
                      icon: Icons.email,
                      isPassword: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _isLoading ? Colors.grey : null,
                  ),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() => _obscureText = !_obscureText);
                          },
                )
                : null,
      ),
    );
  }
}
