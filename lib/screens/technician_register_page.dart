import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TechRegisterPage extends StatefulWidget {
  const TechRegisterPage({super.key});

  @override
  State<TechRegisterPage> createState() => _TechRegisterPageState();
}

class _TechRegisterPageState extends State<TechRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Branding Side (Mirroring your Login Page)
          if (size.width > 900)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.engineering_rounded, size: 120, color: Colors.white),
                    SizedBox(height: 24),
                    Text("Technician Portal", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    Text("Join our network of experts", style: TextStyle(color: Colors.white70, fontSize: 18)),
                  ],
                ),
              ),
            ),

          // Form Side
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Technician Signup", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 30),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                          validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          validator: (val) => val!.contains('@') ? null : 'Invalid email',
                        ),
                        const SizedBox(height: 20),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                          validator: (val) => val!.length < 6 ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 20),

                        // PINCODE (Specific for Technicians)
                        TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Service Pincode',
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Where do you provide service?',
                          ),
                          validator: (val) => val!.length != 6 ? 'Enter valid 6-digit Pincode' : null,
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      final success = await authProvider.signUp(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text.trim(),
                                        name: _nameController.text.trim(),
                                        role: 'technician',
                                        pincode: _pincodeController.text.trim(),
                                      );

                                      if (mounted) {
                                        if (success) {
                                          Navigator.pushNamedAndRemoveUntil(context, '/technician_profile', (route) => false);
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
                                  },
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : const Text("Complete Registration"),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Back to User Login"),
                          ),
                        )
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