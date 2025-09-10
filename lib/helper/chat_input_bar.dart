// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../APIs/apis.dart';
// import '../models/chat_user.dart';
// import '../models/messages.dart';
// import 'dialogs.dart';
//
// class ChatInputBar extends StatefulWidget {
//   final ChatUser recipient;
//   final ValueNotifier<bool> isEmojiPickerVisible;
//   final TextEditingController textController;
//   final Future<void> Function(String) onSend;
//   final Function(String) onTextChanged;
//
//   const ChatInputBar({
//
//   super.key,
//   required this.recipient,
//   required this.isEmojiPickerVisible,
//   required this.textController,
//   required this.onSend,
//   required this.onTextChanged,
// });
//
//   @override
//   State<ChatInputBar> createState() => _ChatInputBarState();
// }
//
// class _ChatInputBarState extends State<ChatInputBar> {
//   bool _isSending = false; // Tracks if a message is being sent
//   final ValueNotifier<bool> _isTextEmpty = ValueNotifier(true); // Tracks if input is empty
//   Timer? _debouncer; // Debounces text changes
//   bool _isImageUploading = false;
//   bool _imageUploadFailed = false;
//
//
//   @override
//   void dispose() {
//     _debouncer?.cancel();
//     _isTextEmpty.dispose();
//     super.dispose();
//   }
//
//   void _handleTextChange(String value) {
//     final isEmpty = value.trim().isEmpty;
//     if (_isTextEmpty.value != isEmpty) {
//       _isTextEmpty.value = isEmpty;
//     }
//
//     widget.onTextChanged(value); // Notify parent
//     _debouncer?.cancel();
//     _debouncer = Timer(const Duration(milliseconds: 150), () {});
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Reply Preview
//           ValueListenableBuilder<Message?>(
//             valueListenable: replyToMessageNotifier,
//             builder: (context, replyMsg, child) {
//               if (replyMsg == null) return const SizedBox.shrink();
//               return _buildReplyPreview(replyMsg);
//             },
//           ),
//
//           // Edit Preview
//           ValueListenableBuilder<Message?>(
//             valueListenable: editingMessageNotifier,
//             builder: (context, editMsg, child) {
//               if (editMsg == null) return const SizedBox.shrink();
//               return _buildEditPreview(editMsg);
//             },
//           ),
//
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(30),
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//
//                   child: Row(
//                     children: [
//                       //emoji
//                       IconButton(
//                         icon: ValueListenableBuilder<bool>(
//                          valueListenable: widget.isEmojiPickerVisible,
//                           builder: (context, isVisible, child) {
//                             return Icon(
//                               isVisible
//                                   ? Icons.keyboard
//                                   : Icons.emoji_emotions_outlined,
//                               color: Theme
//                                   .of(context)
//                                   .colorScheme
//                                   .primary,
//                             );
//                           }),
//                         onPressed: () {
//                           widget.isEmojiPickerVisible.value = !widget.isEmojiPickerVisible.value;
//                           if (widget.isEmojiPickerVisible.value) {
//                             FocusScope.of(context).unfocus();
//                           }
//                         },
//                       ),
//                       // text field
//                       Expanded(
//                         child: TextField(
//                           controller: widget.textController,
//                           maxLines: null,
//                           decoration: const InputDecoration(
//                             hintText: 'Type a message...',
//                             border: InputBorder.none,
//                           ),
//                           onChanged: _handleTextChange,
//                           onTap: () {
//                             if (widget.isEmojiPickerVisible.value) {
//                               widget.isEmojiPickerVisible.value = false;
//                             }
//                           },
//                         ),
//                       ),
//                       //attachment
//                       IconButton(
//                           icon: _isImageUploading
//                           ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2)
//                           ) : const Icon(Icons.attach_file),
//                           onPressed: _isImageUploading ? null: () async {
//                             await _sendImageMessage();
//                           }
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 6),
//               _buildSendButton(),
//
//               // CircleAvatar(
//               //   backgroundColor: Theme.of(context).colorScheme.primary,
//               //   child: ValueListenableBuilder<bool>(
//               //     valueListenable: _isTextEmpty,
//               //     builder: (context, isEmpty, child) {
//               //       return IconButton(
//               //         icon: _isSending
//               //             ? const SizedBox(
//               //           width: 20,
//               //           height: 20,
//               //           child: CircularProgressIndicator(
//               //             color: Colors.white,
//               //             strokeWidth: 2,
//               //           ),
//               //         )
//               //             : const Icon(Icons.send, color: Colors.white),
//               //         onPressed: isEmpty || _isSending
//               //             ? null
//               //             : () async {
//               //           final msg = widget.textController.text.trim();
//               //           if (msg.isEmpty) return;
//               //
//               //           widget.textController.clear();
//               //           _handleTextChange('');
//               //           setState(() => _isSending = true);
//               //
//               //           await widget.onSend(msg);
//               //           if (mounted) setState(() => _isSending = false);
//               //         },
//               //       );
//               //     },
//               //   ),
//               // ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getHintText() {
//     if (editingMessageNotifier.value != null) {
//       return 'Edit message...';
//     } else if (replyToMessageNotifier.value != null) {
//       return 'Reply to message...';
//     }
//     return 'Type a message...';
//   }
//
//   Widget _buildSendButton(){
//     return CircleAvatar(
//       backgroundColor: Theme.of(context).colorScheme.primary,
//       child: ValueListenableBuilder<bool>(
//         valueListenable: _isTextEmpty,
//         builder: (context, isEmpty, child) {
//           return IconButton(
//             icon: _isSending
//                 ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//                 strokeWidth: 2,
//               ),
//             )
//                 : Icon(
//               editingMessageNotifier.value != null
//                   ? Icons.check  // Check icon for edit
//                   : Icons.send,   // Send icon for normal/reply
//               color: Colors.white,
//             ),
//             onPressed: isEmpty || _isSending
//                 ? null
//                 : () async {
//               final msg = widget.textController.text.trim();
//               if (msg.isEmpty) return;
//
//               widget.textController.clear();
//               _handleTextChange('');
//               setState(() => _isSending = true);
//
//               try {
//                 // Handle edit
//                 if (editingMessageNotifier.value != null) {
//                   final message = editingMessageNotifier.value!;
//                   final success = await APIS.editMessage(
//                     widget.recipient.id,
//                     message.sent,
//                     msg,
//                   );
//                   if (success) {
//                     editingMessageNotifier.value = null;
//                     _showSuccessMessage('Message edited');
//                   } else {
//                     _showErrorMessage('Failed to edit message');
//                   }
//                 }
//                 // Handle reply
//                 else if (replyToMessageNotifier.value != null) {
//                   final replyMsg = replyToMessageNotifier.value!;
//                   final success = await APIS.replyToMessage(
//                     widget.recipient,
//                     msg,
//                     replyMsg,
//                   );
//                   if (success) {
//                     replyToMessageNotifier.value = null;
//                     _showSuccessMessage('Reply sent');
//                   } else {
//                     _showErrorMessage('Failed to send reply');
//                   }
//                 }
//                 // Normal send
//                 else {
//                   final success = await APIS.sendMessage(widget.recipient, msg);
//                   if (!success) {
//                     _showErrorMessage('Failed to send message');
//                   }
//                 }
//               } catch (e) {
//                 _showErrorMessage('Error: ${e.toString()}');
//               }
//
//               if (mounted) setState(() => _isSending = false);
//             },
//           );
//         },
//       ),
//     );
//     // return CircleAvatar(
//     //   backgroundColor: Theme.of(context).colorScheme.primary,
//     //   child: ValueListenableBuilder<bool>(
//     //     valueListenable: _isTextEmpty,
//     //     builder: (context, isEmpty, child) {
//     //       return IconButton(
//     //         icon: _isSending
//     //             ? const SizedBox(
//     //           width: 20,
//     //           height: 20,
//     //           child: CircularProgressIndicator(
//     //             color: Colors.white,
//     //             strokeWidth: 2,
//     //           ),
//     //         )
//     //             : const Icon(
//     //
//     //             Icons.send, color: Colors.white),
//     //         onPressed: isEmpty || _isSending
//     //             ? null
//     //             : () async {
//     //           final msg = widget.textController.text.trim();
//     //           if (msg.isEmpty) return;
//     //
//     //           widget.textController.clear();
//     //           _handleTextChange('');
//     //           setState(() => _isSending = true);
//     //
//     //           // Handle edit
//     //           if (editingMessageNotifier.value != null) {
//     //             final message = editingMessageNotifier.value!;
//     //             await APIS.updateMessage(widget.recipient, message, msg);
//     //             editingMessageNotifier.value = null;
//     //           }
//     //           // Handle reply
//     //           else if (replyToMessageNotifier.value != null) {
//     //             final replyMsg = replyToMessageNotifier.value!;
//     //             await APIS.sendMessage(widget.recipient, msg, replyToMessage: replyMsg);
//     //             replyToMessageNotifier.value = null;
//     //           }
//     //           // Normal send
//     //           else {
//     //             await APIS.sendMessage(widget.recipient, msg);
//     //           }
//     //
//     //           if (mounted) setState(() => _isSending = false);
//     //         },
//     //       );
//     //     },
//     //   ),
//     // );
//   }
//   void _showSuccessMessage(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   void _showErrorMessage(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }
//
//   Widget _buildReplyPreview(Message msg) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               'Replying to: ${msg.originalMsg}',
//               style: const TextStyle(fontSize: 12, color: Colors.black54),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close, size: 16),
//             onPressed: () => replyToMessageNotifier.value = null,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEditPreview(Message msg) {
//     // Pre-fill text controller with original message when editing starts
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (widget.textController.text != msg.originalMsg) {
//         widget.textController.text = msg.originalMsg;
//         widget.textController.selection = TextSelection.fromPosition(
//           TextPosition(offset: msg.originalMsg.length),
//         );
//         _handleTextChange(msg.originalMsg);
//       }
//     });
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.orange[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               'Editing: ${msg.originalMsg}',
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black87,
//                 fontStyle: FontStyle.italic,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close, size: 16),
//             onPressed: () => editingMessageNotifier.value = null,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // The image sending method (similar to your _uploadToCloudinary)
//   Future<void> _sendImageMessage() async {
//     try {
//       print('🚀 Starting image send process...');
//       // Pick an image
//       final picker = ImagePicker();
//       print('📷 Opening image picker...');
//       final picked = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//         maxWidth: 1920,
//         maxHeight: 1920,
//       );
//
//       if (picked != null) {
//         print('✅ Image picked: ${picked.path}');
//         print('📊 File size: ${await File(picked.path).length()} bytes');
//
//         setState(() {
//           _isImageUploading = true;
//           _imageUploadFailed = false;
//         });
//
//         // Upload to Cloudinary
//         print('☁️ Starting Cloudinary upload...');
//         String? imageUrl = await APIS.uploadImageToCloudinary(File(picked.path));
//         print('📥 Upload result: $imageUrl');
//
//         if (imageUrl != null) {
//           // Send message as image
//           final success = await APIS.sendMessage(
//             widget.recipient, // or however you access chatUser
//             "", // empty text for image
//             imageUrl: imageUrl,
//             type: MessageType.image,
//           );
//
//           print('📤 Send message result: $success');
//
//           setState(() {
//             _isImageUploading = false;
//           });
//
//           if (success) {
//             print('✅ Image sent successfully');
//             await Future.delayed(const Duration(milliseconds: 300));
//             // Optional success feedback
//             // Dialogs.showSnackbar(context, 'Image sent successfully');
//           } else {
//             print('❌ Failed to send message to Firestore');
//             Dialogs.showSnackbar(context, 'Failed to send image message');
//           }
//         } else {
//           print('❌ Upload failed - imageUrl is null or empty');
//           setState(() {
//             _isImageUploading = false;
//             // _imageUploadFailed = true;
//           });
//           Dialogs.showSnackbar(context, 'Failed to upload image. Please try again.');
//         }
//       } else {
//         // User cancelled - no need to show error
//         print('📷 User cancelled image selection');
//       }
//     } catch (e) {
//       setState(() {
//         _isImageUploading = false;
//       });
//       print('❌ Error in image sending process: $e');
//       Dialogs.showSnackbar(context, 'Error selecting image. Please try again.');
//     }
//   }
//
//
// }

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../APIs/apis.dart';
import '../models/chat_user.dart';
import '../models/messages.dart';
import '../helper/chat_input_controller.dart'; // Import the controller
import 'dialogs.dart';

class ChatInputBar extends StatefulWidget {
  final ChatUser recipient;
  final ValueNotifier<bool> isEmojiPickerVisible;
  final TextEditingController textController;
  final Future<void> Function(String) onSend;
  final Function(String) onTextChanged;

  const ChatInputBar({
    super.key,
    required this.recipient,
    required this.isEmojiPickerVisible,
    required this.textController,
    required this.onSend,
    required this.onTextChanged,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isSending = false;
  final ValueNotifier<bool> _isTextEmpty = ValueNotifier(true);
  Timer? _debouncer;
  bool _isImageUploading = false;

  @override
  void dispose() {
    _debouncer?.cancel();
    _isTextEmpty.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    final isEmpty = value.trim().isEmpty;
    if (_isTextEmpty.value != isEmpty) {
      _isTextEmpty.value = isEmpty;
    }

    widget.onTextChanged(value);
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 150), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply Preview
          ValueListenableBuilder<Message?>(
            valueListenable: ChatInputController.replyToMessageNotifier,
            builder: (context, replyMsg, child) {
              if (replyMsg == null) return const SizedBox.shrink();
              return _buildReplyPreview(replyMsg);
            },
          ),

          // Edit Preview
          ValueListenableBuilder<Message?>(
            valueListenable: ChatInputController.editingMessageNotifier,
            builder: (context, editMsg, child) {
              if (editMsg == null) return const SizedBox.shrink();
              return _buildEditPreview(editMsg);
            },
          ),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(30),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: ValueListenableBuilder<bool>(
                            valueListenable: widget.isEmojiPickerVisible,
                            builder: (context, isVisible, child) {
                              return Icon(
                                isVisible
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              );
                            }),
                        onPressed: () {
                          widget.isEmojiPickerVisible.value = !widget.isEmojiPickerVisible.value;
                          if (widget.isEmojiPickerVisible.value) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.textController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: _getHintText(),
                            border: InputBorder.none,
                          ),
                          onChanged: _handleTextChange,
                          onTap: () {
                            if (widget.isEmojiPickerVisible.value) {
                              widget.isEmojiPickerVisible.value = false;
                            }
                          },
                        ),
                      ),
                      IconButton(
                          icon: _isImageUploading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)
                          )
                              : const Icon(Icons.attach_file),
                          onPressed: _isImageUploading ? null : () async {
                            await _sendImageMessage();
                          }
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    if (ChatInputController.editingMessageNotifier.value != null) {
      return 'Edit message...';
    } else if (ChatInputController.replyToMessageNotifier.value != null) {
      return 'Reply to message...';
    }
    return 'Type a message...';
  }

  Widget _buildSendButton() {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isTextEmpty,
        builder: (context, isEmpty, child) {
          return IconButton(
            icon: _isSending
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(
              ChatInputController.editingMessageNotifier.value != null
                  ? Icons.check  // Check icon for edit
                  : Icons.send,   // Send icon for normal/reply
              color: Colors.white,
            ),
            onPressed: isEmpty || _isSending
                ? null
                : () async {
              final msg = widget.textController.text.trim();
              if (msg.isEmpty) return;

              widget.textController.clear();
              _handleTextChange('');
              setState(() => _isSending = true);

              try {
                // Handle edit
                if (ChatInputController.editingMessageNotifier.value != null) {
                  final message = ChatInputController.editingMessageNotifier.value!;
                  final success = await APIS.editMessage(
                    widget.recipient.id,
                    message.sent,
                    msg,
                  );
                  if (success) {
                    ChatInputController.editingMessageNotifier.value = null;
                    _showSuccessMessage('Message edited');
                  } else {
                    _showErrorMessage('Failed to edit message');
                  }
                }
                // Handle reply
                else if (ChatInputController.replyToMessageNotifier.value != null) {
                  final replyMsg = ChatInputController.replyToMessageNotifier.value!;
                  final success = await APIS.replyToMessage(
                    widget.recipient,
                    msg,
                    replyMsg,
                  );
                  if (success) {
                    ChatInputController.replyToMessageNotifier.value = null;
                    _showSuccessMessage('Reply sent');
                  } else {
                    _showErrorMessage('Failed to send reply');
                  }
                }
                // Normal send
                else {
                  final success = await APIS.sendMessage(widget.recipient, msg);
                  if (!success) {
                    _showErrorMessage('Failed to send message');
                  }
                }
              } catch (e) {
                _showErrorMessage('Error: ${e.toString()}');
              }

              if (mounted) setState(() => _isSending = false);
            },
          );
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildReplyPreview(Message msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.originalMsg,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.blue.shade700),
            onPressed: () => ChatInputController.replyToMessageNotifier.value = null,
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview(Message msg) {
    // Pre-fill text controller with original message when editing starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.textController.text != msg.originalMsg) {
        widget.textController.text = msg.originalMsg;
        widget.textController.selection = TextSelection.fromPosition(
          TextPosition(offset: msg.originalMsg.length),
        );
        _handleTextChange(msg.originalMsg);
      }
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing message:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.originalMsg,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.orange.shade700),
            onPressed: () {
              ChatInputController.editingMessageNotifier.value = null;
              widget.textController.clear();
              _handleTextChange('');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendImageMessage() async {
    try {
      print('🚀 Starting image send process...');
      final picker = ImagePicker();
      print('📷 Opening image picker...');
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (picked != null) {
        print('✅ Image picked: ${picked.path}');
        print('📊 File size: ${await File(picked.path).length()} bytes');

        setState(() {
          _isImageUploading = true;
        });

        print('☁️ Starting Cloudinary upload...');
        String? imageUrl = await APIS.uploadImageToCloudinary(File(picked.path));
        print('📥 Upload result: $imageUrl');

        if (imageUrl != null) {
          final success = await APIS.sendMessage(
            widget.recipient,
            "",
            imageUrl: imageUrl,
            type: MessageType.image,
          );

          print('📤 Send message result: $success');

          setState(() {
            _isImageUploading = false;
          });

          if (success) {
            print('✅ Image sent successfully');
            await Future.delayed(const Duration(milliseconds: 300));
          } else {
            print('❌ Failed to send message to Firestore');
            Dialogs.showSnackbar(context, 'Failed to send image message');
          }
        } else {
          print('❌ Upload failed - imageUrl is null or empty');
          setState(() {
            _isImageUploading = false;
          });
          Dialogs.showSnackbar(context, 'Failed to upload image. Please try again.');
        }
      } else {
        print('📷 User cancelled image selection');
      }
    } catch (e) {
      setState(() {
        _isImageUploading = false;
      });
      print('❌ Error in image sending process: $e');
      Dialogs.showSnackbar(context, 'Error selecting image. Please try again.');
    }
  }
}
