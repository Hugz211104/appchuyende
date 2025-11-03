import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Uploads a profile image for the current user.
  Future<String?> uploadProfileImage(File file) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await uploadFile(file, 'profile_pictures/${user.uid}');
  }

  /// Uploads a cover image for the current user.
  Future<String?> uploadCoverImage(File file) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await uploadFile(file, 'cover_pictures/${user.uid}');
  }
}
