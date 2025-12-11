import 'package:chuyende/auth/auth_wrapper.dart';
import 'package:chuyende/providers/theme_provider.dart';
import 'package:chuyende/screens/login_screen.dart';
import 'package:chuyende/screens/register_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/services/notification_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('vi', timeago.ViMessages());
  await Firebase.initializeApp();

  const androidProvider = kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
  const appleProvider = kDebugMode ? AppleProvider.debug : AppleProvider.appAttest;

  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );

  runApp(const GenNewsApp());
}

class GenNewsApp extends StatefulWidget {
  const GenNewsApp({super.key});

  @override
  State<GenNewsApp> createState() => _GenNewsAppState();
}

class _GenNewsAppState extends State<GenNewsApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'GenNews',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: AuthWrapper(),
            routes: {
              '/login': (context) => LoginScreen(
                    showRegisterScreen: () {
                      Navigator.pushNamed(context, '/register');
                    },
                  ),
              '/register': (context) => RegisterScreen(
                    showLoginScreen: () {
                      Navigator.pop(context);
                    },
                  ),
            },
          );
        },
      ),
    );
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
