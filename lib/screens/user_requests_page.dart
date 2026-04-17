import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';

class UserRequestsPage extends StatelessWidget {
  const UserRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isMobile = MediaQuery.of(context).size.width < 1000;
    final firestoreService = FirestoreService();

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
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Service Requests', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Track the status of your repair requests', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 24),

                if (user == null)
                  const Center(child: Text('Please log in to view your requests.'))
                else
                  StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getRequestsForUser(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No requests found', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/repair'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0061FF), foregroundColor: Colors.white),
                                child: const Text('Find a Technician'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'pending';
                          final techName = data['technicianName'] ?? 'Technician';
                          final techId = data['technicianId'] ?? '';
                          final appliance = data['appliance'] ?? '';
                          final issue = data['issue'] ?? '';
                          final message = data['message'] ?? '';

                          Color statusColor = Colors.orange;
                          String statusText = 'Pending';
                          IconData statusIcon = Icons.pending_actions;

                          if (status == 'accepted') {
                            statusColor = Colors.blue;
                            statusText = 'Accepted';
                            statusIcon = Icons.handyman;
                          } else if (status == 'completed') {
                            statusColor = Colors.green;
                            statusText = 'Completed';
                            statusIcon = Icons.done_all;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: statusColor.withOpacity(0.1),
                                        child: Icon(statusIcon, color: statusColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(appliance.isNotEmpty ? appliance : 'Repair Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('Technician: $techName', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(statusText.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Visual Tracking Timeline
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildTimelineStep('Pending', Icons.schedule, status == 'pending' || status == 'accepted' || status == 'completed', Colors.orange),
                                      _buildTimelineLine(status == 'accepted' || status == 'completed'),
                                      _buildTimelineStep('Accepted', Icons.handyman, status == 'accepted' || status == 'completed', Colors.blue),
                                      _buildTimelineLine(status == 'completed'),
                                      _buildTimelineStep('Completed', Icons.done_all, status == 'completed', Colors.green),
                                    ],
                                  ),
                                  
                                  if (issue.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text('Issue: $issue', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 4),
                                  ],
                                  if (message.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(top: 8),
                                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                                      child: Text(message, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                                    ),
                                  
                                  // Show 'Leave Review' only if completed
                                  if (status == 'completed') ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/feedback_rating', arguments: {
                                            'technicianId': techId,
                                            'technicianName': techName,
                                          });
                                        },
                                        icon: const Icon(Icons.star_outline, color: Colors.amber),
                                        label: const Text('Leave a Review', style: TextStyle(color: Colors.blue)),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.blue.shade200),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String label, IconData icon, bool isActive, Color activeColor) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isActive ? activeColor.withOpacity(0.15) : Colors.grey.shade100,
            child: Icon(icon, size: 16, color: isActive ? activeColor : Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? activeColor : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Expanded(
      flex: 2,
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
        color: isActive ? Colors.grey.shade400 : Colors.grey.shade200,
      ),
    );
  }
}
