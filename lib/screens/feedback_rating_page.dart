import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/app_drawer.dart';

class FeedbackRatingPage extends StatefulWidget {
  const FeedbackRatingPage({super.key});

  @override
  State<FeedbackRatingPage> createState() => _FeedbackRatingPageState();
}

class _FeedbackRatingPageState extends State<FeedbackRatingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  String _getRatingText() {
    switch (_rating) {
      case 1: return "Disappointing";
      case 2: return "Fair";
      case 3: return "Good";
      case 4: return "Very Good";
      case 5: return "Excellent!";
      default: return "Select a rating";
    }
  }

  void _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating first.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    setState(() => _isSubmitting = true);

    try {
      await _firestoreService.submitFeedback({
        'userId': authProvider.user?.uid ?? '',
        'userName': authProvider.user?.displayName ?? 'Anonymous',
        'technicianId': args?['technicianId'] ?? '',
        'technicianName': args?['technicianName'] ?? 'Unknown',
        'rating': _rating,
        'comment': _feedbackController.text.trim(),
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text("Thank You!", textAlign: TextAlign.center),
              ],
            ),
            content: const Text(
              "Your feedback has been saved and helps improve our services.",
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                  child: const Text("Return Home"),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: NavigationBarWidget(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: 500,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rate Your Repair',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How was your experience with the technician?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          iconSize: 45,
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setState(() => _rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _getRatingText(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _rating > 0 ? Colors.blue : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Feedback Field
                    TextFormField(
                      controller: _feedbackController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Share more details (Optional)',
                        hintText: 'Tell us what went well or what we can improve...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0061FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('Submit Review', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}