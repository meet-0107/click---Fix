import 'package:flutter/material.dart';

class RepairIssue {
  final String id;
  final String title;
  final List<String> diySteps;

  const RepairIssue({
    required this.id,
    required this.title,
    required this.diySteps,
  });
}

class DeviceCategory {
  final String name;
  final IconData icon;
  final List<RepairIssue> commonIssues;

  const DeviceCategory({
    required this.name,
    required this.icon,
    required this.commonIssues,
  });
}

class RepairData {
  static List<DeviceCategory> categories = [
    // --- TV ---
    DeviceCategory(
      name: 'TV',
      icon: Icons.tv,
      commonIssues: [
        RepairIssue(
          id: 'tv_pwr',
          title: 'No power',
          diySteps: ['Check if power cord is loose.', 'Try a different wall outlet.', 'Hold power button for 30s while unplugged.'],
        ),
        RepairIssue(
          id: 'tv_disp',
          title: 'No display',
          diySteps: ['Check HDMI cable connections.', 'Ensure correct Input/Source is selected.', 'Test with another device (console/laptop).'],
        ),
      ],
    ),

    // --- LAPTOP ---
    DeviceCategory(
      name: 'Laptop',
      icon: Icons.laptop,
      commonIssues: [
        RepairIssue(
          id: 'lp_heat',
          title: 'Overheating',
          diySteps: ['Clear dust from vents with compressed air.', 'Use on a hard, flat surface.', 'Check for high CPU usage in Task Manager.'],
        ),
        RepairIssue(
          id: 'lp_bat',
          title: 'Battery not charging',
          diySteps: ['Inspect charging port for debris.', 'Check for cable frays.', 'Reset battery drivers in Device Manager.'],
        ),
      ],
    ),

    // --- MOBILE ---
    DeviceCategory(
      name: 'Mobile',
      icon: Icons.smartphone,
      commonIssues: [
        RepairIssue(
          id: 'mb_scr',
          title: 'Screen flickering',
          diySteps: ['Disable Adaptive Brightness.', 'Check for software updates.', 'Perform a hard restart.'],
        ),
        RepairIssue(
          id: 'mb_chg',
          title: 'Slow charging',
          diySteps: ['Clean the USB port with a toothpick.', 'Try a different charging brick.', 'Avoid using the phone while charging.'],
        ),
      ],
    ),

    // --- AIR CONDITIONER (AC) ---
    DeviceCategory(
      name: 'AC',
      icon: Icons.ac_unit,
      commonIssues: [
        RepairIssue(
          id: 'ac_cool',
          title: 'Not cooling',
          diySteps: ['Clean or replace air filters.', 'Check if outdoor unit is obstructed.', 'Set thermostat to Cool mode at 24°C.'],
        ),
        RepairIssue(
          id: 'ac_leak',
          title: 'Water leakage',
          diySteps: ['Check for blocked drain pipe.', 'Ensure the unit is tilted slightly backwards.', 'Inspect for ice buildup on coils.'],
        ),
      ],
    ),

    // --- WASHING MACHINE ---
    DeviceCategory(
      name: 'Washing Machine',
      icon: Icons.local_laundry_service,
      commonIssues: [
        RepairIssue(
          id: 'wm_drain',
          title: 'Not draining',
          diySteps: ['Inspect drain hose for kinks.', 'Clean the drain pump filter.', 'Ensure the lid is closed properly.'],
        ),
        RepairIssue(
          id: 'wm_spin',
          title: 'Not spinning',
          diySteps: ['Distribute the load evenly.', 'Check for a snapped drive belt.', 'Ensure the machine is level on the floor.'],
        ),
      ],
    ),

    // --- FAN ---
    DeviceCategory(
      name: 'Fan',
      icon: Icons.wind_power,
      commonIssues: [
        RepairIssue(
          id: 'fn_slow',
          title: 'Slow rotation',
          diySteps: ['Clean dust from blades and motor.', 'Apply lubricant to the motor shaft.', 'Check for a faulty capacitor.'],
        ),
        RepairIssue(
          id: 'fn_noise',
          title: 'Squeaking noise',
          diySteps: ['Tighten loose screws on the grill.', 'Check for imbalanced blades.', 'Oil the bearings.'],
        ),
      ],
    ),

    // --- REMOTE ---
    DeviceCategory(
      name: 'Remote',
      icon: Icons.settings_remote,
      commonIssues: [
        RepairIssue(
          id: 'rm_keys',
          title: 'Buttons not responding',
          diySteps: ['Replace batteries with new ones.', 'Clean contacts inside the battery compartment.', 'Check IR signal through a phone camera.'],
        ),
      ],
    ),
  ];
}