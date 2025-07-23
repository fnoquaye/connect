import 'package:connect/models/chat_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';

//card to rep a single user in home screen
class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width *0.01, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.5,
      child: InkWell(
        onTap: (){},
        child: ListTile(
          //profile picture
          leading: const CircleAvatar(child: Icon(CupertinoIcons.person)),
          //user name
          title: Text(widget.user.name),
          //last text
          subtitle: Text(widget.user.about, maxLines: 1),
          //last text time
          trailing: Text('12:00 PM',
              // style: TextStyle(color: Colors.black54)),
          ),
        ),
      ),
    );
  }
}
