import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/llm_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';

class SelfRepairGuidePage extends StatefulWidget {
  const SelfRepairGuidePage({super.key});

  @override
  State<SelfRepairGuidePage> createState() => _SelfRepairGuidePageState();
}

class _SelfRepairGuidePageState extends State<SelfRepairGuidePage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isBookmarked = false;
  int _guideRating = 0;
  bool _ratingSubmitted = false;

  String _applianceName = '';
  String _issueTitle = '';
  List<String> _steps = [];
  bool _isGenerating = false;
  String? _generationError;
  bool _isInitialLoad = true;

  // Track which step visualizer is active
  int? _activeStepVisualizerIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _applianceName = args['appliance'] ?? '';
        _issueTitle = args['issue'] ?? '';
        
        if (_applianceName.isNotEmpty && _issueTitle.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _generateGuide();
          });
        }
      }
      _isInitialLoad = false;
    }
  }

  void _checkBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && _applianceName.isNotEmpty && _issueTitle.isNotEmpty) {
      final guideKey = '${_applianceName}_$_issueTitle';
      final result = await _firestoreService.isBookmarked(authProvider.user!.uid, guideKey);
      if (mounted) setState(() => _isBookmarked = result);
    }
  }

  void _toggleBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to bookmark guides'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_applianceName.isEmpty || _issueTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a guide first to bookmark'), backgroundColor: Colors.orange),
      );
      return;
    }
    final guideKey = '${_applianceName}_$_issueTitle';
    if (_isBookmarked) {
      await _firestoreService.removeBookmark(authProvider.user!.uid, guideKey);
    } else {
      await _firestoreService.addBookmark(authProvider.user!.uid, guideKey);
    }
    if (mounted) setState(() => _isBookmarked = !_isBookmarked);
  }

  void _submitGuideRating() async {
    if (_guideRating == 0) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await _firestoreService.submitFeedback({
        'userId': authProvider.user?.uid ?? '',
        'userName': authProvider.user?.displayName ?? 'Anonymous',
        'technicianId': 'guide',
        'technicianName': '$_applianceName - $_issueTitle Guide',
        'rating': _guideRating,
        'comment': 'Guide rating',
        'type': 'guide_rating',
      });
      if (mounted) {
        setState(() => _ratingSubmitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for rating this guide!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // silently fail
    }
  }

  void _generateGuide() async {
    if (_applianceName.isEmpty || _issueTitle.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generationError = null;
      _steps = [];
      _ratingSubmitted = false;
      _guideRating = 0;
      _activeStepVisualizerIndex = null;
    });

    try {
      final generatedSteps = await LlmService.generateGuide(_applianceName, _issueTitle);
      setState(() {
        _steps = generatedSteps;
        _isGenerating = false;
      });
      _checkBookmark();
    } catch (e) {
      setState(() {
        _generationError = "Failed to generate instructions.\nDetails: $e";
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isGenerating) _buildGeneratingPlaceholder(),
                if (_generationError != null) _buildErrorContainer(),

                if (!_isGenerating && _steps.isNotEmpty) ...[
                  // Title + Bookmark header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildHeader(_applianceName, _issueTitle),
                      ),
                      IconButton(
                        onPressed: _toggleBookmark,
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _isBookmarked ? Colors.blue : Colors.grey,
                          size: 32,
                        ),
                        tooltip: _isBookmarked ? 'Remove Bookmark' : 'Save Guide',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSafetyWarning(),
                  const SizedBox(height: 32),

                  const Text('Preparation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildToolList(const ['Standard Screwdriver', 'Flashlight', 'Dry Cloth']),
                  const SizedBox(height: 32),

                  const Text('Instructions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  ..._steps.asMap().entries.map((entry) => _buildStepCard(entry.key, entry.value)),

                  const SizedBox(height: 32),

                  // Rate this guide
                  _buildGuideRatingSection(),
                  const SizedBox(height: 48),
                ],

                if (!_isGenerating && _steps.isEmpty && _generationError == null)
                  _buildEmptyStatePlaceholder(),

                const SizedBox(height: 24),
                _buildContactProBanner(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              "Preparing guide for '$_applianceName'...",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Preparing custom step-by-step DIY instructions.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStatePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "No Guide Loaded",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please select a device and problem from the repair page first.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
              _generationError!,
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRatingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text('Was this guide helpful?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                iconSize: 36,
                icon: Icon(
                  i < _guideRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: _ratingSubmitted ? null : () => setState(() => _guideRating = i + 1),
              );
            }),
          ),
          if (_guideRating > 0 && !_ratingSubmitted) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitGuideRating,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Submit Rating'),
            ),
          ],
          if (_ratingSubmitted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Thank you for your rating!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String appliance, String issue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.build_circle, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(appliance.toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Fixing: $issue',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
        ),
      ],
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: const Row(
        children: [
          Icon(Icons.gpp_maybe, color: Colors.red, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'SAFETY NOTICE: Always disconnect the power supply before opening any electronic device. Do not attempt if you see exposed wiring.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolList(List<String> tools) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tools.map((tool) => Chip(
        avatar: const Icon(Icons.handyman, size: 16),
        label: Text(tool),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide.none,
      )).toList(),
    );
  }

  Widget _buildStepCard(int index, String text) {
    final isExpanded = _activeStepVisualizerIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 17, height: 1.5, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.blue,
                  ),
                  tooltip: isExpanded ? "Hide Blueprint" : "Show 3D Blueprint",
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _activeStepVisualizerIndex = null;
                      } else {
                        _activeStepVisualizerIndex = index;
                      }
                    });
                  },
                ),
              ],
            ),
            if (isExpanded) ...[
              const Divider(height: 32),
              Simulated3dHelper(stepIndex: index, stepText: text),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactProBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text("Guide not helping?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Some repairs require specialized equipment. Connect with a certified technician nearby.", textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/technician_support', arguments: {
              'appliance': _applianceName.isNotEmpty ? _applianceName : 'Appliance',
              'issue': _issueTitle.isNotEmpty ? _issueTitle : 'Issue',
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text("Request Professional Support"),
          ),
        ],
      ),
    );
  }
}

