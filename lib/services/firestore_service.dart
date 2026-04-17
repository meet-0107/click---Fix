import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore CRUD service for all collections.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===================== USERS =====================

  /// Get a single user document by UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Get user role by UID.
  Future<String?> getUserRole(String uid) async {
    final data = await getUser(uid);
    return data?['role'] as String?;
  }

  /// Get all users.
  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').orderBy('createdAt', descending: true).snapshots();
  }

  /// Update user profile fields.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Delete a user document.
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ===================== TECHNICIANS =====================

  /// Get all technicians (users with role == 'technician').
  Stream<QuerySnapshot> getTechnicians() {
    return _db.collection('users').where('role', isEqualTo: 'technician').snapshots();
  }

  /// Get technicians by pincode.
  Stream<QuerySnapshot> getTechniciansByPincode(String pincode) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .where('pincode', isEqualTo: pincode)
        .snapshots();
  }

  /// Get technicians filtered by specialty (contains appliance name) and pincode.
  Stream<QuerySnapshot> getTechniciansBySpecialtyAndPincode(String appliance, String pincode) {

    return _db
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .where('pincode', isEqualTo: pincode)
        .snapshots();
  }

  /// Get requests for a technician filtered by status.
  Stream<QuerySnapshot> getRequestsForTechnicianByStatus(String technicianId, String status) {
    return _db
        .collection('service_requests')
        .where('technicianId', isEqualTo: technicianId)
        .where('status', isEqualTo: status)
        .snapshots();
  }

  /// Update technician-specific profile fields.
  Future<void> updateTechnicianProfile(String uid, {
    String? specialty,
    String? phone,
    String? pincode,
    bool? isAvailable,
  }) async {
    final data = <String, dynamic>{};
    if (specialty != null) data['specialty'] = specialty;
    if (phone != null) data['phone'] = phone;
    if (pincode != null) data['pincode'] = pincode;
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  // ===================== GUIDES =====================

  /// Get all guides.
  Stream<QuerySnapshot> getGuides() {
    return _db.collection('guides').orderBy('category').snapshots();
  }

  /// Get guides by category.
  Stream<QuerySnapshot> getGuidesByCategory(String category) {
    return _db.collection('guides').where('category', isEqualTo: category).snapshots();
  }

  /// Add a new guide.
  Future<DocumentReference> addGuide(Map<String, dynamic> guide) async {
    guide['createdAt'] = FieldValue.serverTimestamp();
    return await _db.collection('guides').add(guide);
  }

  /// Update an existing guide.
  Future<void> updateGuide(String guideId, Map<String, dynamic> data) async {
    await _db.collection('guides').doc(guideId).update(data);
  }

  /// Delete a guide.
  Future<void> deleteGuide(String guideId) async {
    await _db.collection('guides').doc(guideId).delete();
  }

  /// Seed default repair guides from local data.
  Future<void> seedDefaultGuides(List<Map<String, dynamic>> guides) async {
    final batch = _db.batch();
    for (final guide in guides) {
      final ref = _db.collection('guides').doc();
      guide['createdAt'] = FieldValue.serverTimestamp();
      batch.set(ref, guide);
    }
    await batch.commit();
  }

  // ===================== SERVICE REQUESTS =====================

  /// Create a service request.
  Future<DocumentReference> createServiceRequest(Map<String, dynamic> request) async {
    request['createdAt'] = FieldValue.serverTimestamp();
    request['status'] = 'pending';
    return await _db.collection('service_requests').add(request);
  }

  /// Get requests for a specific user.
  Stream<QuerySnapshot> getRequestsForUser(String userId) {
    return _db
        .collection('service_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get requests for a specific technician.
  Stream<QuerySnapshot> getRequestsForTechnician(String technicianId) {
    return _db
        .collection('service_requests')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all pending requests (for technicians to browse).
  Stream<QuerySnapshot> getPendingRequests() {
    return _db
        .collection('service_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update request status.
  Future<void> updateRequestStatus(String requestId, String status, {String? technicianId}) async {
    final data = <String, dynamic>{'status': status};
    if (technicianId != null) data['technicianId'] = technicianId;
    await _db.collection('service_requests').doc(requestId).update(data);
  }

  // ===================== FEEDBACK =====================

  /// Submit feedback for a technician.
  Future<DocumentReference> submitFeedback(Map<String, dynamic> feedback) async {
    feedback['createdAt'] = FieldValue.serverTimestamp();
    return await _db.collection('feedback').add(feedback);
  }

  /// Get feedback for a specific technician.
  Stream<QuerySnapshot> getFeedbackForTechnician(String technicianId) {
    return _db
        .collection('feedback')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all feedback.
  Stream<QuerySnapshot> getAllFeedback() {
    return _db.collection('feedback').orderBy('createdAt', descending: true).snapshots();
  }

  /// Get average rating for a technician.
  Future<double> getTechnicianRating(String technicianId) async {
    final snapshot = await _db
        .collection('feedback')
        .where('technicianId', isEqualTo: technicianId)
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['rating'] as num).toDouble();
    }
    return total / snapshot.docs.length;
  }

  // ===================== BOOKMARKS =====================

  /// Add a bookmark.
  Future<void> addBookmark(String userId, String guideId) async {
    await _db.collection('bookmarks').doc('${userId}_$guideId').set({
      'userId': userId,
      'guideId': guideId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a bookmark.
  Future<void> removeBookmark(String userId, String guideId) async {
    await _db.collection('bookmarks').doc('${userId}_$guideId').delete();
  }

  /// Get all bookmarks for a user.
  Stream<QuerySnapshot> getUserBookmarks(String userId) {
    return _db.collection('bookmarks').where('userId', isEqualTo: userId).snapshots();
  }

  /// Check if a guide is bookmarked.
  Future<bool> isBookmarked(String userId, String guideId) async {
    final doc = await _db.collection('bookmarks').doc('${userId}_$guideId').get();
    return doc.exists;
  }
}
