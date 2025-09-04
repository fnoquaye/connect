import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/helper/my_date_util.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/screens/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../main.dart';
import '../models/messages.dart';

//card to rep a single user in home screen
class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {

  // last message info (if null --> no message)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * 0.01, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.5,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user))
          );
        },
              child: StreamBuilder(
                // **Last message for display**
                stream: APIS.getLastMessage(widget.user),
                builder: (context, snapshot) {
                  final messageData = snapshot.data?.docs;
                  final messageList = messageData?.map((e) => Message.fromJson(e.data())).toList() ?? [];

                  if (messageList.isNotEmpty) {
                    _message = messageList[0];
                  } else {
                    _message = null;
                  }
                  // end

                  // layout
                  return Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(mq.height * 0.03),
                            child: CachedNetworkImage(
                              width: mq.height * 0.055,
                              height: mq.height * 0.055,
                              imageUrl: widget.user.image,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                              const CircleAvatar(child: Icon(CupertinoIcons.person)),
                            ),
                          ),
                          title: Text(widget.user.name),
                          subtitle: Text(
                            _message != null
                                ? (_message!.fromID == APIS.user.uid
                                ?_message!.originalMsg
                                :_message!.msg)
                                : widget.user.about,
                            maxLines: 1,
                          ),
                          trailing: null, // Trailing handled by separate StreamBuilder
                        ),
                      ),

                      // **Separate StreamBuilder for unread count**
                      StreamBuilder(
                        stream: APIS.getAllMessagesForUnreadCount(widget.user),
                        builder: (context, snapshot) {
                          final unreadData = snapshot.data?.docs;
                          final unreadCount = unreadData?.length ?? 0;

                          if (unreadCount > 0) {
                            return Container(
                              margin: EdgeInsets.only(right: 16),
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: TextStyle(
                                  // color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else {
                            // Show message time when no unread
                            return Container(
                              margin: EdgeInsets.only(right: 16),
                              child:
                              _message != null
                                  ? Text(
                                MyDateUtil.getLastMessageTime(
                                  context: context,
                                  time: _message!.sent,
                                ),
                                style: TextStyle(fontSize: 14),
                              )
                                  : SizedBox.shrink(),
                            );
                        }
                      },
                    ),
                  ],
                );
              },
              ),
      ),
    );
  }
}


    //   StreamBuilder(
    //     stream: APIS.getLastMessage(widget.user),
    //     builder: (context, snapshot) {
    //       final data = snapshot.data?.docs;
    //       final list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
    //
    //       if (list.isNotEmpty) {
    //         final message = list[0];
    //         return Text(
    //           MyDateUtil.getLastMessageTime(
    //             context: context,
    //             time: message.sent,
    //           ),
    //           style: TextStyle(fontSize: 14),
    //         );
    //       }
    //       return SizedBox.shrink();
    //     },
    //   ),
    // );


    // return Card(
    //   margin: EdgeInsets.symmetric(horizontal: mq.width *0.01, vertical: 4),
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    //   elevation: 0.5,
    //   child: InkWell(
    //     onTap: (){
    //       Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
    //     },
    //     child: StreamBuilder(
    //         stream: APIS.getLastMessage(widget.user),
    //         builder: (context, snapshot) {
    //           final data = snapshot.data?.docs;
    //           final list =
    //               data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
    //
    //           // get last message for display
    //           if (list.isNotEmpty){
    //             _message = list[0];
    //           } else {
    //             _message = null;
    //           }
    //
    //           // // Count unread messages
    //           // int unreadCount = 0;
    //           // for (var message in list) {
    //           //   if (message.read.isEmpty &&
    //           //       message.fromID != APIS.user.uid &&
    //           //       message.toID == APIS.user.uid) {  // **IMPORTANT: Check toID**
    //           //     unreadCount++;
    //           //   }
    //           // }
    //
    //           return ListTile(
    //             //profile picture
    //             // leading: const CircleAvatar(child: Icon(CupertinoIcons.person)),
    //             leading: ClipRRect(
    //               borderRadius: BorderRadius.circular(mq.height * 0.03),
    //               child: CachedNetworkImage(
    //                 width: mq.height * 0.055,
    //                 height: mq.height * 0.055,
    //                 imageUrl: widget.user.image,
    //                 placeholder: (context, url) => CircularProgressIndicator(),
    //                 errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person)),
    //               ),
    //             ),
    //
    //             //user name
    //             title: Text(widget.user.name),
    //
    //             //last text
    //             subtitle: Text(
    //               _message != null ? _message!.msg
    //                 : widget.user.about, maxLines: 1),
    //
    //
    //             //last text time
    //
    //             trailing: null,
    //             // trailing: _message == null
    //             //     ? null // show nothing when no message is sent
    //             //     : _message!.read.isEmpty &&
    //             //         _message!.fromID != APIS.user.uid
    //             //     ?
    //             //     // show unread messages
    //             //     Container(
    //             //         width: 15,
    //             //         height: 15,
    //             //         decoration: BoxDecoration(
    //             //           color: Colors.blueGrey.shade400,
    //             //           borderRadius: BorderRadius.circular(10)
    //             //         ),
    //             //       )
    //             //     // message sent time
    //             //         : Text(
    //             //         MyDateUtil.getLastMessageTime(
    //             //             context: context, time: _message!.sent),
    //             //         style: TextStyle(
    //             //           fontSize: 14,
    //             //         ),
    //             //     ),
    //           );
    //         },
    //         ),
    //     ),
    //
    // );
