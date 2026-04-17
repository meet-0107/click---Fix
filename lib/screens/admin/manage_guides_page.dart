import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_bar.dart';

class ManageGuidesPage extends StatefulWidget {
  const ManageGuidesPage({super.key});

  @override
  State<ManageGuidesPage> createState() => _ManageGuidesPageState();
}

class _ManageGuidesPageState extends State<ManageGuidesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddEditDialog({String? docId, Map<String, dynamic>? existing}) {
    final categoryCtrl = TextEditingController(text: existing?['category'] ?? '');
    final issueCtrl = TextEditingController(text: existing?['issue'] ?? '');
    final stepsCtrl = TextEditingController(
      text: existing?['steps'] != null ? (existing!['steps'] as List).join('\n') : '',
    );
    final toolsCtrl = TextEditingController(
      text: existing?['tools'] != null ? (existing!['tools'] as List).join(', ') : '',
    );
    final difficultyCtrl = TextEditingController(text: existing?['difficulty'] ?? 'easy');
    final timeCtrl = TextEditingController(text: existing?['estimatedTime'] ?? '15-30 mins');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(docId == null ? 'Add New Guide' : 'Edit Guide'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category (e.g., TV, AC, Fan)')),
                const SizedBox(height: 12),
                TextField(controller: issueCtrl, decoration: const InputDecoration(labelText: 'Issue Title')),
                const SizedBox(height: 12),
                TextField(
                  controller: stepsCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Steps (one per line)', alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                TextField(controller: toolsCtrl, decoration: const InputDecoration(labelText: 'Tools (comma separated)')),
                const SizedBox(height: 12),
                TextField(controller: difficultyCtrl, decoration: const InputDecoration(labelText: 'Difficulty (easy/medium/hard)')),
                const SizedBox(height: 12),
                TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Estimated Time')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final guide = {
                'category': categoryCtrl.text.trim(),
                'issue': issueCtrl.text.trim(),
                'steps': stepsCtrl.text.trim().split('\n').where((s) => s.isNotEmpty).toList(),
                'tools': toolsCtrl.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                'difficulty': difficultyCtrl.text.trim(),
                'estimatedTime': timeCtrl.text.trim(),
              };

              if (docId == null) {
                await _firestoreService.addGuide(guide);
              } else {
                await _firestoreService.updateGuide(docId, guide);
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: Text(docId == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _seedGuides() async {
    final guides = [
      {'category': 'TV', 'issue': 'No power', 'steps': ['Check if power cord is loose.', 'Try a different wall outlet.', 'Hold power button for 30s while unplugged.'], 'tools': ['None'], 'difficulty': 'easy', 'estimatedTime': '10 mins'},
      {'category': 'TV', 'issue': 'No display', 'steps': ['Check HDMI cable connections.', 'Ensure correct Input/Source is selected.', 'Test with another device.'], 'tools': ['HDMI Cable'], 'difficulty': 'easy', 'estimatedTime': '10 mins'},
      {'category': 'AC', 'issue': 'Not cooling', 'steps': ['Clean or replace air filters.', 'Check if outdoor unit is obstructed.', 'Set thermostat to Cool mode at 24°C.'], 'tools': ['Water spray', 'Soft brush'], 'difficulty': 'easy', 'estimatedTime': '20 mins'},
      {'category': 'AC', 'issue': 'Water leakage', 'steps': ['Check for blocked drain pipe.', 'Ensure unit tilted slightly backwards.', 'Inspect for ice buildup on coils.'], 'tools': ['Flashlight'], 'difficulty': 'medium', 'estimatedTime': '30 mins'},
      {'category': 'Fan', 'issue': 'Slow rotation', 'steps': ['Clean dust from blades and motor.', 'Apply lubricant to motor shaft.', 'Check for a faulty capacitor.'], 'tools': ['Screwdriver', 'Lubricant'], 'difficulty': 'medium', 'estimatedTime': '30 mins'},
      {'category': 'Fan', 'issue': 'Squeaking noise', 'steps': ['Tighten loose screws on the grill.', 'Check for imbalanced blades.', 'Oil the bearings.'], 'tools': ['Screwdriver', 'Oil'], 'difficulty': 'easy', 'estimatedTime': '15 mins'},
      {'category': 'Laptop', 'issue': 'Overheating', 'steps': ['Clear dust from vents with compressed air.', 'Use on a hard, flat surface.', 'Check for high CPU usage in Task Manager.'], 'tools': ['Compressed air'], 'difficulty': 'easy', 'estimatedTime': '15 mins'},
      {'category': 'Laptop', 'issue': 'Battery not charging', 'steps': ['Inspect charging port for debris.', 'Check for cable frays.', 'Reset battery drivers in Device Manager.'], 'tools': ['Toothpick', 'Cloth'], 'difficulty': 'easy', 'estimatedTime': '15 mins'},
      {'category': 'Mobile', 'issue': 'Screen flickering', 'steps': ['Disable Adaptive Brightness.', 'Check for software updates.', 'Perform a hard restart.'], 'tools': ['None'], 'difficulty': 'easy', 'estimatedTime': '10 mins'},
      {'category': 'Mobile', 'issue': 'Slow charging', 'steps': ['Clean the USB port with a toothpick.', 'Try a different charging brick.', 'Avoid using phone while charging.'], 'tools': ['Toothpick'], 'difficulty': 'easy', 'estimatedTime': '10 mins'},
      {'category': 'Washing Machine', 'issue': 'Not draining', 'steps': ['Inspect drain hose for kinks.', 'Clean the drain pump filter.', 'Ensure lid is closed properly.'], 'tools': ['Pliers', 'Bucket'], 'difficulty': 'medium', 'estimatedTime': '45 mins'},
      {'category': 'Washing Machine', 'issue': 'Not spinning', 'steps': ['Distribute load evenly.', 'Check for a snapped drive belt.', 'Ensure machine is level on floor.'], 'tools': ['Level tool'], 'difficulty': 'medium', 'estimatedTime': '30 mins'},
      {'category': 'Remote', 'issue': 'Buttons not responding', 'steps': ['Replace batteries with new ones.', 'Clean contacts inside battery compartment.', 'Check IR signal through a phone camera.'], 'tools': ['Batteries', 'Cloth'], 'difficulty': 'easy', 'estimatedTime': '5 mins'},
    ];
    await _firestoreService.seedDefaultGuides(guides);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default guides seeded!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Manage Repair Guides', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                    OutlinedButton.icon(
                      onPressed: _seedGuides,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Seed Defaults'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Guide'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getGuides(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No guides yet. Click "Seed Defaults" to add sample guides.'),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(Icons.menu_book, color: Colors.blue.shade700),
                            ),
                            title: Text('${data['category']} — ${data['issue']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${(data['steps'] as List?)?.length ?? 0} steps • ${data['difficulty'] ?? 'easy'} • ${data['estimatedTime'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showAddEditDialog(docId: doc.id, existing: data),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await _firestoreService.deleteGuide(doc.id);
                                  },
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
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
}
