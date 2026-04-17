import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  int _selectedRoleIndex = 0; // 0: User, 1: Technician

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (role != null) {
          // Navigate based on role
          String targetRoute;
          switch (role) {
            case 'admin':
              targetRoute = '/admin_dashboard';
              break;
            case 'technician':
              targetRoute = '/technician_profile';
              break;
            default:
              targetRoute = '/home';
          }
          Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTech = _selectedRoleIndex == 1;
    final authProvider = Provider.of<AuthProvider>(context);

    // Define colors for smooth transitions
    final primaryColor = isTech ? Colors.orange.shade800 : theme.colorScheme.primary;
    final accentColor = isTech ? Colors.orange.shade400 : theme.colorScheme.primaryContainer;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Branding Side with Animated Gradient
          if (size.width > 900)
            Expanded(
              flex: 3,
              child: TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 500),
                tween: ColorTween(begin: theme.colorScheme.primary, end: primaryColor),
                builder: (context, color, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color!, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Icon(
                        isTech ? Icons.engineering_rounded : Icons.build_circle_rounded,
                        key: ValueKey(_selectedRoleIndex),
                        size: 140,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isTech ? "TECH PORTAL" : "CLICK & FIX",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        isTech
                            ? "Manage your repair jobs and connect with clients nearby."
                            : "Professional repairs for your home and electronics.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Form Side
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTech ? "Technician Login" : "User Login",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isTech ? Colors.orange.shade900 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Welcome back! Please enter your credentials."),
                        const SizedBox(height: 32),

                        // Improved Toggle Switch
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildRoleOption("User", 0, Icons.person),
                              _buildRoleOption("Technician", 1, Icons.handyman),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Form Fields
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          validator: (val) => (val == null || !val.contains('@')) ? 'Invalid email' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (val) => (val == null || val.length < 6) ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 32),

                        // Animated Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New here? "),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, isTech ? '/tech_register' : '/register'),
                              child: Text(
                                "Create Account",
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Role Switcher Widget
  Widget _buildRoleOption(String title, int index, IconData icon) {
    final isSelected = _selectedRoleIndex == index;
    final primaryColor = index == 1 ? Colors.orange.shade800 : Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRoleIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}