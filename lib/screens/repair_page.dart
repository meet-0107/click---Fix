import 'package:flutter/material.dart';
import '../models/appliance_issues.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  _RepairPageState createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  // Now using Objects instead of just Strings
  DeviceCategory? selectedCategory;
  RepairIssue? selectedIssue;

  @override
  Widget build(BuildContext context) {
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
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              children: [
                const Icon(Icons.build_circle_outlined, size: 80, color: Color(0xFF0061FF)),
                const SizedBox(height: 20),
                const Text(
                  'Diagnose Your Device',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Expert troubleshooting for your home appliances.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Main Selection Card
                Card(
                  elevation: 8,
                  shadowColor: Colors.black12,
                  surfaceTintColor: Colors.white,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- STEP 1: APPLIANCE ---
                        const Text("1. Select your appliance",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<DeviceCategory>(
                          isExpanded: true,   //changes happen here
                          decoration: _inputDecoration(selectedCategory?.icon ?? Icons.devices),
                          hint: const Text('Choose Device (TV, AC, etc.)'),
                          value: selectedCategory,
                          onChanged: (DeviceCategory? newValue) {
                            setState(() {
                              selectedCategory = newValue;
                              selectedIssue = null; // Reset issue when appliance changes
                            });
                          },
                          // Mapping the List of Objects to DropdownMenuItems
                          items: RepairData.categories.map((category) {
                            return DropdownMenuItem<DeviceCategory>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // --- STEP 2: ISSUE (Conditional) ---
                        if (selectedCategory != null) ...[
                          const Text("2. What is the problem?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<RepairIssue>(
                            isExpanded: true,  //changes happen here
                            decoration: _inputDecoration(Icons.report_problem_outlined),
                            hint: const Text('Select the issue'),
                            value: selectedIssue,
                            onChanged: (RepairIssue? newValue) {
                              setState(() => selectedIssue = newValue);
                            },
                            // Mapping the sub-list of issues based on selected Category
                            items: selectedCategory!.commonIssues.map((issue) {
                              return DropdownMenuItem<RepairIssue>(
                                value: issue,
                                child: Text(issue.title),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 40),

                        // --- ACTION BUTTONS ---
                        if (selectedIssue != null)
                          Column(
                            children: [
                              _buildActionButton(
                                label: 'View Self-Repair Guide',
                                color: const Color(0xFF0061FF),
                                isOutlined: false,
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/self_repair_guide',
                                  arguments: {
                                    'appliance': selectedCategory!.name,
                                    'issue': selectedIssue!.title,
                                    'steps': selectedIssue!.diySteps, // Pass steps directly!
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              _buildActionButton(
                                label: 'Find a Nearby Technician',
                                color: Colors.orange,
                                isOutlined: true,
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/technician_support',
                                  arguments: {
                                    'appliance': selectedCategory!.name,
                                    'issue': selectedIssue!.title,
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildActionButton({required String label, required Color color, required bool isOutlined, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      )
          : ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF0061FF)),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }
}