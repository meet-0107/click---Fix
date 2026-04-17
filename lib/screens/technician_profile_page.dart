import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({super.key});

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isAvailable = true;
  bool _isEditing = false;
  bool _isSaving = false;
  int _selectedTab = 0; // 0=pending, 1=accepted, 2=completed

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final data = authProvider.userData;
    if (data != null) {
      _specialtyController.text = data['specialty'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _pincodeController.text = data['pincode'] ?? '';
      _isAvailable = data['isAvailable'] ?? true;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await _firestoreService.updateTechnicianProfile(
        authProvider.user!.uid,
        specialty: _specialtyController.text.trim(),
        phone: _phoneController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isAvailable: _isAvailable,
      );
      if (mounted) {
        setState(() { _isEditing = false; _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
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
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Technician Header
                Text('Technician Dashboard', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Manage your profile and service requests', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 20),

                // Profile Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 24 : 30,
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(Icons.engineering, size: isMobile ? 24 : 32, color: Colors.orange.shade800),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user?.displayName ?? 'Technician',
                                      style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold)),
                                  Text(user?.email ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isAvailable ? '● Online' : '● Offline',
                                style: TextStyle(color: _isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quick info chips
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [
                            if (_specialtyController.text.isNotEmpty)
                              Chip(avatar: const Icon(Icons.build, size: 16), label: Text(_specialtyController.text, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                            if (_pincodeController.text.isNotEmpty)
                              Chip(avatar: const Icon(Icons.location_on, size: 16), label: Text(_pincodeController.text, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                            if (_phoneController.text.isNotEmpty)
                              Chip(avatar: const Icon(Icons.phone, size: 16), label: Text(_phoneController.text, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditing = !_isEditing),
                            icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 16),
                            label: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                          ),
                        ),
                        // Edit form
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          TextFormField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialty (e.g., TV Repair, AC Repair)', prefixIcon: Icon(Icons.build))),
                          const SizedBox(height: 10),
                          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
                          const SizedBox(height: 10),
                          TextFormField(controller: _pincodeController, decoration: const InputDecoration(labelText: 'Service Pincode', prefixIcon: Icon(Icons.location_on))),
                          SwitchListTile(
                            title: const Text('Available for jobs'),
                            value: _isAvailable,
                            activeColor: Colors.green,
                            onChanged: (val) => setState(() => _isAvailable = val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          SizedBox(
                            width: double.infinity, height: 44,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                              child: _isSaving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Request Tabs
                const Text('Service Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Pending'), icon: Icon(Icons.pending_actions, size: 18)),
                      ButtonSegment(value: 1, label: Text('Accepted'), icon: Icon(Icons.check_circle_outline, size: 18)),
                      ButtonSegment(value: 2, label: Text('Finished'), icon: Icon(Icons.done_all, size: 18)),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
                  ),
                ),
                const SizedBox(height: 16),

                // Request list based on tab
                if (_selectedTab == 0)
                  _buildRequestList(
                    user != null ? _firestoreService.getRequestsForTechnicianByStatus(user.uid, 'pending') : null,
                    'pending',
                    user?.uid,
                  ),
                if (_selectedTab == 1)
                  _buildRequestList(
                    user != null ? _firestoreService.getRequestsForTechnicianByStatus(user.uid, 'accepted') : null,
                    'accepted',
                    user?.uid,
                  ),
                if (_selectedTab == 2)
                  _buildRequestList(
                    user != null ? _firestoreService.getRequestsForTechnicianByStatus(user.uid, 'completed') : null,
                    'completed',
                    user?.uid,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(Stream<QuerySnapshot>? stream, String statusFilter, String? techId) {
    if (stream == null) return const Center(child: Text('Please login'));

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty(statusFilter);
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            return _buildRequestCard(doc.id, doc.data() as Map<String, dynamic>, statusFilter, techId);
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmpty(String status) {
    final icons = {'pending': Icons.pending_actions, 'accepted': Icons.check_circle_outline, 'completed': Icons.done_all};
    return Container(
      padding: const EdgeInsets.all(32), width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icons[status] ?? Icons.inbox, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('No $status requests', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String id, Map<String, dynamic> data, String status, String? techId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.person, color: Colors.blue.shade700, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['userName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${data['appliance'] ?? ''} — ${data['issue'] ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                if (data['pincode'] != null && data['pincode'].toString().isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.location_on, size: 14),
                    label: Text(data['pincode'], style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (data['message'] != null && data['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Message:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(data['message'], style: const TextStyle(fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Action buttons
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _firestoreService.updateRequestStatus(id, 'accepted', technicianId: techId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request accepted!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (status == 'accepted')
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _firestoreService.updateRequestStatus(id, 'completed');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked as finished!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark Finished'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (status == 'completed')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 6),
                    Text('Completed', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
