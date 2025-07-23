import 'dart:developer';

import 'package:connect/screens/auth/login_screen.dart';
import 'package:connect/screens/homescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:connect/screens/homescreen.dart';
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
  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500),(){
      //exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

      if(FirebaseAuth.instance.currentUser != null){
        log('\nUser: ${FirebaseAuth.instance.currentUser}');
        // log('\nUserAdditionalInfo: ${FirebaseAuth.instance.currentUser.additionalUserInfo}');
        //navigate to home screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
      } else {
        //navigate to login screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_)=> const LoginScreen()));
      }

      // //navigate to login screen
      // Navigator.pushReplacement(
      //     context, MaterialPageRoute(builder: (_)=> const LoginScreen()));
    });
  }



  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

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
