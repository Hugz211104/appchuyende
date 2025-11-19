import 'package:chuyende/auth/auth_page.dart';
import 'package:chuyende/screens/home_screen.dart';
import 'package:chuyende/screens/setup_profile_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Key sẽ thay đổi mỗi khi user thay đổi, buộc HomeScreen phải được tạo lại
  Key? _homeScreenKey;
  User? _currentUser;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    // Phát hiện sự thay đổi người dùng
    if (_currentUser?.uid != user?.uid) {
      setState(() {
        _currentUser = user;
        // Tạo một Key hoàn toàn mới khi user thay đổi
        _homeScreenKey = UniqueKey();
      });
    }

    if (user == null) {
      return const AuthPage();
    } else {
      // Khi user đã đăng nhập, chúng ta sử dụng một StreamBuilder để kiểm tra hồ sơ
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, profileSnapshot) {
          // Trong khi chờ dữ liệu hồ sơ
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Nếu không có hồ sơ (tài khoản mới)
          if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
            return SetupProfileScreen(key: UniqueKey()); // Dùng key ở đây để reset
          }

          final data = profileSnapshot.data!.data() as Map<String, dynamic>?;
          final bool profileCompleted = data?['profileCompleted'] ?? false;

          // Nếu hồ sơ đã hoàn tất -> vào màn hình chính
          if (profileCompleted) {
            // ** ĐIỂM MẤU CHỐT LÀ Ở ĐÂY **
            // Gán Key đã được tạo ở trên. Khi key này thay đổi,
            // toàn bộ widget HomeScreen và các state con của nó sẽ bị hủy và tạo mới.
            return HomeScreen(key: _homeScreenKey);
          } else {
            // Nếu hồ sơ chưa hoàn tất -> vào màn hình cài đặt
            return SetupProfileScreen(key: UniqueKey());
// Dùng key ở đây để reset
          }
        },
      );
    }
  }
}
