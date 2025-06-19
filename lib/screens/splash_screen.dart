import 'package:connect/screens/homescreen.dart';
import 'package:flutter/material.dart';

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
    Future.delayed(const Duration(milliseconds: 1500),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
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
              top: mq.height * 0.1,
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
                color: Colors.black,
                letterSpacing: 0.5,

              ),
            )
          ),
        ],
      ),
    );
  }
}
