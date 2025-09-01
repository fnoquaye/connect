// import 'package:connect/screens/auth/login_screen.dart';
import 'dart:developer';

import 'package:connect/screens/auth/login_screen.dart';
import 'package:connect/screens/homescreen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //enter fullscreen
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
// portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

       await _initializeFirebase();
       await initializeApp();

        runApp(
            ChangeNotifierProvider(
                create:(_)=> ThemeProvider(),
                child: const MyApp(),
            ));
}

Future<void> initializeApp() async {
  try {
    log('🚀 Starting app initialization...');
    // 🔥 NEW: Add timeout to prevent splash screen hanging
    await APIS.getSelfInfo().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        log('⏰ App initialization timed out, continuing anyway...');
      },
    );
    log('✅ App initialization completed');
  } catch (e) {
    log('❌ App initialization error: $e');
    // Don't block the app - continue to home screen
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add this widget as a lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    // Remove the observer and clean up presence tracking
    WidgetsBinding.instance.removeObserver(this);
    APIS.dispose(); // Clean up presence tracking when app is disposed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for presence tracking
    switch (state) {
      case AppLifecycleState.resumed:
      // App came to foreground
        APIS.handleAppLifecycleChange(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      // App went to background/inactive
        APIS.handleAppLifecycleChange(false);
        break;
      case AppLifecycleState.hidden:
      // App is hidden (newer Flutter versions)
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
      // themeMode: ThemeMode.light,
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
          builder: (context, snapshot){
    // Show splash screen while loading
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const SplashScreen();
    }

    // If there's an error, show splash screen (which will handle the error)
    if (snapshot.hasError) {
    log('❌ Auth stream error: ${snapshot.error}');
    return const SplashScreen();
      }
    // Check if user is authenticated
    if (snapshot.hasData && snapshot.data != null) {
    log('✅ User is authenticated: ${snapshot.data!.uid}');
    return const HomeScreen();
    } else {
    log('ℹ️ User is not authenticated');
    return const LoginScreen();
       }
      }
      ),
    );
  }
}

Future<void> _initializeFirebase() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// return MaterialApp(
//   title: 'Connect',
//   themeMode: themeProvider.themeMode,
//   theme: ThemeData.light(),
//     darkTheme: ThemeData.dark(),
//     appBarTheme: const AppBarTheme(
//       shape:RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(
//           bottom: Radius.circular(20),
//         ),
//       ) ,
//       centerTitle: true,
//       elevation: 1,
//      iconTheme: IconThemeData(color: Colors.black),
//      titleTextStyle: TextStyle(
//        color: Colors.black,
//        fontSize: 28,
//        fontWeight: FontWeight.w400,
//      ),
//       backgroundColor: Colors.blue,
//     ),
//   home: const SplashScreen(),
// );