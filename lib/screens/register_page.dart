import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: 'user',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful!'), backgroundColor: Colors.green),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      // Background color matches the form side of the login page
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side: Branding (Visible on Desktop/Tablet - Mirror of Login)
          if (size.width > 900)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_rounded, size: 120, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      "Join Click & Fix",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Start your smart repair journey with us",
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          // Right Side: Register Form
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button for mobile users
                        if (size.width <= 900)
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),

                        Text(
                          "Create Account",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join the community and get expert support",
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 40),

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (val) => val!.length < 6 ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRegister(),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                            ),
                          ),
                          validator: (val) {
                            if (val != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : const Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
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
}