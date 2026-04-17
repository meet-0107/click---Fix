import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_bar.dart';

class ManageTechniciansPage extends StatelessWidget {
  const ManageTechniciansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isMobile = MediaQuery.of(context).size.width < 700;

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
            padding: const EdgeInsets.all(24),
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
                    const Expanded(
                      child: Text(
                        'Manage Technicians',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// STREAM BUILDER
                StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getTechnicians(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.engineering_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No technicians registered yet.',
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data =
                        doc.data() as Map<String, dynamic>;
                        final isAvailable =
                            data['isAvailable'] ?? false;

                        return Card(
                          margin:
                          const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding:
                            const EdgeInsets.all(16),
                            child: isMobile
                                ? _buildMobileLayout(
                              context,
                              data,
                              doc.id,
                              firestoreService,
                              isAvailable,
                            )
                                : _buildDesktopLayout(
                              context,
                              data,
                              doc.id,
                              firestoreService,
                              isAvailable,
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

  /// ---------------- DESKTOP LAYOUT ----------------
  Widget _buildDesktopLayout(
      BuildContext context,
      Map<String, dynamic> data,
      String docId,
      FirestoreService firestoreService,
      bool isAvailable,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.orange.shade50,
          child: Icon(Icons.engineering,
              color: Colors.orange.shade700, size: 28),
        ),
        const SizedBox(width: 16),

        /// TEXT SECTION
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                data['name'] ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                data['email'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13),
              ),
              const SizedBox(height: 6),
              _buildChips(data, isAvailable),
            ],
          ),
        ),

        const SizedBox(width: 12),

        /// DELETE BUTTON
        SizedBox(
          width: 40,
          child: IconButton(
            onPressed: () => _showDeleteDialog(
                context, data, docId, firestoreService),
            icon: const Icon(Icons.delete_outline,
                color: Colors.red),
          ),
        ),
      ],
    );
  }

  /// ---------------- MOBILE LAYOUT ----------------
  Widget _buildMobileLayout(
      BuildContext context,
      Map<String, dynamic> data,
      String docId,
      FirestoreService firestoreService,
      bool isAvailable,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
              Colors.orange.shade50,
              child: Icon(Icons.engineering,
                  color: Colors.orange.shade700,
                  size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data['name'] ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight:
                    FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => _showDeleteDialog(
                  context, data, docId,
                  firestoreService),
              icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          data['email'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
          TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        _buildChips(data, isAvailable),
      ],
    );
  }

  /// ---------------- CHIPS ----------------
  Widget _buildChips(
      Map<String, dynamic> data,
      bool isAvailable) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (data['specialty'] != null &&
            data['specialty']
                .toString()
                .isNotEmpty)
          Chip(
            label: Text(
              data['specialty'],
              overflow: TextOverflow.ellipsis,
            ),
            visualDensity:
            VisualDensity.compact,
          ),
        if (data['pincode'] != null &&
            data['pincode']
                .toString()
                .isNotEmpty)
          Chip(
            label: Text(
              data['pincode'],
              overflow: TextOverflow.ellipsis,
            ),
            visualDensity:
            VisualDensity.compact,
          ),
        Chip(
          label: Text(
              isAvailable
                  ? 'Available'
                  : 'Unavailable'),
          backgroundColor: isAvailable
              ? Colors.green.shade50
              : Colors.red.shade50,
          visualDensity:
          VisualDensity.compact,
        ),
      ],
    );
  }

  /// ---------------- DELETE DIALOG ----------------
  void _showDeleteDialog(
      BuildContext context,
      Map<String, dynamic> data,
      String docId,
      FirestoreService firestoreService,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16)),
        title: const Text(
            'Remove Technician'),
        content: Text(
            'Remove "${data['name']}" from the platform?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await firestoreService
                  .deleteUser(docId);
              if (ctx.mounted)
                Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor:
              Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}