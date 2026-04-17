import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

// Firebase
import 'services/firebase_config.dart';
import 'providers/auth_provider.dart';

// Screens
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/repair_page.dart';
import 'screens/self_repair_guide_page.dart';
import 'screens/technician_support_page.dart';
import 'screens/feedback_rating_page.dart';
import 'screens/user_requests_page.dart';
import 'screens/register_page.dart';
import 'screens/technician_register_page.dart';
import 'screens/technician_profile_page.dart';

// Admin Screens
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/manage_users_page.dart';
import 'screens/admin/manage_guides_page.dart';
import 'screens/admin/manage_technicians_page.dart';
import 'screens/admin/view_feedback_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Click & Fix | Smart Repair Support',
        debugShowCheckedModeBanner: false,
        scrollBehavior: MyCustomScrollBehavior(),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0061FF),
            primary: const Color(0xFF0061FF),
            secondary: Colors.orangeAccent,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Use AuthWrapper as home to handle persistence
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/tech_register': (context) => const TechRegisterPage(),
          '/home': (context) => const HomePage(),
          '/repair': (context) => const RepairPage(),
          '/self_repair_guide': (context) => const SelfRepairGuidePage(),
          '/technician_support': (context) => const TechnicianSupportPage(),
          '/feedback_rating': (context) => const FeedbackRatingPage(),
          '/user_requests': (context) => const UserRequestsPage(),
          '/technician_profile': (context) => const TechnicianProfilePage(),
          '/admin_dashboard': (context) => const AdminDashboardPage(),
          '/admin_users': (context) => const ManageUsersPage(),
          '/admin_guides': (context) => const ManageGuidesPage(),
          '/admin_technicians': (context) => const ManageTechniciansPage(),
          '/admin_feedback': (context) => const ViewFeedbackPage(),
        },
      ),
    );
  }
}

/// Checks auth state on app start and routes to the correct screen.
/// This keeps the user logged in when they close and reopen the app.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Still loading auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/Click_logo.jpeg'),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    color: Color(0xFF0061FF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Not logged in
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }

        // Route based on role
        switch (authProvider.userRole) {
          case 'admin':
            return const AdminDashboardPage();
          case 'technician':
            return const TechnicianProfilePage();
          default:
            return const HomePage();
        }
      },
    );
  }
}