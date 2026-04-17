import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_bar.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: NavigationBarWidget(),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    const Text('Manage Users', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final role = data['role'] ?? 'user';
                          final roleColor = role == 'admin'
                              ? Colors.red
                              : role == 'technician'
                                  ? Colors.orange
                                  : Colors.blue;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.1),
                              child: Icon(
                                role == 'technician' ? Icons.engineering : role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                color: roleColor,
                              ),
                            ),
                            title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['email'] ?? ''),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            trailing: role != 'admin'
                                ? IconButton(
                                    onPressed: () => _confirmDelete(context, firestoreService, doc.id, data['name'] ?? 'User'),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Delete user',
                                  )
                                : null,
                          );
                        }).toList(),
                      ),
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

  void _confirmDelete(BuildContext context, FirestoreService service, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await service.deleteUser(uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
