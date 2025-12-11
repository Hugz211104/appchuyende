import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum FollowListType { following, followers }

class FollowListScreen extends StatelessWidget {
  final String userId;
  final FollowListType listType;

  const FollowListScreen({super.key, required this.userId, required this.listType});

  String get _title => listType == FollowListType.following ? 'Đang theo dõi' : 'Người theo dõi';
  String get _firestoreField => listType == FollowListType.following ? 'following' : 'followers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy người dùng.'));
          }

          final List<dynamic> userIds = userSnapshot.data![_firestoreField] ?? [];
          if (userIds.isEmpty) {
            return Center(child: Text('Không có ai trong danh sách này.'));
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: userIds).get(),
            builder: (context, followUsersSnapshot) {
              if (followUsersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!followUsersSnapshot.hasData || followUsersSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Không thể tải danh sách người dùng.'));
              }

              return ListView.builder(
                itemCount: followUsersSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final userDoc = followUsersSnapshot.data!.docs[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final photoURL = userData['photoURL'] as String?;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                      child: (photoURL == null || photoURL.isEmpty) ? Text(userData['displayName']?[0] ?? 'N/A') : null,
                    ),
                    title: Text(userData['displayName'] ?? 'Người dùng', style: AppStyles.username),
                    subtitle: Text('@${userData['handle'] ?? 'N/A'}', style: TextStyle(color: AppColors.textSecondary)),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen(userId: userDoc.id))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
