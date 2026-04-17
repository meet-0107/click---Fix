import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBookmark());
  }

  void _checkBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (authProvider.user != null && args != null) {
      final guideKey = '${args['appliance']}_${args['issue']}';
      final result = await _firestoreService.isBookmarked(authProvider.user!.uid, guideKey);
      if (mounted) setState(() => _isBookmarked = result);
    }
  }

  void _toggleBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to bookmark guides'), backgroundColor: Colors.orange),
      );
      return;
    }
    final guideKey = '${args?['appliance']}_${args?['issue']}';
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    try {
      await _firestoreService.submitFeedback({
        'userId': authProvider.user?.uid ?? '',
        'userName': authProvider.user?.displayName ?? 'Anonymous',
        'technicianId': 'guide',
        'technicianName': '${args?['appliance']} - ${args?['issue']} Guide',
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

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final Map<String, dynamic>? args = route?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return const Scaffold(body: Center(child: Text("Error: No data provided")));
    }

    final String applianceName = args['appliance'];
    final List<String> steps = args['steps'];

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
                // Title + Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHeader(applianceName, args['issue'])),
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
                _buildToolList(['Standard Screwdriver', 'Flashlight', 'Dry Cloth']),
                const SizedBox(height: 32),

                const Text('Step-by-Step Instructions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...steps.asMap().entries.map((entry) => _buildStepCard(entry.key, entry.value)),

                const SizedBox(height: 32),

                // Rate this guide
                _buildGuideRatingSection(),

                const SizedBox(height: 48),

                _buildContactProBanner(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideRatingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
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
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, height: 1.1),
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
        child: Row(
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
            onPressed: () => Navigator.pushNamed(context, '/technician_support'),
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