import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app bar
      appBar: AppBar(
        leading: Icon(CupertinoIcons.home),
        title: const Text('Connect'),
        actions: [
          //search button
          IconButton(onPressed: (){}, icon: const Icon(Icons.search)),
          //more features button
          IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert)),
        ],
      ),

      //new chat button
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton(
          onPressed:
              () async {
                //sign out function
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
              },
          child: Icon(Icons.add_comment_rounded),


        ),
      ),
    );
  }
}
