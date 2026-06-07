import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://betogether-154f6-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// Check if current user has completed profile setup
  static Future<bool> hasCompletedProfile() async {
    final user = auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      return doc.exists && (doc.data()?['username'] != null);
    } catch (_) {
      return false;
    }
  }

  /// Save or update user profile in Firestore
  static Future<void> saveUserProfile({
    required String displayName,
    required String birthday,
    String? photoUrl,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': displayName.toLowerCase().replaceAll(' ', '_'),
      'displayName': displayName,
      'birthday': birthday,
      'photoUrl': photoUrl ?? user.photoURL ?? '',
      'email': user.email ?? '',
      'friends': [],
      'friendCode': user.uid.substring(0, 8).toUpperCase(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final doc = await firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Sign out and clean up location data
  static Future<void> signOut() async {
    final user = auth.currentUser;
    if (user != null) {
      // Set offline in RTDB before signing out
      try {
        await database.ref('locations/${user.uid}/isOnline').set(false);
      } catch (_) {}

      // Remove FCM token from user document
      try {
        await firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (_) {}
    }
    await auth.signOut();
  }
}
