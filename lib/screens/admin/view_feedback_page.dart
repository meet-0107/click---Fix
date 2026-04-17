import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation_bar.dart';
import '../../widgets/app_drawer.dart';

class ViewFeedbackPage extends StatelessWidget {
  const ViewFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isMobile = MediaQuery.of(context).size.width < 1000;

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
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: EdgeInsets.all(isMobile ? 12 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 8),
                    const Text('User Feedback', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getAllFeedback(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No feedback submitted yet.'),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const SizedBox();

                    // Calculate stats
                    int totalReviews = docs.length;
                    double sumRatings = 0;
                    Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final rating = (data['rating'] as num?)?.toInt() ?? 0;
                      if (rating > 0 && rating <= 5) {
                        counts[rating] = counts[rating]! + 1;
                        sumRatings += rating;
                      }
                    }
                    double avgRating = totalReviews > 0 ? (sumRatings / totalReviews) : 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Graph Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _buildAvgSection(avgRating, totalReviews),
                                      const SizedBox(height: 24),
                                      _buildBarsSection(counts, totalReviews),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _buildAvgSection(avgRating, totalReviews),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 40),
                                          child: _buildBarsSection(counts, totalReviews),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Recent Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // Reviews List
                        Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final rating = (data['rating'] as num?)?.toInt() ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.purple.shade50,
                                          child: Icon(Icons.person, color: Colors.purple.shade700),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(data['userName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('For: ${data['technicianName'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (i) => Icon(
                                            i < rating ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 18,
                                          )),
                                        ),
                                      ],
                                    ),
                                    if (data['comment'] != null && data['comment'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(data['comment'], style: const TextStyle(height: 1.4)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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

  Widget _buildAvgSection(double avgRating, int totalReviews) {
    return Column(
      children: [
        Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            if (i < avgRating.floor()) return const Icon(Icons.star, color: Colors.amber, size: 24);
            if (i < avgRating.ceil() && avgRating - avgRating.floor() >= 0.5) return const Icon(Icons.star_half, color: Colors.amber, size: 24);
            return const Icon(Icons.star_border, color: Colors.amber, size: 24);
          }),
        ),
        const SizedBox(height: 8),
        Text('$totalReviews reviews', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBarsSection(Map<int, int> counts, int total) {
    return Column(
      children: [
        _buildBarRow('5', counts[5]!, total),
        _buildBarRow('4', counts[4]!, total),
        _buildBarRow('3', counts[3]!, total),
        _buildBarRow('2', counts[2]!, total),
        _buildBarRow('1', counts[1]!, total),
      ],
    );
  }

  Widget _buildBarRow(String label, int count, int total) {
    double pct = total == 0 ? 0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: Colors.grey, size: 14),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade400),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(count.toString(), textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