class Simulated3dHelper extends StatefulWidget {
  final int stepIndex;
  final String stepText;

  const Simulated3dHelper({
    super.key,
    required this.stepIndex,
    required this.stepText,
  });

  @override
  State<Simulated3dHelper> createState() => _Simulated3dHelperState();
}

class _Simulated3dHelperState extends State<Simulated3dHelper> {
  double _rotationX = 0.5; // pitch
  double _rotationY = 0.5; // yaw
  
  // Interactive states
  int _screwsRemoved = 0;
  bool _disconnected = false;
  bool _wireRepaired = false;
  bool _filterCleaned = false;

  @override
  Widget build(BuildContext context) {
    final int modelType = widget.stepIndex % 4;
    String interactionStatus = "";
    if (modelType == 0) {
      interactionStatus = _disconnected ? "Status: Disconnected (Safe)" : "Status: Connected (Tap plug to disconnect)";
    } else if (modelType == 1) {
      interactionStatus = _screwsRemoved >= 4 ? "Status: Panel Open" : "Status: Screws removed: $_screwsRemoved/4 (Tap amber screws)";
    } else if (modelType == 2) {
      interactionStatus = _wireRepaired ? "Status: Wire Connected" : "Status: Loose connection detected (Tap glowing amber wire)";
    } else if (modelType == 3) {
      interactionStatus = _filterCleaned ? "Status: Filter Cleaned" : "Status: Blocked / Dirty (Tap filter core to clean)";
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade900, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.threed_rotation, color: Colors.cyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "3D Interactive Blueprint",
                    style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Text(
                interactionStatus,
                style: TextStyle(color: Colors.cyan.shade200, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX -= details.delta.dy * 0.01;
              });
            },
            onTapDown: (details) {
              // Handle simple clicks for interaction toggling
              setState(() {
                if (modelType == 0) {
                  _disconnected = !_disconnected;
                } else if (modelType == 1) {
                  if (_screwsRemoved < 4) {
                    _screwsRemoved++;
                  } else {
                    _screwsRemoved = 0;
                  }
                } else if (modelType == 2) {
                  _wireRepaired = !_wireRepaired;
                } else if (modelType == 3) {
                  _filterCleaned = !_filterCleaned;
                }
              });
            },
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.transparent,
              child: CustomPaint(
                painter: Blueprint3dPainter(
                  rotationX: _rotationX,
                  rotationY: _rotationY,
                  modelType: modelType,
                  screwsRemoved: _screwsRemoved,
                  disconnected: _disconnected,
                  wireRepaired: _wireRepaired,
                  filterCleaned: _filterCleaned,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Drag model to rotate. Tap anywhere on blueprint to simulate repair interactions.",
            style: TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class Blueprint3dPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final int modelType;
  final int screwsRemoved;
  final bool disconnected;
  final bool wireRepaired;
  final bool filterCleaned;

  Blueprint3dPainter({
    required this.rotationX,
    required this.rotationY,
    required this.modelType,
    required this.screwsRemoved,
    required this.disconnected,
    required this.wireRepaired,
    required this.filterCleaned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintGrid = Paint()
      ..color = Colors.blue.shade900.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw blueprint background grid
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final paintLine = Paint()
      ..color = Colors.cyan.shade500
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintAccent = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Project points based on model type
    if (modelType == 0) {
      // Plug and Outlet wireframe
      final double zShift = disconnected ? 40.0 : 0.0;

      // Socket box (fixed)
      _drawWireframeCube(canvas, center, 0, 0, 50, 60, 60, 20, rotationX, rotationY, paintLine);
      // Socket holes
      _drawWireframeCube(canvas, center, -15, 0, 40, 10, 20, 5, rotationX, rotationY, paintLine);
      _drawWireframeCube(canvas, center, 15, 0, 40, 10, 20, 5, rotationX, rotationY, paintLine);

      // Plug box (moving)
      _drawWireframeCube(canvas, center, 0, 0, -10 - zShift, 45, 45, 30, rotationX, rotationY, disconnected ? paintAccent : paintLine);
      // Prongs
      _drawWireframeCube(canvas, center, -15, 0, 15 - zShift, 6, 6, 20, rotationX, rotationY, paintLine);
      _drawWireframeCube(canvas, center, 15, 0, 15 - zShift, 6, 6, 20, rotationX, rotationY, paintLine);
    } else if (modelType == 1) {
      // Panel and Screws
      // Draw frame cabinet
      _drawWireframeCube(canvas, center, 0, 0, 0, 120, 120, 40, rotationX, rotationY, paintLine);
      // Cover plate
      _drawWireframeCube(canvas, center, 0, 0, 20, 100, 100, 2, rotationX, rotationY, screwsRemoved >= 4 ? paintAccent : paintLine);

      // Draw screws (amber targets)
      final List<List<double>> screwCoords = [
        [-40.0, -40.0],
        [40.0, -40.0],
        [-40.0, 40.0],
        [40.0, 40.0],
      ];
      for (int i = 0; i < 4; i++) {
        if (i >= screwsRemoved) {
          final coord = screwCoords[i];
          _drawWireframeCube(canvas, center, coord[0], coord[1], 22, 10, 10, 10, rotationX, rotationY, paintAccent);
        }
      }
    } else if (modelType == 2) {
      // Circuit board & wire connection
      _drawWireframeCube(canvas, center, 0, 0, 0, 140, 80, 5, rotationX, rotationY, paintLine);
      // Capacitor cylinder
      _drawWireframeCylinder(canvas, center, -35, 10, 15, 20, 30, rotationX, rotationY, paintLine);
      // Chip board
      _drawWireframeCube(canvas, center, 30, -10, 10, 40, 30, 8, rotationX, rotationY, paintLine);

      // Loose wire (Accent)
      _drawWireframeLine(canvas, center, -35, 25, 0, 10, -10, 10, rotationX, rotationY, wireRepaired ? paintLine : paintAccent);
      _drawWireframeLine(canvas, center, 10, -10, 10, 30, -10, 10, rotationX, rotationY, paintLine);
    } else {
      // Cylinder / Mechanical filter
      _drawWireframeCylinder(canvas, center, 0, 0, 0, 50, 100, rotationX, rotationY, filterCleaned ? paintLine : paintAccent);
      // Inner mesh lines
      _drawWireframeCylinder(canvas, center, 0, 0, 0, 30, 80, rotationX, rotationY, paintLine);
    }
  }

  // Projection helper
  Offset _project(double x, double y, double z, Offset center) {
    // Rotate Y (yaw)
    final x1 = x * math.cos(rotationY) - z * math.sin(rotationY);
    final z1 = x * math.sin(rotationY) + z * math.cos(rotationY);
    // Rotate X (pitch)
    final y2 = y * math.cos(rotationX) - z1 * math.sin(rotationX);
    final z2 = y * math.sin(rotationX) + z1 * math.cos(rotationX);

    // Isometric perspective projection
    const distance = 250.0;
    final scale = 180.0 / (z2 + distance);
    return Offset(
      center.dx + x1 * scale,
      center.dy + y2 * scale,
    );
  }

  void _drawWireframeLine(Canvas canvas, Offset center, double x1, double y1, double z1, double x2, double y2, double z2, double rx, double ry, Paint paint) {
    final p1 = _project(x1, y1, z1, center);
    final p2 = _project(x2, y2, z2, center);
    canvas.drawLine(p1, p2, paint);
  }

  void _drawWireframeCube(Canvas canvas, Offset center, double cx, double cy, double cz, double w, double h, double d, double rx, double ry, Paint paint) {
    final hw = w / 2;
    final hh = h / 2;
    final hd = d / 2;

    final verts = [
      _project(cx - hw, cy - hh, cz - hd, center),
      _project(cx + hw, cy - hh, cz - hd, center),
      _project(cx + hw, cy + hh, cz - hd, center),
      _project(cx - hw, cy + hh, cz - hd, center),
      _project(cx - hw, cy - hh, cz + hd, center),
      _project(cx + hw, cy - hh, cz + hd, center),
      _project(cx + hw, cy + hh, cz + hd, center),
      _project(cx - hw, cy + hh, cz + hd, center),
    ];

    // Draw front face edges
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(verts[i], verts[(i + 1) % 4], paint);
    }
    // Draw back face edges
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(verts[i + 4], verts[((i + 1) % 4) + 4], paint);
    }
    // Draw connecting edges
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(verts[i], verts[i + 4], paint);
    }
  }

  void _drawWireframeCylinder(Canvas canvas, Offset center, double cx, double cy, double cz, double radius, double height, double rx, double ry, Paint paint) {
    final halfH = height / 2;
    const segments = 12;
    final List<Offset> topVerts = [];
    final List<Offset> bottomVerts = [];

    for (int i = 0; i < segments; i++) {
      final angle = (i * 2 * math.pi) / segments;
      final x = cx + radius * math.cos(angle);
      final z = cz + radius * math.sin(angle);
      topVerts.add(_project(x, cy - halfH, z, center));
      bottomVerts.add(_project(x, cy + halfH, z, center));
    }

    // Draw cylinder edges
    for (int i = 0; i < segments; i++) {
      canvas.drawLine(topVerts[i], topVerts[(i + 1) % segments], paint);
      canvas.drawLine(bottomVerts[i], bottomVerts[(i + 1) % segments], paint);
      if (i % 2 == 0) {
        canvas.drawLine(topVerts[i], bottomVerts[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}