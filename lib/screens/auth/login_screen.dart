import 'dart:io';

import 'package:connect/APIs/apis.dart';
import 'package:connect/helper/dialogs.dart';
import 'package:connect/screens/language_select_screen.dart';
// import 'package:connect/screens/homescreen.dart';
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
  bool _isSigningIn = false; // Add loading state

  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(milliseconds: 10), (){
      if (mounted) {
        setState(() {
          _isAnimate = true;
        });
      }
    });
  }



  _handleGoogleButtonClick() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      //show progress bar
      Dialogs.showProgressBar(context);

      final user = await _signInWithGoogle();

      //hide progress bar
        Navigator.pop(context);

      // _signInWithGoogle().then((user) async {
      if (user != null) {
        print('\nUser: ${user.user}');
        print('\nUserAdditionalInfo: ${user.additionalUserInfo}');
        // Try direct ScaffoldMessenger instead of Dialogs.showSnackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign In Successful!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          // Give time for the success message to show
          await Future.delayed(const Duration(seconds: 2));
        }
          // Dialogs.showSnackbar(context, 'Sign In Successful');
          // Give time for the success message to show
          // await Future.delayed(const Duration(milliseconds: 1200));

        bool userExists = false;

        // int retryCount = 0;
        // const maxRetries = 3;
        //
        // while (retryCount < maxRetries) {

        try {
          userExists = await _checkUserExistsWithRetry();
          print('✅ New user created - StreamBuilder will handle navigation');
        } catch (e) {
          print('Failed to check user existence after all retries: $e');
          userExists = false;
        }



        if (!userExists) {
          try {
            await _createUserWithRetry();
            print('✅ New user created - StreamBuilder will handle navigation');
          } catch (e) {
            print('Failed to create user after all retries: $e');
            if (mounted) {
              // Clear any existing snack bars before showing error
              ScaffoldMessenger.of(context).clearSnackBars();
              await Future.delayed(const Duration(milliseconds: 100));
              Dialogs.showSnackbar(context,
                  'Account setup incomplete. Please try signing in again.');
            }
            return; // Exit early if we can't create the user
          }
        } else {
          print('✅ User exists - StreamBuilder will handle navigation');
        }
      } else {
        // Handle the case when sign-in fails or was cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          await Future.delayed(const Duration(milliseconds: 100));
          Dialogs.showSnackbar(
              context, 'Sign In was cancelled or failed. Please try again.');
        }
      }
    } catch (e) {
      print('Error in _handleGoogleButtonClick: $e');

      if (mounted) {
        // Make sure to pop progress dialog if it's still showing
        try {
          while(Navigator.canPop(context)){
            Navigator.pop(context);
            // Navigator.of(context, rootNavigator: true).popUntil((route) =>
            // route.isFirst);
          }
        } catch (popError) {
          print('Error managing dialogs: $popError');
        }

        // Clear any existing snack bars before showing error
        ScaffoldMessenger.of(context).clearSnackBars();
        await Future.delayed(const Duration(milliseconds: 100));


        // Show appropriate error message
        String errorMessage = 'Sign In Failed. Please try again.';
        if (e.toString().toLowerCase().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        Dialogs.showSnackbar(context, errorMessage);
      }
    }
    finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }


  // Helper method for checking user existence with retry
  Future<bool> _checkUserExistsWithRetry() async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await APIS.userExists();
      } catch (e) {
        retryCount++;
        print('Retry $retryCount for userExists: $e');
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        } else {
          rethrow; // Rethrow on final attempt
        }
      }
    }

    return false; // This shouldn't be reached
  }

  // Helper method for creating user with retry
  Future<void> _createUserWithRetry() async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await APIS.createUser();
        return; // Success, exit
      } catch (e) {
        retryCount++;
        print('Retry $retryCount for createUser: $e');
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        } else {
          rethrow; // Rethrow on final attempt
        }
      }
    }
  }



  Future<UserCredential?> _signInWithGoogle() async {
    try {

      await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10),
          onTimeout: () =>
          throw Exception('Network timeout - please check your connection')
      );

      // Clear any existing sign-in state
      await GoogleSignIn().signOut();

      // Add delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn()
          .signIn()
          .timeout(const Duration(seconds: 30),
          onTimeout: () =>
          throw Exception('Sign-in timeout - please try again')
      );

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser
          .authentication
          .timeout(const Duration(seconds: 15),
          onTimeout: () =>
          throw Exception('Authentication Timeout')
      );

      if (googleAuth?.accessToken == null || googleAuth?.idToken == null) {
        throw Exception('Failed to get authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential) .timeout(
          const Duration(seconds: 20), // Longer timeout for slow networks
          onTimeout: () => throw Exception('Firebase sign-in timeout'));

      // Wait a bit for Firebase to fully process the sign-in
      await Future.delayed(const Duration(milliseconds: 1000));

      return userCredential;
      // Once signed in, return the UserCredential
      // return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('\n_signInWithGoogle: $e}');


      if (mounted) {
        // String errorMessage = 'Something went wrong. Please try again.';
        //
        // if (e.toString().contains('network')) {
        //   errorMessage = 'Network error. Check your connection.';
        // } else if (e.toString().contains('cancelled')) {
        //   errorMessage = 'Sign in was cancelled.';
        // }

        Dialogs.showSnackbar(context, 'Check Connection');
      }
      return null;
    }
  }

  //   Dialogs.showSnackbar(context, 'Something Went Wrong. Check Connection');
  //   // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something Went Wrong. Check Connection'), backgroundColor: Colors.cyan.withOpacity(0.8),));
  //   return null;
  //   }
  // }

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
                  onPressed: _isSigningIn ? null : (){
                      _handleGoogleButtonClick();
                  },
                // google Icon
                  icon: _isSigningIn
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      :
                  Image.asset('assets/google.png',
                    height: mq.height * 0.06),

                  label: Text(
                    _isSigningIn ? 'Signing In...' : 'Sign In With Google',
                    style: const TextStyle(
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
