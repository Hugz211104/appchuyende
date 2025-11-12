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

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  // A helper to mark notifications as read can be added here in the future.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
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
                        if (!userSnapshot.hasData) {
                          return const ListTile(); // Or a loading tile
                        }

                        final actorData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
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
                          default:
                            notificationMessage = 'đã gửi cho bạn một thông báo.';
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (actorPhotoUrl != null && actorPhotoUrl.isNotEmpty) ? NetworkImage(actorPhotoUrl) : null,
                            child: (actorPhotoUrl == null || actorPhotoUrl.isEmpty) ? const Icon(Icons.person) : null,
                          ),
                          title: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(text: actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' $notificationMessage'),
                              ],
                            ),
                          ),
                          subtitle: Text(timeago.format(timestamp, locale: 'vi')),
                          onTap: () => _navigateToProfile(data['actorId']), // Or navigate to post
                          trailing: data['type'] == 'follow' ? const Icon(Icons.person_add_alt_1_sharp) : const Icon(Icons.article),
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
