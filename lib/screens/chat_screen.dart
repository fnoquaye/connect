import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/models/chat_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        //app bar
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
        ),
        //body
        body: Column(),
      ),
    );
  }
  Widget _appBar(){
    return InkWell(
      onTap: (){},
      child: Row(
        children: [
          //back button
          IconButton(onPressed: (){Navigator.pop(context);},
              icon: const Icon(
                  Icons.arrow_back,)),

          //user profile picture
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * 0.03),
            child: CachedNetworkImage(
              width: mq.height * 0.05,
              height: mq.height * 0.05,
              imageUrl: widget.user.image,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person)),
            ),
          ),

          const SizedBox(width: 10),
          // Name and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 16,
                  // color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.user.isOnline ? Colors.green : Colors.red,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}


