// import 'package:connect/screens/auth/login_screen.dart';
import 'package:connect/screens/splash_screen.dart';
// import 'package:connect/screens/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//global object for accessing device screen size
late Size mq;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
         iconTheme: IconThemeData(color: Colors.black),
         titleTextStyle: TextStyle(
           color: Colors.black,
           fontSize: 28,
           fontWeight: FontWeight.w400,
         ),
          backgroundColor: Colors.blue,
        )
      ),
      home: const SplashScreen(),
    );
  }
}

_initializeFirebase() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}