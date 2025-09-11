import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect/screens/user_profile_screen.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/models/messages.dart';
import 'package:connect/widgets/message_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../helper/chat_input_bar.dart';
import '../helper/chat_input_controller.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final ValueNotifier<bool> _isTextEmpty = ValueNotifier(true);

  // Cache streams to prevent recreation
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStatusStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userProfileStream; // NEW: Real-time user profile

  // String _selectedTargetLanguage = 'fr'; // Default to French
  final String targetLang = APIS.me.preferredLanguage ?? 'en';

  @override
  void initState() {
    super.initState();
    // _loadFullUser();
    // Initialize streams once
    _messagesStream = APIS.getAllMessages(widget.user);
    _userStatusStream = APIS.getUserStatus(widget.user.id);
    _userProfileStream = APIS.getUserProfileStream(widget.user.id); // NEW: Real-time profile stream
  }

  final ValueNotifier<bool> _isEmojiPickerVisible = ValueNotifier(false);

  //for storing all messages
  List<Message> _list = [];
  // for handling message text changes
  final TextEditingController _textController = TextEditingController();
  Timer? _textChangeDebouncer;
  String _lastText = '';

  @override
  void dispose() {
    _textChangeDebouncer?.cancel(); // 🔥 NEW: Cancel debouncer
    _textController.dispose();
    _isEmojiPickerVisible.dispose();
    _isTextEmpty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Already handled
        // **SMART BACK BUTTON LOGIC: Handle emoji picker/keyboard before exiting**
        if (_isEmojiPickerVisible.value) {
          // Close emoji picker first
          _isEmojiPickerVisible.value = false;
          // _isEmojiPickerVisible.value = !_isEmojiPickerVisible.value;

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
                    stream: _messagesStream,
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
                                      message: _list[reversedIndex],
                                      onReply: (msg){
                                        ChatInputController.setReplyMessage(msg);
                                        // Focus text field
                                        _textController.text = '';
                                        FocusScope.of(context).requestFocus();
                                      },
                                    onEdit: (msg){
                                      ChatInputController.setEditMessage(msg);
                                      FocusScope.of(context).requestFocus();
                                    },
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

              ChatInputBar(
                recipient: widget.user,
                isEmojiPickerVisible: _isEmojiPickerVisible,
                textController: _textController,
                onTextChanged: _handleTextChange,
                onSend: (msg) async => await APIS.sendMessage(widget.user, msg),
              ),

              // Fixed emoji picker for v4.3.0 syntax
              ValueListenableBuilder<bool>(
                valueListenable: _isEmojiPickerVisible,
                builder: (context, isVisible, child) {
                  return isVisible ? _buildEmojiPicker() : const SizedBox.shrink();
                },
              )
              // if (_isEmojiPickerVisible)  _buildEmojiPicker(),
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
          _handleTextChange(newText);
        },
        onBackspacePressed: () {
    final text = _textController.text;
    if (text.isNotEmpty) {
      final newText = text.characters.skipLast(1).toString();
      _textController.text = newText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      // 🔥 NEW: Update button state after backspace
      _handleTextChange(newText);
    }
    },
      ),
    );
  }

  Widget _appBar(){
    // 🔥 FIXED: Use StreamBuilder for real-time user profile updates
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userProfileStream,
      builder: (context, profileSnapshot) {
        // Get the most up-to-date user data
        ChatUser currentUser = widget.user;
        if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
          currentUser = ChatUser.fromJson(profileSnapshot.data!.data()!);
        }

        final imageUrl = (currentUser.image.isNotEmpty) ? currentUser.image : '';

        return InkWell(
          onTap: () {
            // Always use the most current user data for navigation
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(user: currentUser),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              IconButton(
                  onPressed: (){Navigator.pop(context);},
                  icon: const Icon(Icons.arrow_back,)
              ),

              // User profile picture with real-time updates
              imageUrl.isEmpty
                  ? const CircleAvatar(child: Icon(CupertinoIcons.person))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * 0.03),
                child: CachedNetworkImage(
                  width: mq.height * 0.05,
                  height: mq.height * 0.05,
                  imageUrl: imageUrl,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => CircleAvatar(
                      child: Icon(CupertinoIcons.person)),
                ),
              ),

              const SizedBox(width: 10),

              // Name and status with real-time updates
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _userStatusStream,
                  builder: (context, snapshot){
                    final statusData = APIS.parseUserStatus(snapshot.data, currentUser);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentUser.name, // Use current user data
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Widget _appBar(){
  //   final imageUrl = (_fullUser?.image != null && _fullUser!.image.isNotEmpty)
  //       ? _fullUser!.image
  //       : '';
  //   return InkWell(
  //     onTap: () async {
  //       final fullUser = await APIS.getUserById(widget.user.id);
  //       if(fullUser != null){
  //         // Navigate to UserProfileScreen when tapping on user info
  //         Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => UserProfileScreen(user: fullUser),
  //             ),
  //       );
  //     } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("Unable to load user profile")),
  //         );
  //       }
  //       },
  //     borderRadius: BorderRadius.circular(8),
  //     child: Row(
  //       children: [
  //         //back button
  //         IconButton(
  //             onPressed: (){Navigator.pop(context);},
  //             icon: const Icon(Icons.arrow_back,)
  //         ),
  //         //user profile picture
  //         imageUrl.isEmpty
  //             ? const CircleAvatar(child: Icon(CupertinoIcons.person))
  //             :
  //         ClipRRect(
  //           borderRadius: BorderRadius.circular(mq.height * 0.03),
  //           child: CachedNetworkImage(
  //             width: mq.height * 0.05,
  //             height: mq.height * 0.05,
  //             imageUrl: imageUrl,
  //             placeholder: (context, url) => CircularProgressIndicator(),
  //             errorWidget: (context, url, error) => CircleAvatar(
  //                 child: Icon(CupertinoIcons.person)),
  //           ),
  //         ),
  //
  //         const SizedBox(width: 10),
  //
  //         // Name and status with cleaner StreamBuilder
  //         Expanded(
  //           child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  //             stream: _userStatusStream,
  //             builder: (context, snapshot){
  //               // Use the new parseUserStatus method for cleaner code
  //               final statusData = APIS.parseUserStatus(snapshot.data, widget.user);
  //
  //               return Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     widget.user.name,
  //                     style: const TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 2),
  //                   Text(
  //                     statusData['statusText'],
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: statusData['isOnline'] ? Colors.green : Colors.grey,
  //                     ),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // 🔥 NEW: Optimized text change handler (PERFORMANCE FIX - reduces rebuilds)
  void _handleTextChange(String value) {
    final isEmpty = value.trim().isEmpty;

    if (value == _lastText) return;
    _lastText = value;

    if (_isTextEmpty.value != isEmpty) {
      _isTextEmpty.value = isEmpty;
    }
    // 🔥 NEW: Debounce rapid typing to prevent crashes
    _textChangeDebouncer?.cancel();
    _textChangeDebouncer = Timer(const Duration(milliseconds: 150), () {
    });
  }
}