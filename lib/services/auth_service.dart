import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    notifyListeners();
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'displayName': email.split('@')[0], 
          'photoURL': null, 
          'coverPhotoUrl': null, // Set to null to avoid unreliable URL
          'followers': [],
          'following': [],
          'profileCompleted': false, // Ensure this is false on creation
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    }
  }

  // New method to check follow status in real-time
  Stream<bool> isFollowing(String targetUserId) {
    if (_user == null) {
      return Stream.value(false);
    }
    return _firestore.collection('users').doc(_user!.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data != null && data.containsKey('following')) {
        final followingList = List<String>.from(data['following']);
        return followingList.contains(targetUserId);
      }
      return false;
    });
  }

  // New method to toggle follow/unfollow status
  Future<void> toggleFollow(String targetUserId) async {
    if (_user == null) {
      throw Exception('User not logged in');
    }
    final currentUserId = _user!.uid;

    if (currentUserId == targetUserId) {
      throw Exception('Cannot follow yourself');
    }

    final currentUserDocRef = _firestore.collection('users').doc(currentUserId);
    final targetUserDocRef = _firestore.collection('users').doc(targetUserId);

    final writeBatch = _firestore.batch();

    final currentUserDoc = await currentUserDocRef.get();
    final List<String> following = List<String>.from(currentUserDoc.data()?['following'] ?? []);

    if (following.contains(targetUserId)) {
      // --- Unfollow logic ---
      writeBatch.update(currentUserDocRef, {
        'following': FieldValue.arrayRemove([targetUserId])
      });
      writeBatch.update(targetUserDocRef, {
        'followers': FieldValue.arrayRemove([currentUserId])
      });
    } else {
      // --- Follow logic ---
      writeBatch.update(currentUserDocRef, {
        'following': FieldValue.arrayUnion([targetUserId])
      });
      writeBatch.update(targetUserDocRef, {
        'followers': FieldValue.arrayUnion([currentUserId])
      });
    }

    await writeBatch.commit();
    // No need to notifyListeners() here, as the stream in isFollowing will handle UI updates automatically
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
