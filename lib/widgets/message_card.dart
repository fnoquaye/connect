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
  String? displayText;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayText();
  }

  Future<void> _loadDisplayText() async {
    final text = await APIS.getDisplayText(widget.message);
    if (mounted) {
      setState(() {
        displayText = text;
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return APIS.user.uid == widget.message.fromID
        ? _blueMessage()
        : _greyMessage();
  }


  //sender or another user message
Widget _greyMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // message content
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: mq.width * 0.02, horizontal:  mq.width * 0.03),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04, vertical: mq.height * 0.01),
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF2C2C2E)  // iMessage dark mode incoming
                      : Color(0xFFE5E5EA), // iMessage light mode incoming (the signature grey)
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF2C2C2E)
                      : Color(0xFFE5E5EA)),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),    // iMessage uses 18px radius
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  )
              ),

              // actual text
              child: Text(
                displayText ?? "...",
                style: TextStyle(
                  fontSize: 14,
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
              fontSize: 10
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
              size: 15),
              //some space
              SizedBox(width: 2),

              //sent time
              Text(
               MyDateUtil.getFormattedTime(
                   context: context, time: widget.message.sent),
                style: TextStyle(
                    fontSize: 10
                ),
              )
            ]
        ),
              // message content
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: mq.width * 0.02, horizontal:  mq.width * 0.03),
                  margin: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.04, vertical: mq.height * 0.01),
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF0A84FF)  // iMessage dark mode blue
                          : Color(0xFF007AFF), // iMessage light mode blue
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF0A84FF)
                          : Color(0xFF007AFF)),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(1),
                      )
                  ),

                  // actual text
                  child: Text(
                    displayText ?? "...",
                    // widget.message.originalMsg,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),


      ],
    );
}
}
