import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../models/appliance_issues.dart';
import '../services/llm_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';

class AiDiagnosticPage extends StatefulWidget {
  const AiDiagnosticPage({super.key});

  @override
  State<AiDiagnosticPage> createState() => _AiDiagnosticPageState();
}

class _AiDiagnosticPageState extends State<AiDiagnosticPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String _loadingMessage = "";
  String? _errorMessage;
  Map<String, dynamic>? _diagnosisResult;

  // Matching local data
  DeviceCategory? _matchedCategory;
  RepairIssue? _matchedIssue;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _errorMessage = null;
        _diagnosisResult = null;
        _matchedCategory = null;
        _matchedIssue = null;
      });

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to select image: $e";
      });
    }
  }

  Future<void> _runDiagnosis() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _diagnosisResult = null;
      _loadingMessage = "Uploading image...";
    });

    // Animate loading messages
    final messages = [
      "Uploading image...",
      "Analyzing control panel components...",
      "Detecting model and error codes...",
      "Matching with repair manuals...",
      "Preparing final instructions..."
    ];

    int messageIndex = 0;
    final loadingTimer = Stream.periodic(const Duration(milliseconds: 1800), (i) => i).listen((i) {
      if (mounted && _isLoading && messageIndex < messages.length - 1) {
        setState(() {
          messageIndex++;
          _loadingMessage = messages[messageIndex];
        });
      }
    });

    try {
      final result = await LlmService.diagnoseImage(_selectedImage!);
      
      // Perform local database matching
      final String applianceText = (result['appliance'] ?? '').toString().toLowerCase();
      final String issueText = (result['issue'] ?? '').toString().toLowerCase();

      DeviceCategory? matchedCat;
      RepairIssue? matchedIss;

      for (final cat in RepairData.categories) {
        if (applianceText.contains(cat.name.toLowerCase()) || cat.name.toLowerCase().contains(applianceText)) {
          matchedCat = cat;
          for (final issue in cat.commonIssues) {
            if (issueText.contains(issue.title.toLowerCase()) || issue.title.toLowerCase().contains(issueText)) {
              matchedIss = issue;
              break;
            }
          }
          break;
        }
      }

      setState(() {
        _diagnosisResult = result;
        _matchedCategory = matchedCat;
        _matchedIssue = matchedIss;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Diagnosis failed. Please check your network or LLM API configuration.\nDetails: $e";
        _isLoading = false;
      });
    } finally {
      loadingTimer.cancel();
    }
  }



  @override
  Widget build(BuildContext context) {
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
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "AI Diagnostics",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 48), // Symmetrical spacer to center the title
                  ],
                ),
                const SizedBox(height: 24),

                // Main diagnostic panel
                if (!_isLoading && _diagnosisResult == null) _buildImageSelectionCard(),
                if (_isLoading) _buildLoadingCard(),
                if (_diagnosisResult != null) _buildDiagnosisResultCard(),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 72, color: Color(0xFF0061FF))
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 2.seconds, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            const Text(
              "Diagnose Appliance in Seconds",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Take a picture of the appliance, control panel, or any display showing an error code. Our AI will identify the model and formulate a repair guide.",
              style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Image Preview or Placeholder
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Text(
                        "No photo selected",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("Gallery"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF0061FF)),
                      foregroundColor: const Color(0xFF0061FF),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0061FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            if (_imageBytes != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runDiagnosis,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text("Start AI Diagnosis"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ).animate().scale(delay: 100.ms),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: Color(0xFF0061FF),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .rotate(duration: 2.seconds),
            const SizedBox(height: 32),
            Text(
              _loadingMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Our vision intelligence engine is diagnosing the photo. This takes around 5-10 seconds.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisResultCard() {
    if (_diagnosisResult == null) return const SizedBox();

    final appliance = _diagnosisResult!['appliance'] ?? 'Unknown Appliance';
    final issue = _diagnosisResult!['issue'] ?? 'Unknown Issue';
    final errorCode = _diagnosisResult!['errorCode'] ?? 'None';
    final summary = _diagnosisResult!['summary'] ?? '';
    final confidence = _diagnosisResult!['confidence'] ?? 1.0;
    final customSteps = List<String>.from(_diagnosisResult!['customDiySteps'] ?? []);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Appliance + Confidence
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appliance.toString().toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0061FF)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    "${(confidence * 100).toInt()}% Match",
                    style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Error code (if any)
            if (errorCode != 'None' && errorCode != '') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      "Error Code Detected: ",
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      errorCode,
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              "Diagnosis Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_matchedCategory != null && _matchedIssue != null) {
                        Navigator.pushNamed(context, '/self_repair_guide', arguments: {
                          'appliance': _matchedCategory!.name,
                          'issue': _matchedIssue!.title,
                          'steps': _matchedIssue!.diySteps,
                        });
                      } else {
                        // Custom Dynamic Guide
                        Navigator.pushNamed(context, '/self_repair_guide', arguments: {
                          'appliance': appliance,
                          'issue': issue,
                          'steps': customSteps.isNotEmpty ? customSteps : ['Please consult a professional.'],
                        });
                      }
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text("View Repair Guide"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0061FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/technician_support', arguments: {
                        'appliance': appliance,
                        'issue': issue,
                      });
                    },
                    icon: const Icon(Icons.engineering_outlined),
                    label: const Text("Request Pro Support"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.orange, width: 2),
                      foregroundColor: Colors.orange.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _imageBytes = null;
                    _diagnosisResult = null;
                    _matchedCategory = null;
                    _matchedIssue = null;
                  });
                },
                child: const Text("Diagnose another appliance"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Math min implementation to avoid importing dart:math just for one use
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
