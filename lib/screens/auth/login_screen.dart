import 'dart:io';

import 'package:connect/APIs/apis.dart';
import 'package:connect/helper/dialogs.dart';
import 'package:connect/screens/homescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;

  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(milliseconds: 10), (){
      setState(() {
        _isAnimate = true ;
      });
    });
  }

  _handleGoogleButtonClick(){

    //show progress bar
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
    //hide progress bar
      Navigator.pop(context);


      if(user != null){
        print('\nUser: ${user.user}');
        print('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if((await APIS.userExists())){
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }else{
          await APIS.createUser().then((value){
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
        Dialogs.showSnackbar(context, 'Sign In Successful');
    });
  }


  Future<UserCredential?> _signInWithGoogle() async {
    try{
      await InternetAddress.lookup('google.com');
  // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

  // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
  );
      Dialogs.showSnackbar(context, 'Check Connection');

      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign In Successful'),
      //   backgroundColor: Colors.amber,
      // ));

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
  }catch(e){
    print('\n_signInWithGoogle: $e}');
    print('\n_signInWithGoogle: $e}');
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something Went Wrong. Check Connection'), backgroundColor: Colors.cyan.withOpacity(0.8),));

    return null;
    }
  }

  // //sign out function
  //   _signOut() async {
  //   await FirebaseAuth.instance.signOut();
  //   await GoogleSignIn().signOut();
  //   }






  @override
  Widget build(BuildContext context) {
    // initializing media query for getting screen size
    // mq = MediaQuery.of(context).size;

    return Scaffold(
      //app bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome To Connect!'),

      ),
      body: Stack(
        children: [
          //app logo
          AnimatedPositioned(
            top: mq.height * 0.1,
              right: _isAnimate ? mq.width * 0.25 : -mq.width * 0.5,
              width: mq.width * 0.5,
              duration: const Duration(seconds: 2),
              // left: mq.width * 0.25,
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
                      _handleGoogleButtonClick();
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
            bottom: mq.height * 0.08,
            width: mq.width * 0.8,
            left: mq.width * 0.1,
            height: mq.height * 0.06,
            child: TextButton(onPressed: (){},
                child: const Text('Create a Google Account',
                  style: TextStyle(
                    // color: Colors.black,
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
