// import 'dart:convert';
// import 'dart:developer';
// import 'package:awesome_emoji_picker/awesome_emoji_picker.dart';


import 'dart:developer';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/models/messages.dart';
import 'package:connect/widgets/message_card.dart';
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
  bool _isEmojiPickerVisible = false;


  //for storing all messages
  List<Message> _list = [];
  // for handling message text changes
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Already handled
        // **SMART BACK BUTTON LOGIC: Handle emoji picker/keyboard before exiting**
        if (_isEmojiPickerVisible) {
          // Close emoji picker first
          setState(() {
            _isEmojiPickerVisible = false;
          });
        } else if (FocusScope.of(context).hasFocus) {
          // Close keyboard if it's open
          FocusScope.of(context).unfocus();
        } else {
          // Nothing is open, safe to go back
          Navigator.pop(context);
        }
      },

      child: SafeArea(
        child: Scaffold(
          //app bar
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: _appBar(),
          ),
          //body
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  // stream: APIS.firestore.collection('users').snapshots(),
                    stream: APIS.getAllMessages(widget.user),
                  //   stream: Stream.empty(),
                    builder: (context, snapshot){
                      switch (snapshot.connectionState){
                      //if data is loading
                        case  ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                      //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                        // if(snapshot.hasData){
                          final data = snapshot.data?.docs;

                          _list = data
                              ?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                              [];

                          // Check and mark unread messages as read
                          for (var message in _list) {
                            if (message.read.isEmpty && message.fromID != APIS.user.uid) {
                              log('Marking message as read: ${message.msg}');
                              APIS.updateMessageReadStatus(message);
                            }
                          }
                          // log('Data: ${jsonEncode(data![0].data())}');



                          // _list.clear();
                          // _list.add(Message(toID: 'xyz', msg: 'hello', read: '', type: '', fromID: APIS.user.uid, sent: '12:00 AM'));
                          // _list.add(Message(toID: APIS.user.uid, msg: 'hello', read: '', type: '', fromID: 'xyz', sent: '12:00 AM'));

                          if(_list.isNotEmpty){
                            return  ListView.builder(
                                itemCount: _list.length,
                                padding: EdgeInsets.symmetric(vertical: mq.height * 0.001, horizontal: mq.width * 0.005),
                                // padding: EdgeInsets.only(top: mq.height * 0.01),
                                physics: BouncingScrollPhysics(),
                                reverse: true,
                                // padding: EdgeInsets.all(2.0),
                                itemBuilder: (context, index){
                                  final reversedIndex = _list.length - 1 - index;
                                  return MessageCard(message: _list[reversedIndex]);
                                }
                            );
                          }else{
                            return const Center(
                              child: Text('No Conversations Found\n''Start A new Conversation',
                                style: TextStyle(
                                  fontSize: 20,

                                ),
                              ),
                            );
                          }
                      }
                    }
                ),
              ),


              _chatInput(),

              // Fixed emoji picker for v4.3.0 syntax
              if (_isEmojiPickerVisible)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (Category? category, Emoji emoji) {
                      _textController.text += emoji.emoji;
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _textController.text.length),
                      );
                    },
                    // V4+ uses simple constructor parameters instead of Config object
                    onBackspacePressed: () {
                      _textController
                        ..text = _textController.text.characters.skipLast(1).toString()
                        ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length));
                    },
                  ),
                ),


            ],
          ),
        ),
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


  Widget _chatInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme.
                surfaceContainerHighest.
                withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [


                  // Emoji icon
                  IconButton(
                    icon: Icon(
                      _isEmojiPickerVisible
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                        // Icons.emoji_emotions_outlined),
              ),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: (){
                      // Show the emoji picker
                      setState(() {
                        _isEmojiPickerVisible = !_isEmojiPickerVisible;
                        if (_isEmojiPickerVisible) FocusScope.of(context).unfocus();
                      });
                    },
                  ),



                  // Text input field
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onTap: () {
                        // Hide emoji picker when text field is focused
                        if (_isEmojiPickerVisible) {
                          setState(() {
                            _isEmojiPickerVisible = false;
                          });
                        }
                      },
                      onChanged: (value) {
                        setState(() {}); // to toggle send button
                      },
                    ),
                  ),



                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // TODO: Handle file/media picker
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),



          // Send button
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _textController.text.trim().isEmpty
                  ? null
                  : () {
                final message = _textController.text.trim();
                // if (_textController.text.isNotEmpty){
                    APIS.sendMessage(widget.user, message);
              // }
                print('Sending: ${message}');
                _textController.clear();
                // Hide emoji picker after sending
                if (_isEmojiPickerVisible) {
                  setState(() {
                    _isEmojiPickerVisible = false;
                  });
                }
                setState(() {}); // to disable send button again
              },
            ),
          ),
        ],
      ),
    );
  }
}


// final emoji = await AwesomeEmojiPicker.pickEmoji(
//   context: context,
//   config: const EmojiPickerConfig(
//     columns: 8,
//     emojiSizeMax: 32,
//     enableSkinTones: true,
//     recentsLimit: 28,
//   ),
// );
// if (emoji != null) {
//   _textController.text += emoji.emoji; // Append to existing text
//   _textController.selection = TextSelection.fromPosition(
//     TextPosition(offset: _textController.text.length),
//   );
// }