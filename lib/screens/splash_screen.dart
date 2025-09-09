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
  }


  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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

