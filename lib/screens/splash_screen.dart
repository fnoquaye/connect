import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';

//Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> {
  // bool _hasNavigated = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
    );
    // _initializeAndNavigate();
  }


  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Future<void> _initializeAndNavigate() async {
  //   try {
  //     // Exit fullscreen
  //     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  //     SystemChrome.setSystemUIOverlayStyle(
  //         const SystemUiOverlayStyle(
  //             systemNavigationBarColor: Colors.transparent,
  //             statusBarColor: Colors.transparent
  //         )
  //     );
  //
  //     // Start listening to auth state changes immediately
  //     _setupAuthListener();
  //
  //     // Wait for the splash screen display duration
  //     await Future.delayed(const Duration(milliseconds: 3500));
  //     // Wait for Firebase Auth to be ready and check auth state
  //
  //     // If we haven't navigated yet due to auth state changes, force a check
  //     if (!_hasNavigated && mounted) {
  //       await _performInitialAuthCheck();
  //     }
  //     // await _checkAuthStateAndNavigate();
  //   } catch (e) {
  //     log('❌ Splash screen error: $e');
  //     if (!_hasNavigated && mounted) {
  //       // If there's any error, default to login screen
  //       _navigateToLogin();
  //     }
  //   }
  // }

  // void _setupAuthListener() {
  //   _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
  //         (User? user) {
  //       if (!_hasNavigated && mounted) {
  //         if (user != null) {
  //           log('✅ Auth state changed - User authenticated: ${user.uid}');
  //           // _navigateToHome();
  //         } else {
  //           log('ℹ️ Auth state changed - No user authenticated');
  //           // Only navigate to login if we've waited long enough
  //           Future.delayed(const Duration(milliseconds: 3500), () {
  //             if (!_hasNavigated && mounted) {
  //               // _navigateToLogin();
  //             }
  //           });
  //         }
  //       }
  //     },
  //     onError: (error) {
  //       log('❌ Auth state listener error: $error');
  //       if (!_hasNavigated && mounted) {
  //         _navigateToLogin();
  //       }
  //     },
  //   );
  // }


  // Future<void> _performInitialAuthCheck() async {
  //   try {
  //     // Double-check current user state
  //     final currentUser = FirebaseAuth.instance.currentUser;
  //
  //     if (currentUser != null) {
  //       log('✅ Initial check - User authenticated: ${currentUser.uid}');
  //       _navigateToHome();
  //     } else {
  //       log('ℹ️ Initial check - No authenticated user found');
  //       _navigateToLogin();
  //     }
  //   } catch (e) {
  //     log('❌ Initial auth check error: $e');
  //     _navigateToLogin();
  //   }
  // }
  //
  // void _navigateToHome() {
  //   if (_hasNavigated || !mounted) return;
  //   _hasNavigated = true;
  //
  //   Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const HomeScreen())
  //   );
  // }
  //
  // void _navigateToLogin() {
  //   if (_hasNavigated || !mounted) return;
  //   _hasNavigated = true;
  //
  //   Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen())
  //   );
  // }

    // Future<void> _checkAuthStateAndNavigate() async {
    //   try {
    //     // Listen to auth state changes with a timeout
    //     final completer = Completer<User?>();
    //     late StreamSubscription<User?> subscription;
    //
    //     // Set up a timeout
    //     final timeout = Timer(const Duration(seconds: 5), () {
    //       if (!completer.isCompleted) {
    //         completer.complete(FirebaseAuth.instance.currentUser);
    //       }
    //     });
    //
    //     // Listen to auth state changes
    //     subscription =
    //         FirebaseAuth.instance.authStateChanges().listen((User? user) {
    //           if (!completer.isCompleted) {
    //             completer.complete(user);
    //           }
    //         });
    //
    //     // Wait for auth state or timeout
    //     final user = await completer.future;
    //
    //     // Clean up
    //     timeout.cancel();
    //     subscription.cancel();
    //
    //     if (!mounted) return;
    //
    //     if (user != null) {
    //       log('✅ User authenticated: ${user.uid}');
    //       _navigateToHome();
    //     } else {
    //       log('ℹ️ No authenticated user found');
    //       _navigateToLogin();
    //     }
    //   } catch (e) {
    //     log('❌ Auth state check error: $e');
    //     if (mounted) {
    //       _navigateToLogin();
    //     }
    //   }
    // }

    //   Future.delayed(const Duration(milliseconds: 3500),(){
    //     //exit fullscreen
    //     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    //     SystemChrome.setSystemUIOverlayStyle(
    //         const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent,
    //             statusBarColor: Colors.transparent));
    //
    //     if(FirebaseAuth.instance.currentUser != null){
    //       log('\nUser: ${FirebaseAuth.instance.currentUser}');
    //       // log('\nUserAdditionalInfo: ${FirebaseAuth.instance.currentUser.additionalUserInfo}');
    //       //navigate to home screen
    //       Navigator.pushReplacement(
    //           context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
    //     } else {
    //       //navigate to login screen
    //       Navigator.pushReplacement(
    //           context, MaterialPageRoute(builder: (_)=> const LoginScreen()));
    //     // //navigate to login screen
    //     // Navigator.pushReplacement(
    //     //     context, MaterialPageRoute(builder: (_)=> const LoginScreen()));
    //   );
    // }

    @override
    Widget build(BuildContext context) {
      mq = MediaQuery
          .of(context)
          .size;

      return Scaffold(
        //app bar
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Welcome To Connect!'),
        ),

        body: Stack(
          children: [
            //app logo
            Positioned(
                top: mq.height * 0.3,
                width: mq.width * 0.5,
                left: mq.width * 0.25,
                child: Image.asset('assets/chat.png')),

            //sign in button
            Positioned(
                bottom: mq.height * 0.15,
                width: mq.width,
                // left: mq.width * 0.1,
                // height: mq.height * 0.06,
                child: const Text('Live To Love😊',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    // color: Colors.white,
                    letterSpacing: 0.5,

                  ),
                )
            ),
          ],
        ),
      );
    }
  }

