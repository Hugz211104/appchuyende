import 'package:chuyende/screens/post_detail_screen.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _handleNotificationTap(DocumentSnapshot notification) async {
    final data = notification.data() as Map<String, dynamic>;

    // Mark as read immediately
    if (data['isRead'] == false) {
      await notification.reference.update({'isRead': true});
    }

    // Navigate based on type
    final type = data['type'] as String?;
    if (type == 'like' || type == 'comment' || type == 'reaction') { // Added reaction type
      final postId = data['postId'] as String?;
      if (postId != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: postId),
        ));
      }
    } else if (type == 'follow') {
      final actorId = data['actorId'] as String?;
      if (actorId != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: actorId),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo', style: AppStyles.headline.copyWith(fontSize: 28, color: theme.colorScheme.onSurface)),
        centerTitle: false,
        elevation: 0.5,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem thông báo.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: _currentUser!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có thông báo nào.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final notification = snapshot.data!.docs[index];
                    final data = notification.data() as Map<String, dynamic>;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(data['actorId']).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                          return ListTile(leading: CircleAvatar(backgroundColor: theme.colorScheme.background));
                        }

                        final actorData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final actorName = actorData['displayName'] ?? 'Ai đó';
                        final actorPhotoUrl = actorData['photoURL'] as String?;
                        final timestamp = (data['timestamp'] as Timestamp).toDate();

                        String notificationMessage;
                        switch (data['type']) {
                          case 'follow':
                            notificationMessage = 'đã bắt đầu theo dõi bạn.';
                            break;
                          case 'like':
                            notificationMessage = 'đã thích bài viết của bạn.';
                            break;
                          case 'comment':
                            notificationMessage = 'đã bình luận về bài viết của bạn.';
                            break;
                           case 'reaction':
                             notificationMessage = 'đã bày tỏ cảm xúc về bài viết của bạn.';
                             break;
                          default:
                            notificationMessage = 'đã gửi cho bạn một thông báo.';
                        }

                        return ListTile(
                          tileColor: data['isRead'] == false ? theme.colorScheme.primary.withOpacity(0.05) : Colors.transparent,
                          leading: CircleAvatar(
                            backgroundImage: (actorPhotoUrl != null && actorPhotoUrl.isNotEmpty) ? NetworkImage(actorPhotoUrl) : null,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: (actorPhotoUrl == null || actorPhotoUrl.isEmpty)
                                ? Text(actorName[0].toUpperCase(), style: AppStyles.username.copyWith(color: theme.colorScheme.primary))
                                : null,
                          ),
                          title: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                              children: [
                                TextSpan(text: actorName, style: AppStyles.username.copyWith(fontSize: 15)),
                                TextSpan(text: ' $notificationMessage'),
                              ],
                            ),
                          ),
                          subtitle: Text(timeago.format(timestamp, locale: 'vi'), style: AppStyles.timestamp.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          onTap: () => _handleNotificationTap(notification),
                          trailing: data['isRead'] == false ? Icon(Icons.circle, color: theme.colorScheme.primary, size: 12) : null,
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
