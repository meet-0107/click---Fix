import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';

class TechnicianSupportPage extends StatefulWidget {
  const TechnicianSupportPage({super.key});

  @override
  State<TechnicianSupportPage> createState() => _TechnicianSupportPageState();
}

class _TechnicianSupportPageState extends State<TechnicianSupportPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _messageController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedTechId;
  String? _selectedTechName;
  bool _showTechnicians = false;
  
  final MapController _mapController = MapController();
  LatLng? _searchCenter;
  bool _isLoadingMap = false;

  void _searchTechnicians() async {
    if (_pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pincode first'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() {
      _showTechnicians = true;
      _isLoadingMap = true;
    });

    final center = await GeocodingService.getCoordinatesFromPincode(_pincodeController.text.trim());
    if (mounted) {
      setState(() {
        _searchCenter = center;
        _isLoadingMap = false;
      });
      if (center != null) {
        // We move the map once the widget is built. 
        // Using addPostFrameCallback ensures the map layout is complete.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(center, 13.0);
          } catch (e) {
            // Controller might not be ready on first build
          }
        });
      }
    }
  }

  void _submitRequest(String appliance, String issue) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedTechId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a technician'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your issue'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _firestoreService.createServiceRequest({
        'userId': authProvider.user!.uid,
        'userName': authProvider.user!.displayName ?? 'User',
        'userEmail': authProvider.user!.email ?? '',
        'appliance': appliance,
        'issue': issue,
        'message': _messageController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'technicianId': _selectedTechId!,
        'technicianName': _selectedTechName ?? '',
      });
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text("Request Sent!", textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'Your request has been sent to $_selectedTechName. They will accept or respond soon.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text("Back to Home"),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, String>?) ??
        {'appliance': 'Device', 'issue': 'General Issue'};
    final appliance = args['appliance']!;
    final issue = args['issue']!;
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: NavigationBarWidget(),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.engineering, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text('Find a Technician', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('$appliance — $issue', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // STEP 1: Enter Pincode
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.blue.shade100,
                              child: const Text('1', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            const Text('Enter Your Pincode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter pincode to find nearby technicians',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: IconButton(
                              onPressed: _searchTechnicians,
                              icon: const Icon(Icons.search, color: Color(0xFF0061FF)),
                            ),
                          ),
                          onSubmitted: (_) => _searchTechnicians(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _searchTechnicians,
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Search Technicians'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0061FF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // STEP 2: Select Technician
                if (_showTechnicians) ...[
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue.shade100,
                                child: const Text('2', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Select a Technician', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              Chip(
                                avatar: const Icon(Icons.location_on, size: 14),
                                label: Text('${_pincodeController.text.trim()}', style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.blue.shade50,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Map View
                          if (_isLoadingMap)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_searchCenter != null) ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Ensure we have a strictly positive finite size
                                final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0 
                                    ? constraints.maxWidth 
                                    : 400.0;
                                return Container(
                                  height: 250,
                                  width: width,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _searchCenter!,
                                      initialZoom: 13.0,
                                      interactionOptions: const InteractionOptions(
                                        flags: InteractiveFlag.all,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.clickandfix.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _searchCenter!,
                                            width: 80,
                                            height: 80,
                                            child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Technicians available near this area:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 8),
                          ],
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestoreService.getTechniciansBySpecialtyAndPincode(
                              appliance,
                              _pincodeController.text.trim(),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                              }

                              // Combine with all techs for that pincode (in case specialty doesn't match exactly)
                              final docs = snapshot.data?.docs ?? [];

                              if (docs.isEmpty) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: _firestoreService.getTechniciansByPincode(_pincodeController.text.trim()),
                                  builder: (context, fallbackSnap) {
                                    if (fallbackSnap.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final fallbackDocs = fallbackSnap.data?.docs ?? [];
                                    if (fallbackDocs.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                                        child: const Center(child: Text('No technicians found in this area. Try a different pincode.')),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('No $appliance specialists found, showing all techs in this area:',
                                            style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        ...fallbackDocs.map((doc) => _buildTechCard(doc.id, doc.data() as Map<String, dynamic>)),
                                      ],
                                    );
                                  },
                                );
                              }

                              return Column(
                                children: docs.map((doc) => _buildTechCard(doc.id, doc.data() as Map<String, dynamic>)).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // STEP 3: Write message and submit
                if (_selectedTechId != null) ...[
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.green.shade100,
                                child: const Text('3', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              const Text('Send Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text('To: $_selectedTechName', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Describe your issue in detail',
                              hintText: 'E.g., My TV is not turning on since yesterday. Tried changing the power outlet but didn\'t work...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : () => _submitRequest(appliance, issue),
                              icon: _isSubmitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send),
                              label: Text(_isSubmitting ? 'Sending...' : 'Send Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechCard(String techId, Map<String, dynamic> data) {
    final isAvailable = data['isAvailable'] ?? false;
    final isSelected = _selectedTechId == techId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.person, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Technician', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (data['specialty'] != null && data['specialty'].toString().isNotEmpty)
                        Text(data['specialty'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Busy',
                    style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (data['pincode'] != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[400], size: 14),
                          Text(' ${data['pincode']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    if (data['phone'] != null && data['phone'].toString().isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, color: Colors.grey[400], size: 14),
                          Text(' ${data['phone']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: isAvailable
                        ? () => setState(() {
                              _selectedTechId = techId;
                              _selectedTechName = data['name'] ?? 'Technician';
                            })
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.green : const Color(0xFF0061FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isSelected ? '✓ Selected' : 'Select', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}