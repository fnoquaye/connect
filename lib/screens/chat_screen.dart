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

  // String _selectedTargetLanguage = 'fr'; // Default to French
  String _myPreferredLanguage = 'en';

// Simple language options
  final Map<String, String> _languages = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'hi': 'Hindi',
    'sw': 'Swahili',
  };

  @override
  void initState() {
    super.initState();
    // Initialize streams once
    _messagesStream = APIS.getAllMessages(widget.user);
    _userStatusStream = APIS.getUserStatus(widget.user.id);

    // Load current user's preferred language
    _loadMyPreferredLanguage();
  }

  Future<void> _loadMyPreferredLanguage() async {
    final preferredLang = await APIS.getUserPreferredLanguage(APIS.user.uid);
    if (mounted) {
      setState(() {
        _myPreferredLanguage = preferredLang;
      });
    }
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
          IconButton(
              onPressed: (){Navigator.pop(context);},
              icon: const Icon(Icons.arrow_back,)
          ),

          //user profile picture
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * 0.03),
            child: CachedNetworkImage(
              width: mq.height * 0.05,
              height: mq.height * 0.05,
              imageUrl: widget.user.image,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => CircleAvatar(
                  child: Icon(CupertinoIcons.person)),
            ),
          ),

          const SizedBox(width: 10),

          // Name and status with cleaner StreamBuilder
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
            ),
          ),

          //Language Selector Button
          IconButton(
            onPressed: _showMyLanguagePreference,
            icon: Icon(Icons.translate),
            tooltip: 'Select Language (${_languages[_myPreferredLanguage]})',
          ),
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

                  // // Add this to your _chatInput() method after the attach file button:
                  // IconButton(
                  //   icon: Icon(Icons.bug_report),
                  //   onPressed: () async {
                  //     print('🧪 Testing translation server...');
                  //     await APIS.testTranslation();
                  //   },
                  // ),

                  // Add this temporarily to your _chatInput() method or anywhere in your UI
                  // ElevatedButton(
                  //   onPressed: () async {
                  //     print('Testing server connectivity...');
                  //     await APIS.testServerConnectivity();
                  //   },
                  //   child: Text('Test Server'),
                  // ),

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
              onPressed: _lastTextEmpty || _isSending //
                  ? null
                  : () async { // Make async
                final message = _textController.text.trim();

                // DEBUG: Check language values
                print('🔍 DEBUG SEND:');
                print('  - _myPreferredLanguage: "$_myPreferredLanguage"');
                print('  - widget.user.preferredLanguage: "${widget.user.preferredLanguage}"');
                print('  - widget.user.preferredLanguage.isEmpty: ${widget.user.preferredLanguage?.isEmpty}');

                // Immediately clear the text field and update state
                _textController.clear();

                setState(() {
                  _isSending = true; // Show loading
                  _lastTextEmpty = true; // Reset text state immediately
                });

                // Cancel any pending debouncer
                _textChangeDebouncer?.cancel();
                _lastText = '';

                try {
                  final success = await APIS.sendMessage(widget.user, message)
                      .timeout( const Duration(seconds: 10),
                    onTimeout: (){
                      print('❌ Send message timeout');
                      return false;
                    }
                  );

                  if (success) {
                   if (mounted){
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
                   }
                  } else {
                    // Show error to user
                    if (mounted){ // Check if widget is still mounted (CRASH FIX)
                      _textController.text = message; // Restore the message
                      _handleTextChange(message); // Update button state

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send message')),
                      );
                    }
                  }
                }  catch (e) {
                  log('Error sending message: $e');
                  if (mounted) { // 🔥 NEW: Check if widget is still mounted (CRASH FIX)

                    if (mounted) {
                      // Restore the message on error
                      _textController.text = message;
                      _handleTextChange(message);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending message: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }

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

    // Update button state immediately for better UX
    final isEmpty = value.trim().isEmpty;
    if (isEmpty != _lastTextEmpty) {
      setState(() {
        _lastTextEmpty = isEmpty;
      });
    }

    // 🔥 NEW: Debounce rapid typing to prevent crashes
    _textChangeDebouncer?.cancel();
    _textChangeDebouncer = Timer(const Duration(milliseconds: 150), () {
    });
  }

  // UPDATED: Language preference selector (for current user)
  void _showMyLanguagePreference() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('My Language Preference'),
        content: Container(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final langCode = _languages.keys.elementAt(index);
              final langName = _languages[langCode]!;

              return RadioListTile<String>(
                title: Text(langName),
                subtitle: Text('I want to receive messages in $langName'),
                value: langCode,
                groupValue: _myPreferredLanguage,
                onChanged: (value) async {
                  // Update in Firestore
                  await APIS.updateMyPreferredLanguage(value!);

                  setState(() {
                    _myPreferredLanguage = value;
                  });

                  Navigator.pop(context);

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language preference updated to $langName')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

  // Add this method to show language picker
  // void _showLanguagePicker() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Select Translation Language'),
  //       content: Container(
  //         width: double.minPositive,
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: _languages.length,
  //           itemBuilder: (context, index) {
  //             final langCode = _languages.keys.elementAt(index);
  //             final langName = _languages[langCode]!;
  //
  //             return RadioListTile<String>(
  //               title: Text(langName),
  //               value: langCode,
  //               groupValue: _selectedTargetLanguage,
  //               onChanged: (value) {
  //                 setState(() {
  //                   _selectedTargetLanguage = value!;
  //                 });
  //                 Navigator.pop(context);
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
//
// final isEmpty = value.trim().isEmpty;
// if (isEmpty != _lastTextEmpty) {
//   setState(() {
//     _lastTextEmpty = isEmpty;
//   });
// }
