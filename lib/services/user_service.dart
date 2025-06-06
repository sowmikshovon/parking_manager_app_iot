import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<String> getUserName([User? user]) async {
    user ??= currentUser;
    if (user == null) return 'User';

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = data['name'] as String? ?? '';
        if (name.isNotEmpty) return name;
      }
    } catch (e) {
      print('Error getting user name: $e');
    }

    if (user.displayName?.isNotEmpty == true) {
      return user.displayName!;
    }

    if (user.email?.contains('@') == true) {
      return user.email!.split('@')[0];
    }

    return 'User';
  }

  static Future<Map<String, dynamic>?> getUserData([User? user]) async {
    user ??= currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
