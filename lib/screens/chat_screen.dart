import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/models/messages.dart';
import 'package:connect/widgets/message_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../main.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 🔥 NEW: Cache streams to prevent recreation
  Stream<QuerySnapshot>? _messagesStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStatusStream;

  @override
  void initState() {
    super.initState();
    // Initialize streams once
    _messagesStream = APIS.getAllMessages(widget.user);
    _userStatusStream = APIS.getUserStatus(widget.user.id);
  }

  bool _isEmojiPickerVisible = false;

  //for storing all messages
  List<Message> _list = [];
  // for handling message text changes
  final TextEditingController _textController = TextEditingController();
  bool _isSending = false;

  // 🔥Track last text state to reduce rebuilds (PERFORMANCE FIX)
  bool _lastTextEmpty = true;

  Timer? _textChangeDebouncer;
  String _lastText = '';

  @override
  void dispose() {
    _textChangeDebouncer?.cancel(); // 🔥 NEW: Cancel debouncer
    _textController.dispose();
    super.dispose();
  }

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


                          // for (var message in _list) {
                          //   if (message.read.isEmpty && message.fromID != APIS.user.uid) {
                          //     log('Marking message as read: ${message.msg}');
                          //     APIS.updateMessageReadStatus(message);
                          //   }
                          // }

                          // 🔥 MODIFIED: Check and mark unread messages as read (moved outside of setState)
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _markUnreadMessagesAsRead();
                          });

                          if(_list.isNotEmpty){
                            return  ListView.builder(
                                itemCount: _list.length,
                                padding: EdgeInsets.symmetric(vertical: mq.height * 0.001, horizontal: mq.width * 0.005),
                                // padding: EdgeInsets.only(top: mq.height * 0.01),
                                physics: BouncingScrollPhysics(),
                                reverse: true,
                                // 🔥 NEW: Add item extent for better performance
                                itemExtent: null, // Let Flutter calculate
                                cacheExtent: 1000, // Cache more items
                                itemBuilder: (context, index){
                                  final reversedIndex = _list.length - 1 - index;
                                  return MessageCard(
                                      key:  ValueKey(_list[reversedIndex].sent), // Add key for better performance,
                                      message: _list[reversedIndex]
                                  );
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
              if (_isEmojiPickerVisible)  _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 NEW: Separate method to mark messages as read (PERFORMANCE FIX)
  void _markUnreadMessagesAsRead() {
    for (var message in _list) {
      if (message.read.isEmpty && message.fromID != APIS.user.uid) {
        log('Marking message as read: ${message.msg}');
        APIS.updateMessageReadStatus(message);
      }
    }
  }

  Widget _buildEmojiPicker(){
   return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {

          final currentText = _textController.text;
          final selection = _textController.selection;
          final newText = currentText.replaceRange(
            selection.start,
            selection.end,
            emoji.emoji,
          );

          _textController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: selection.start + emoji.emoji.length,
            ),
          );
          // _textController.text += emoji.emoji;
          // _textController.selection = TextSelection.fromPosition(
          //   TextPosition(offset: _textController.text.length),
          // );

          // 🔥 NEW: Update button state after emoji selection
          _handleTextChange(newText);
          // _handleTextChange(_textController.text);
        },
        // V4+ uses simple constructor parameters instead of Config object
        onBackspacePressed: () {
    final text = _textController.text;
    if (text.isNotEmpty) {
      final newText = text.characters.skipLast(1).toString();
      _textController.text = newText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      // onBackspacePressed: () {
      //   _textController
      //     ..text = _textController.text.characters.skipLast(1).toString()
      //     ..selection = TextSelection.fromPosition(
      //         TextPosition(offset: _textController.text.length));

      // 🔥 NEW: Update button state after backspace
      _handleTextChange(newText);
    }
    },
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
          // Name and status with cleaner StreamBuilder
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: APIS.getUserStatus(widget.user.id),
            builder: (context, snapshot){
              // Use the new parseUserStatus method for cleaner code
              final statusData = APIS.parseUserStatus(snapshot.data, widget.user);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusData['statusText'],
                    style: TextStyle(
                      fontSize: 13,
                      color: statusData['isOnline'] ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              );
            },
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

                      onChanged: _handleTextChange,
                        // setState(() {}); // to toggle send button

                      //   onChanged: (value) {
                      //   // // Only rebuild if send button state needs to change
                      //   // final isEmpty = value.trim().isEmpty;
                      //   // final wasEmpty = _lastTextEmpty ?? true;
                      //   //
                      //   // if (isEmpty != wasEmpty) {
                      //   //   setState(() {
                      //   //     _lastTextEmpty = isEmpty;
                      //   //   });
                      // },
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
              icon: _isSending // Add loading state variable
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )

                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _lastTextEmpty || _isSending // 🔥 CHANGED: Use _lastTextEmpty instead of checking text every time
              // onPressed: _textController.text.trim().isEmpty || _isSending // ✅ Disable when sending
                  ? null
                  : () async { // Make async
                final message = _textController.text.trim();

                setState(() {
                  _isSending = true; // Show loading
                });

                try {
                  final success = await APIS.sendMessage(widget.user, message, "fr");

                  if (success) {
                    _textController.clear();
                    // 🔥 NEW: Update text state after clearing
                    _handleTextChange('');
                    print('Message sent successfully');

                    // Hide emoji picker after sending
                    if (_isEmojiPickerVisible) {
                      setState(() {
                        _isEmojiPickerVisible = false;
                      });
                    }
                  } else {
                    // Show error to user

                    if (mounted){ // 🔥 NEW: Check if widget is still mounted (CRASH FIX)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send message')),
                      );
                    }
                  }
                }  catch (e) {
                  log('Error sending message: $e');
                  if (mounted) { // 🔥 NEW: Check if widget is still mounted (CRASH FIX)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error sending message')),
                    );
                  }
                } finally {

                 if (mounted){
                   setState(() {
                     _isSending = false; // Hide loading
                  });
                }
                }
              },
            ),
          ),
          // CircleAvatar(
          //   backgroundColor: Theme.of(context).colorScheme.primary,
          //   child: IconButton(
          //     icon:
          //     const Icon(Icons.send, color: Colors.white),
          //     onPressed: _textController.text.trim().isEmpty
          //         ? null
          //         : () {
          //       final message = _textController.text.trim();
          //       // if (_textController.text.isNotEmpty){
          //       APIS.sendMessage(widget.user, message,"fr");
          //       // }
          //       print('Sending: ${message}');
          //       _textController.clear();
          //       // Hide emoji picker after sending
          //       if (_isEmojiPickerVisible) {
          //         setState(() {
          //           _isEmojiPickerVisible = false;
          //         });
          //       }
          //       setState(() {}); // to disable send button again
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }


  // 🔥 NEW: Optimized text change handler (PERFORMANCE FIX - reduces rebuilds)
  void _handleTextChange(String value) {

    // Skip if the text hasn't actually changed
    if (value == _lastText) return;
    // 🔥 NEW: Update last text immediately to prevent unnecessary calls
    _lastText = value;

    // 🔥 NEW: Debounce rapid typing to prevent crashes
    _textChangeDebouncer?.cancel();
    _textChangeDebouncer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final isEmpty = value.trim().isEmpty;
      if (isEmpty != _lastTextEmpty && mounted) {
        setState(() {
          _lastTextEmpty = isEmpty;
        });
      }
    });
    //
    // final isEmpty = value.trim().isEmpty;
    // if (isEmpty != _lastTextEmpty) {
    //   setState(() {
    //     _lastTextEmpty = isEmpty;
    //   });
    // }
  }

}