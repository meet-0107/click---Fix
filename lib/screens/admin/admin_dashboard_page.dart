import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_bar.dart';
import '../../widgets/app_drawer.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: NavigationBarWidget(),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard', style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Manage your platform from one place.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 24),

                // Stats
                StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getAllUsers(),
                  builder: (context, usersSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: firestoreService.getAllFeedback(),
                      builder: (context, feedbackSnap) {
                        final userCount = usersSnap.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['role'] == 'user').length ?? 0;
                        final techCount = usersSnap.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['role'] == 'technician').length ?? 0;
                        final feedbackCount = feedbackSnap.data?.docs.length ?? 0;

                        if (isMobile) {
                          return Column(
                            children: [
                              Row(children: [
                                Expanded(child: _buildStatCard('Users', '$userCount', Icons.people, Colors.blue, true)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard('Techs', '$techCount', Icons.engineering, Colors.orange, true)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: _buildStatCard('Reviews', '$feedbackCount', Icons.rate_review, Colors.purple, true)),
                              ]),
                            ],
                          );
                        }
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildStatCard('Total Users', '$userCount', Icons.people, Colors.blue, false),
                            _buildStatCard('Technicians', '$techCount', Icons.engineering, Colors.orange, false),
                            _buildStatCard('Feedback', '$feedbackCount', Icons.rate_review, Colors.purple, false),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),
                Text('Quick Actions', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (isMobile)
                  Column(
                    children: [
                      _buildActionTile(context, 'Manage Users', Icons.people_outline, '/admin_users', Colors.blue),
                      _buildActionTile(context, 'Manage Technicians', Icons.engineering_outlined, '/admin_technicians', Colors.orange),
                      _buildActionTile(context, 'View Feedback', Icons.feedback_outlined, '/admin_feedback', Colors.purple),
                    ],
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildActionCard(context, 'Manage Users', Icons.people_outline, '/admin_users', Colors.blue),
                      _buildActionCard(context, 'Manage Technicians', Icons.engineering_outlined, '/admin_technicians', Colors.orange),
                      _buildActionCard(context, 'View Feedback', Icons.feedback_outlined, '/admin_feedback', Colors.purple),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool compact) {
    return Container(
      width: compact ? null : 240,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 8 : 12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: compact ? 22 : 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: compact ? 12 : 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String route, Color color) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, String route, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.pushNamed(context, route),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ),
    );
  }
}
