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

  final TextEditingController _customApplianceController = TextEditingController();
  final TextEditingController _customProblemController = TextEditingController();

  @override
  void dispose() {
    _customApplianceController.dispose();
    _customProblemController.dispose();
    super.dispose();
  }

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

                // AI Diagnostic Banner
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/ai_diagnostic'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0061FF), Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0061FF).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology_outlined, color: Colors.white, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Try Visual Diagnostics",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Take a picture of the control panel or error screen to diagnose instantly.",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                        const Text("1. Enter your appliance",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customApplianceController,
                          decoration: _inputDecoration(Icons.devices).copyWith(
                            hintText: "e.g., Refrigerator, Washing Machine, Microwave",
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text("2. Describe the issue",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customProblemController,
                          decoration: _inputDecoration(Icons.report_problem_outlined).copyWith(
                            hintText: "e.g., Not cooling, Leaking water, Not turning on",
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // --- ACTION BUTTONS ---
                        _buildActionButton(
                          label: 'View Self-Repair Guide',
                          color: const Color(0xFF0061FF),
                          isOutlined: false,
                          onPressed: () {
                            final appliance = _customApplianceController.text.trim();
                            final problem = _customProblemController.text.trim();
                            if (appliance.isEmpty || problem.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter both appliance and problem'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            Navigator.pushNamed(
                              context,
                              '/self_repair_guide',
                              arguments: {
                                'appliance': appliance,
                                'issue': problem,
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Center(child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          label: 'Find a Nearby Technician',
                          color: Colors.orange,
                          isOutlined: true,
                          onPressed: () {
                            final appliance = _customApplianceController.text.trim();
                            final problem = _customProblemController.text.trim();
                            if (appliance.isEmpty || problem.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter both appliance and problem'), backgroundColor: Colors.orange),
                                );
                              return;
                            }
                            Navigator.pushNamed(
                              context,
                              '/technician_support',
                              arguments: {
                                'appliance': appliance,
                                'issue': problem,
                              },
                            );
                          },
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