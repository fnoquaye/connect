import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connect/screens/auth/login_screen.dart';
import 'package:connect/screens/homescreen.dart';
import 'package:connect/screens/language_select_screen.dart';
import 'package:connect/screens/splash_screen.dart';
import 'package:connect/helper/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'APIs/apis.dart';
import 'firebase_options.dart';

//global object for accessing device screen size
late Size mq;

// Flutter Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📱 Background message: ${message.notification?.title}");

  // Show local notification for background messages
  await _showNotification(message);
}

// Show local notification
Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'chat_channel', // channel id
    'Chat Messages', // channel name
    channelDescription: 'Notifications for chat messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond, // notification id
    message.notification?.title ?? 'New Message',
    message.notification?.body ?? 'You have a new message',
    platformChannelSpecifics,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  await _initializeFirebase();
  await _initializeNotifications();
  await initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      print("📱 Notification tapped: ${details.payload}");
      // Handle notification tap - navigate to chat screen
    },
  );

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_channel',
    'Chat Messages',
    description: 'Notifications for chat messages',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> initializeApp() async {
  try {
    log('🚀 Starting app initialization...');
    await APIS.getSelfInfo().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        log('⏰ App initialization timed out, continuing anyway...');
      },
    );

    // Initialize FCM properly
    await APIS.initializeFCM();

    log('✅ App initialization completed');
  } catch (e) {
    log('❌ App initialization error: $e');
  }
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// Your existing MyApp class remains the same...
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupForegroundMessageHandling();
  }

  void _setupForegroundMessageHandling() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message: ${message.notification?.title}');
      _showNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Message clicked: ${message.data}');
      // Navigate to specific chat screen based on message data
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    APIS.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        APIS.handleAppLifecycleChange(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        APIS.handleAppLifecycleChange(false);
        break;
      case AppLifecycleState.hidden:
        APIS.handleAppLifecycleChange(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connect',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
          ),
          centerTitle: true,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          centerTitle: true,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          backgroundColor: Colors.black,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasError) {
            log('❌ Auth stream error: ${snapshot.error}');
            return const SplashScreen();
          }
          if (snapshot.hasData && snapshot.data != null) {
            log('✅ User is authenticated: ${snapshot.data!.uid}');
            return FutureBuilder<String>(
              future: APIS.getUserPreferredLanguage(snapshot.data!.uid),
              builder: (context, langSnapshot) {
                if (langSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (langSnapshot.hasError) {
                  log('❌ Language fetch error: ${langSnapshot.error}');
                  return const SplashScreen();
                }

                final preferredLang = langSnapshot.data ?? '';
                final showSelector = preferredLang.isEmpty;

                if (showSelector) {
                  log('🌐 Showing Language Selector Screen');
                  return LanguageSelectScreen();
                } else {
                  log('🏠 Routing to HomeScreen');
                  return const HomeScreen();
                }
              },
            );
          } else {
            log('ℹ️ User is not authenticated');
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
