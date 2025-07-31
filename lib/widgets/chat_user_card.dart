import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/screens/chat_screen.dart';
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
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
        },
        child: ListTile(
          //profile picture
          // leading: const CircleAvatar(child: Icon(CupertinoIcons.person)),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * 0.03),
            child: CachedNetworkImage(
              width: mq.height * 0.055,
              height: mq.height * 0.055,
              imageUrl: widget.user.image,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person)),
            ),
          ),

          //user name
          title: Text(widget.user.name),

          //last text
          subtitle: Text(widget.user.about, maxLines: 1),
          //last text time

          trailing: Container(
              width: 15,
              height: 15,
          ),
          // style: TextStyle(color: Colors.black54)),
          // trailing: Text('12:00 PM',
    // style: TextStyle(color: Colors.black54)),

          ),
        ),
    );
  }
}
