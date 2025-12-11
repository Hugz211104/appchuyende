import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> initNotifications() async {
    // Request permission
    await _fcm.requestPermission();

    // Get the token
    final token = await _fcm.getToken();
    print("FCM Token: $token"); // For testing

    // Save the token for the current user
    if (_auth.currentUser != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Here you can show a local notification using a package like flutter_local_notifications
      }
    });
  }

  Future<void> _saveTokenToDatabase(String? token) async {
    if (token == null || _auth.currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
  }
}
