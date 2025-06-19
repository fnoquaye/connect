import 'package:connect/screens/homescreen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<LoginScreen> {
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
              width: mq.width * 0.8,
              left: mq.width * 0.1,
              height: mq.height * 0.06,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan),
                  onPressed: (){
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()));
                  },
                // google Icon
                  icon: Image.asset('assets/google.png',
                    height: mq.height * 0.06,
                  ),
                  label: Text('Sign In With Google',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
              ),
          ),

          //create account button
          Positioned(
            bottom: mq.height * 0.06,
            width: mq.width * 0.8,
            left: mq.width * 0.1,
            height: mq.height * 0.06,
            child: TextButton(onPressed: (){},
                child: const Text('Create a Google Account',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,

                  ),
                )
            )
          ),
        ],
      ),
    );
  }
}
