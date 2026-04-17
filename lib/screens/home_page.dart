import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/appliance_issues.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/footer.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<DeviceCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return RepairData.categories;
    return RepairData.categories.where((cat) {
      final matchesCategory = cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesIssue = cat.commonIssues.any(
        (issue) => issue.title.toLowerCase().contains(_searchQuery.toLowerCase()),
      );
      return matchesCategory || matchesIssue;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 1000;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: NavigationBarWidget(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HERO SECTION with Search ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.blue.shade50),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 80,
                vertical: isMobile ? 32 : 60,
              ),
              child: Column(
                children: [
                  if (!isMobile)
                    Row(children: _heroContent(context, isMobile))
                  else
                    ..._heroContentMobile(context),

                  const SizedBox(height: 32),

                  // Search Bar
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Select an appliance to repair...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF0061FF)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0061FF), width: 2)),
                      ),
                      value: _searchQuery.isEmpty ? null : _searchQuery,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All Devices')),
                        ...RepairData.categories.map((cat) => DropdownMenuItem(
                              value: cat.name,
                              child: Text('${cat.name} Repair'),
                            ))
                      ],
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val ?? '';
                          _searchController.text = val ?? '';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- SEARCH RESULTS ---
            if (_searchQuery.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 24),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Results for "$_searchQuery"',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_filteredCategories.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                const Text('No products found. Try a different search.'),
                              ],
                            ),
                          )
                        else
                          ..._filteredCategories.map((cat) => _buildSearchResultCard(cat, isMobile)),
                      ],
                    ),
                  ),
                ),
              ),

            // --- WELCOME ---
            if (authProvider.isAuthenticated && _searchQuery.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                color: Colors.green.shade50,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const Icon(Icons.waving_hand, color: Colors.orange, size: 22),
                      Text(
                        'Welcome, ${authProvider.user?.displayName ?? 'User'}!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            // --- FEATURES ---
            if (_searchQuery.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      "Our Services",
                      style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    if (isMobile)
                      Column(
                        children: [
                          _buildFeatureCard(context, 'Diagnose Your Device', Icons.biotech_outlined, 'Identify issues in minutes.', isMobile, '/repair'),
                          const SizedBox(height: 16),
                          _buildFeatureCard(context, 'Connect with a Pro', Icons.engineering_outlined, 'Find verified local repair experts.', isMobile, '/technician_support'),
                          const SizedBox(height: 16),
                          _buildFeatureCard(context, 'Track My Requests', Icons.history, 'Check status and leave reviews.', isMobile, '/user_requests'),
                          const SizedBox(height: 16),
                          _buildFeatureCard(context, 'Step-by-Step Guides', Icons.menu_book_rounded, 'Access DIY manuals for fixes.', isMobile, '/repair'),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildFeatureCard(context, 'Diagnose Your Device', Icons.biotech_outlined, 'Identify issues in minutes.', isMobile, '/repair'),
                          _buildFeatureCard(context, 'Connect with a Pro', Icons.engineering_outlined, 'Find verified local repair experts.', isMobile, '/technician_support'),
                          _buildFeatureCard(context, 'Track My Requests', Icons.history, 'Check status and leave reviews.', isMobile, '/user_requests'),
                          _buildFeatureCard(context, 'Step-by-Step Guides', Icons.menu_book_rounded, 'Access DIY manuals for fixes.', isMobile, '/repair'),
                        ],
                      ),
                  ],
                ),
              ),

            // --- DEVICE GRID ---
            if (_searchQuery.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60, horizontal: 16),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    Text('Popular Devices', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Tap a device to see issues', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: RepairData.categories.map((cat) {
                        return InkWell(
                          onTap: () {
                            _searchController.text = cat.name;
                            setState(() => _searchQuery = cat.name);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: isMobile ? 100 : 140,
                            padding: EdgeInsets.all(isMobile ? 14 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(cat.icon, size: isMobile ? 28 : 36, color: const Color(0xFF0061FF)),
                                const SizedBox(height: 8),
                                Text(cat.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 14), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            if (_searchQuery.isEmpty) const FooterWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(DeviceCategory category, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, color: const Color(0xFF0061FF), size: 24),
                const SizedBox(width: 10),
                Text(category.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...category.commonIssues.map((issue) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem_outlined, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(issue.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  Text('${issue.diySteps.length} repair steps', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/self_repair_guide', arguments: {
                            'appliance': category.name,
                            'issue': issue.title,
                            'steps': issue.diySteps,
                          }),
                          icon: const Icon(Icons.menu_book, size: 16),
                          label: const Text('DIY Fix', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/technician_support', arguments: {
                            'appliance': category.name,
                            'issue': issue.title,
                          }),
                          icon: const Icon(Icons.engineering, size: 16),
                          label: const Text('Find Tech', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Desktop hero
  List<Widget> _heroContent(BuildContext context, bool isMobile) {
    return [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Home Electronics,\nFixed.',
              style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1.1, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 20),
            const Text('Expert support and certified technicians, just a click away.',
                style: TextStyle(fontSize: 22, color: Colors.black54)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/repair'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                backgroundColor: const Color(0xFF0061FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Your Repair Now', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, s) => Container(
              height: 300,
              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(24)),
              child: const Center(child: Icon(Icons.build_circle, size: 80, color: Colors.blue)),
            ),
          ),
        ),
      ),
    ];
  }

  // Mobile hero — no Expanded, no Row
  List<Widget> _heroContentMobile(BuildContext context) {
    return [
      const Text(
        'Your Home Electronics,\nFixed.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1, color: Color(0xFF1A237E)),
      ),
      const SizedBox(height: 16),
      const Text('Expert support and certified technicians, just a click away.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/repair'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          backgroundColor: const Color(0xFF0061FF),
          foregroundColor: Colors.white,
        ),
        child: const Text('Start Your Repair Now', style: TextStyle(fontSize: 16)),
      ),
    ];
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, String description, bool isMobile, String route) {
    return SizedBox(
      width: isMobile ? double.infinity : 280,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () {
            final role = Provider.of<AuthProvider>(context, listen: false).userRole;
            if (role == 'user' || route == '/repair') {
                Navigator.pushNamed(context, route);
            } else if (role == 'admin') {
                Navigator.pushNamed(context, '/admin_dashboard');
            } else {
                Navigator.pushNamed(context, '/technician_profile');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: isMobile
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: Icon(icon, size: 28, color: const Color(0xFF0061FF)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(description, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: Icon(icon, size: 36, color: const Color(0xFF0061FF)),
                      ),
                      const SizedBox(height: 20),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.4)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}