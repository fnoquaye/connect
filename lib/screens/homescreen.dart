// import 'dart:convert';
// import 'dart:developer';

import 'package:connect/APIs/apis.dart';
import 'package:connect/screens/auth/login_screen.dart';
import 'package:connect/screens/profile_screen.dart';
import 'package:connect/widgets/chat_user_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
import '../models/chat_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 List<ChatUser> list = [];
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
          IconButton(onPressed: (){
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: list[0])));
          }, icon: const Icon(Icons.more_vert)),
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
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
              },
          child: Icon(Icons.add_comment_rounded),


        ),
      ),

      body: StreamBuilder(
          stream: APIS.firestore.collection('users').snapshots(),
          builder: (context, snapshot){
            switch (snapshot.connectionState){
              //if data is loading
              case  ConnectionState.waiting:
              case ConnectionState.none:
                return const Center(
                  child: CircularProgressIndicator(),
                );

              //if some or all data is loaded then show it
              case ConnectionState.active:
              case ConnectionState.done:
            // if(snapshot.hasData){
                final data = snapshot.data?.docs;
                  list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

                  if(list.isNotEmpty){
                    return  ListView.builder(
                        itemCount: list.length,
                        padding: EdgeInsets.symmetric(vertical: mq.height * 0.001, horizontal: mq.width * 0.005),
                        // padding: EdgeInsets.only(top: mq.height * 0.01),
                        physics: BouncingScrollPhysics(),
                        // padding: EdgeInsets.all(2.0),
                        itemBuilder: (context, index){
                          return ChatUserCard(
                            user: list[index],
                          );
                        }
                    );
                  }else{
                    return const Center(
                      child: Text('No Connections Found\n''Start A new Conversation',
                        style: TextStyle(
                          fontSize: 20,

                        ),
                      ),
                    );
                  }
                // for(var i in data!){
                //   log('Data: ${jsonEncode(i.data())}');
                //   list.add(i.data()['name']);
                // }
              }



            }


    )
    );
  }
}
