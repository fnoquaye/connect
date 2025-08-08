import 'dart:developer';

import 'package:connect/APIs/apis.dart';
import 'package:connect/helper/my_date_util.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../main.dart';
import '../models/messages.dart';

//for showing single message details
class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    return APIS.user.uid == widget.message.fromID
        ? _blueMessage()
        : _greyMessage();
  }
  //  Added function to format Firestore Timestamp
  // String _formatTime(String sentString) {
  //   try {
  //     final date = DateTime.parse(sentString); // <-- Fix: parse string to DateTime
  //     return DateFormat('h:mm a').format(date); // <-- Format: 9:24 AM
  //   } catch (e) {
  //     return ''; // fallback in case of parse error
  //   }
  // }
  // String getFormattedTime(Timestamp timestamp) {
  //   final date = timestamp.toDate();
  //   return DateFormat('h:mm a').format(date); // e.g., 3:45 PM
  // }
  // @override
  // Widget build(BuildContext context) {
  //   return APIS.user.uid == widget.message.fromID
  //   ? _blueMessage()
  //   : _greyMessage();
  // }



  //sender or another user message
Widget _greyMessage() {

    //update last read message if sender and receiver are different
  if(widget.message.read.isEmpty){
    APIS.updateMessageReadStatus(widget.message);
    log('message read updated');
  }



    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // message content
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: mq.width * 0.03, horizontal:  mq.width * 0.04),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04, vertical: mq.height * 0.01),
              decoration: BoxDecoration(
                color: Colors.white12,
                    border: Border.all(color: Colors.white12),
                    //making borders curved and well designed
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                )
              ),

              // actual text
              child: Text(
                  widget.message.msg,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
                ),
        ),

        //message time
        Padding(
          padding: EdgeInsets.only(right: mq.width * 0.04),
          child: Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent),
            style: TextStyle(
              fontSize: 13
            ),
          ),
        ),
      ],
    );
}

  //our or user message
Widget _blueMessage(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
            children: [
              //some space
              SizedBox(width: mq.width * 0.04),

              //double tick icon for message sent
              if (widget.message.read.isNotEmpty)
              Icon(Icons.done_all_rounded,
                color: Colors.blue,
              size: 20),
              //some space
              SizedBox(width: 2),

              //sent time
              Text(
               MyDateUtil.getFormattedTime(
                   context: context, time: widget.message.sent),
                style: TextStyle(
                    fontSize: 13
                ),
  ) ]),
              // message content
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: mq.width * 0.03, horizontal:  mq.width * 0.04),
                  margin: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.04, vertical: mq.height * 0.01),
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      border: Border.all(color: Colors.blue),
                      //making borders curved and well designed
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      )
                  ),

                  // actual text
                  child: Text(
                    widget.message.msg,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),


      ],
    );
}
}
