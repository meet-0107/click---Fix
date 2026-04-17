import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final role = authProvider.userRole;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(
                          'assets/Click_logo.jpeg',
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Click & Fix',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 12),
                    Text(authProvider.user?.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(authProvider.user?.email ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role == 'admin' ? Colors.red.shade50 : role == 'technician' ? Colors.orange.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold,
                          color: role == 'admin' ? Colors.red.shade700 : role == 'technician' ? Colors.orange.shade700 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Role-specific nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // USER items only
                  if (isLoggedIn && role == 'user') ...[
                    _tile(context, 'Home', Icons.home, '/home'),
                    _tile(context, 'My Requests', Icons.list_alt, '/user_requests'),
                    _tile(context, 'Repair Guides', Icons.menu_book, '/repair'),
                    _tile(context, 'Find a Technician', Icons.engineering, '/technician_support'),
                  ],

                  // TECHNICIAN items only
                  if (isLoggedIn && role == 'technician') ...[
                    _tile(context, 'My Dashboard', Icons.dashboard, '/technician_profile'),
                  ],

                  // ADMIN items only
                  if (isLoggedIn && role == 'admin') ...[
                    _tile(context, 'Dashboard', Icons.dashboard, '/admin_dashboard'),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                      child: Text('Management', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    _tile(context, 'Manage Users', Icons.people, '/admin_users'),
                    _tile(context, 'Manage Technicians', Icons.engineering, '/admin_technicians'),
                    _tile(context, 'View Feedback', Icons.feedback, '/admin_feedback'),
                  ],

                  // Not logged in
                  if (!isLoggedIn) ...[
                    _tile(context, 'Repair Guides', Icons.menu_book, '/repair'),
                  ],
                ],
              ),
            ),

            // Auth
            const Divider(height: 1),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.signOut();
                  if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: Color(0xFF0061FF)),
                title: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
