// // Model for technician (dummy data)
// class Technician {
//   final String name;
//   final double rating;
//   final String contact;
//
//   Technician({required this.name, required this.rating, required this.contact});
// }
//
// // Dummy technicians list
// List<Technician> dummyTechnicians = [
//   Technician(name: 'John Doe', rating: 4.5, contact: '+1234567890'),
//   Technician(name: 'Jane Smith', rating: 4.8, contact: '+0987654321'),
//   Technician(name: 'Mike Johnson', rating: 4.2, contact: '+1122334455'),
// ];

import 'package:flutter/material.dart';

enum RepairDifficulty { easy, medium, hard, professionalOnly }

class RepairIssue {
  final String id;
  final String title;
  final List<String> diySteps;
  final List<String> requiredTools;
  final RepairDifficulty difficulty;
  final String estimatedTime;
  final String? safetyWarning;

  const RepairIssue({
    required this.id,
    required this.title,
    required this.diySteps,
    this.requiredTools = const ['Standard Screwdriver'],
    this.difficulty = RepairDifficulty.easy,
    this.estimatedTime = '15-30 mins',
    this.safetyWarning,
  });
}

class DeviceCategory {
  final String name;
  final IconData icon;
  final String description;
  final List<RepairIssue> commonIssues;

  const DeviceCategory({
    required this.name,
    required this.icon,
    required this.description,
    required this.commonIssues,
  });
}

class RepairData {
  static List<DeviceCategory> categories = [
    // --- WASHING MACHINE ---
    DeviceCategory(
      name: 'Washing Machine',
      icon: Icons.local_laundry_service,
      description: 'Front load, top load, and semi-automatic units.',
      commonIssues: [
        RepairIssue(
          id: 'wm_drain',
          title: 'Water Not Draining',
          difficulty: RepairDifficulty.medium,
          estimatedTime: '45 mins',
          requiredTools: ['Pliers', 'Bucket', 'Flashlight'],
          safetyWarning: 'Ensure the machine is unplugged and water inlet is closed.',
          diySteps: [
            'Locate the drain pump filter at the bottom front.',
            'Place a bucket to catch excess water.',
            'Unscrew filter and remove debris (coins, lint).',
            'Check the drain hose for kinks or blockages.',
          ],
        ),
      ],
    ),

    // --- AIR CONDITIONER ---
    DeviceCategory(
      name: 'AC',
      icon: Icons.ac_unit,
      description: 'Split and Window AC maintenance.',
      commonIssues: [
        RepairIssue(
          id: 'ac_cool',
          title: 'Not Cooling Enough',
          difficulty: RepairDifficulty.easy,
          estimatedTime: '20 mins',
          requiredTools: ['Water spray', 'Soft brush'],
          diySteps: [
            'Open the front panel and remove air filters.',
            'Wash filters under running water and dry completely.',
            'Use a brush to gently clean the evaporator coils.',
            'Check if the outdoor unit fan is spinning freely.',
          ],
        ),
      ],
    ),

    // --- LAPTOP ---
    DeviceCategory(
      name: 'Laptop',
      icon: Icons.laptop,
      description: 'Software issues, hardware upgrades, and cleaning.',
      commonIssues: [
        RepairIssue(
          id: 'lp_slow',
          title: 'Slow Performance / Lag',
          difficulty: RepairDifficulty.easy,
          estimatedTime: '30 mins',
          requiredTools: ['Software Only'],
          diySteps: [
            'Open Task Manager and disable high-impact startup apps.',
            'Check for pending Windows/macOS updates.',
            'Run a Disk Cleanup to remove temporary files.',
            'Verify if the hard drive is more than 90% full.',
          ],
        ),
      ],
    ),
  ];
}