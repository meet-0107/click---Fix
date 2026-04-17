import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class NavigationBarWidget extends StatelessWidget {
  const NavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1000;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final role = authProvider.userRole;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      automaticallyImplyLeading: false,
      leading: isMobile
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87,size: 32,),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      title: InkWell(
        onTap: () {
          final target = !isLoggedIn ? '/login'
              : role == 'admin' ? '/admin_dashboard'
              : role == 'technician' ? '/technician_profile'
              : '/home';
          Navigator.pushNamedAndRemoveUntil(context, target, (route) => false);
        },
        hoverColor: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20, // AppBar small logo
              backgroundColor: Colors.white,
              backgroundImage: const AssetImage(
                'assets/Click_logo.jpeg',
              ),
            ),
            const SizedBox(width: 8),
            const Text('Click & Fix',
                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w700, fontSize: 20)),
            if (isLoggedIn && role != 'user') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: role == 'admin' ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role == 'admin' ? 'ADMIN' : 'TECH',
                  style: TextStyle(
                    color: role == 'admin' ? Colors.red.shade700 : Colors.orange.shade700,
                    fontSize: 9, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: isMobile
          ? [
              if (isLoggedIn)
                IconButton(
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red, size: 22),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]
          : [
              // USER nav
              if (isLoggedIn && role == 'user') ...[
                _navItem(context, 'Home', '/home'),
                _navItem(context, 'My Requests', '/user_requests'),
                _navItem(context, 'Repair guides', '/repair'),
                _navItem(context, 'Find Tech', '/technician_support'),
              ],
              // TECHNICIAN nav — only their dashboard
              if (isLoggedIn && role == 'technician') ...[
                _navItem(context, 'My Dashboard', '/technician_profile'),
              ],
              // ADMIN nav
              if (isLoggedIn && role == 'admin') ...[
                _navItem(context, 'Dashboard', '/admin_dashboard'),
                _navItem(context, 'Users', '/admin_users'),
                _navItem(context, 'Technicians', '/admin_technicians'),
                _navItem(context, 'Feedback', '/admin_feedback'),
              ],
              // Not logged in
              if (!isLoggedIn)
                _navItem(context, 'Repair', '/repair'),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: isLoggedIn
                    ? ElevatedButton.icon(
                        onPressed: () async {
                          await authProvider.signOut();
                          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Logout', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0061FF), foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Login'),
                      ),
              ),
              const SizedBox(width: 12),
            ],
    );
  }

  Widget _navItem(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, route),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black87,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          child: Text(title),
        ),
      ),
    );
  }
}