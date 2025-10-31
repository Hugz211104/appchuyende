import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy stream trạng thái đăng nhập của người dùng
  Stream<User?> get user => _auth.authStateChanges();

  // Đăng nhập bằng Email và Password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Bạn có thể xử lý các lỗi cụ thể ở đây, ví dụ: sai mật khẩu, người dùng không tồn tại
      print(e.message);
      return null;
    }
  }

  // Đăng ký bằng Email và Password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Bạn có thể xử lý các lỗi cụ thể ở đây, ví dụ: email đã tồn tại
      print(e.message);
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
