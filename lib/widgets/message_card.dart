// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:connect/APIs/apis.dart';
// import 'package:connect/helper/my_date_util.dart';
// import 'package:connect/screens/fullscreen_image_viewer.dart';
// import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// import '../main.dart';
// import '../models/messages.dart';
//
// //for showing single message details
// class MessageCard extends StatefulWidget {
//   const MessageCard({super.key, required this.message, this.onReply, this.onEdit});
//   final Message message;
//   final Function(Message)? onReply;
//   final Function(Message)? onEdit;
//
//   @override
//   State<MessageCard> createState() => _MessageCardState();
// }
//
// class _MessageCardState extends State<MessageCard> {
//   String? displayText;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.message.type == MessageType.text) {
//       _loadDisplayText();
//     } else {
//       // For image messages, no need to load text
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _loadDisplayText() async {
//     final text = await APIS.getDisplayText(widget.message);
//     if (mounted) {
//       setState(() {
//         displayText = text;
//         isLoading = false;
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return APIS.user.uid == widget.message.fromID
//         ? _blueMessage()
//         : _greyMessage();
//   }
//
//   // Build message content based on type
//   Widget _buildMessageContent() {
//     if (widget.message.type == MessageType.image) {
//       return _buildImageContent();
//     } else {
//       return _buildTextContent();
//     }
//   }
//
//   Widget _buildImageContent(){
//     if(widget.message.imageUrl == null || widget.message.imageUrl!.isEmpty){
//       return Container(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Icon(Icons.broken_image, size: 50, color: Colors.grey),
//             Text('Image not available', style: TextStyle(color: Colors.grey)),
//           ],
//         ),
//       );
//     }
//
//     return GestureDetector(
//       onTap: (){
//         Navigator.push(context,
//             MaterialPageRoute(builder: (context) => FullScreenImageViewer(
//             imageUrl: widget.message.imageUrl!,
//             senderName: APIS.user.uid == widget.message.fromID ? "You" : null,
//             timestamp: MyDateUtil.getFormattedTime(context: context, time: widget.message.sent)
//             ),
//             ),
//         );
//       },
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: CachedNetworkImage(
//           imageUrl: widget.message.imageUrl!,
//           width: mq.width * 0.6,
//           fit: BoxFit.cover,
//           placeholder: (context, url) => Container(
//             width: mq.width * 0.6,
//             height: 200,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Center(
//               child: CircularProgressIndicator(),
//             ),
//           ),
//           errorWidget: (context, url, error) => Container(
//             width: mq.width * 0.6,
//             height: 200,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error, color: Colors.red, size: 40),
//                 Text('Failed to load image', style: TextStyle(color: Colors.red)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextContent() {
//     return Text(
//       displayText ?? "...",
//       style: TextStyle(
//         fontSize: 14,
//         color: APIS.user.uid == widget.message.fromID ? Colors.white : null,
//       ),
//     );
//   }
//
//   //sender or another user message
// Widget _greyMessage() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // message content
//         Flexible(
//           child: Container(
//             padding: EdgeInsets.symmetric(
//                 vertical: mq.width * 0.02,
//                 horizontal: widget.message.type == MessageType.image
//                     ? mq.width * 0.01
//                     : mq.width * 0.03),
//             margin: EdgeInsets.symmetric(
//               horizontal: mq.width * 0.04, vertical: mq.height * 0.01),
//               decoration: BoxDecoration(
//                   color: Theme.of(context).brightness == Brightness.dark
//                       ? Color(0xFF2C2C2E)  // iMessage dark mode incoming
//                       : Color(0xFFE5E5EA), // iMessage light mode incoming (the signature grey)
//                   border: Border.all(color: Theme.of(context).brightness == Brightness.dark
//                       ? Color(0xFF2C2C2E)
//                       : Color(0xFFE5E5EA)),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(18),    // iMessage uses 18px radius
//                     topRight: Radius.circular(18),
//                     bottomRight: Radius.circular(18),
//                   )
//               ),
//
//               // actual content
//               child: _buildMessageContent(),
//           ),
//         ),
//
//         //message time
//         Padding(
//           padding: EdgeInsets.only(right: mq.width * 0.04),
//           child: Text(
//             MyDateUtil.getFormattedTime(
//                 context: context, time: widget.message.sent),
//             style: TextStyle(
//               fontSize: 10
//             ),
//           ),
//         ),
//       ],
//     );
// }
//
//   //our or user message
// Widget _blueMessage(){
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//             children: [
//               //some space
//               SizedBox(width: mq.width * 0.04),
//
//               //double tick icon for message sent
//               if (widget.message.read.isNotEmpty)
//               Icon(Icons.done_all_rounded,
//                 color: Colors.blue,
//               size: 15),
//               //some space
//               SizedBox(width: 2),
//
//               //sent time
//               Text(
//                MyDateUtil.getFormattedTime(
//                    context: context, time: widget.message.sent),
//                 style: TextStyle(
//                     fontSize: 10
//                 ),
//               )
//             ]
//         ),
//               // message content
//               Flexible(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                       vertical: mq.width * 0.02,
//                       horizontal: widget.message.type == MessageType.image
//                           ? mq.width * 0.01
//                           : mq.width * 0.03),
//                   margin: EdgeInsets.symmetric(
//                       horizontal: mq.width * 0.04, vertical: mq.height * 0.01),
//                   decoration: BoxDecoration(
//                       color: Theme.of(context).brightness == Brightness.dark
//                           ? Color(0xFF0A84FF)  // iMessage dark mode blue
//                           : Color(0xFF007AFF), // iMessage light mode blue
//                       border: Border.all(color: Theme.of(context).brightness == Brightness.dark
//                           ? Color(0xFF0A84FF)
//                           : Color(0xFF007AFF)),
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(18),
//                         topRight: Radius.circular(18),
//                         bottomLeft: Radius.circular(18),
//                         bottomRight: Radius.circular(1),
//                       )
//                   ),
//
//                   // actual content
//                   child: _buildMessageContent(),
//                 ),
//               ),
//
//
//       ],
//     );
// }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';

import '../APIs/apis.dart';
import '../models/chat_user.dart';
import '../models/messages.dart';
import '../main.dart';
import '../helper/my_date_util.dart';
import '../screens/fullscreen_image_viewer.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  final Function(Message)? onReply;
  final Function(Message)? onEdit;

  const MessageCard({
    super.key,
    required this.message,
    this.onReply,
    this.onEdit,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  String? _displayText;
  bool _isLoadingText = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayText();
  }

  Future<void> _loadDisplayText() async {
    if (widget.message.type == MessageType.text && !widget.message.isDeleted) {
      setState(() => _isLoadingText = true);
      try {
        final text = await APIS.getDisplayText(widget.message);
        if (mounted) {
          setState(() {
            _displayText = text;
            _isLoadingText = false;
          });
        }
      } catch (e) {
        log('Error loading display text: $e');
        if (mounted) {
          setState(() {
            _displayText = widget.message.originalMsg;
            _isLoadingText = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = APIS.user.uid == widget.message.fromID;

    return Column(
      children: [
        // Reply context (if this message is a reply)
        if (widget.message.replyToMessage != null) ...[
          _buildReplyContext(),
          const SizedBox(height: 4),
        ],

        // Main message
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (isMe) const Spacer(flex: 1),

            // Message bubble
            Flexible(
              flex: 3,
              child: GestureDetector(
                onLongPress: () => _showMessageOptions(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: mq.width * 0.02,
                      horizontal: widget.message.type == MessageType.image
                          ? mq.width * 0.01
                          : mq.width * 0.03),
                  margin: EdgeInsets.symmetric(
                    horizontal: mq.width * 0.04,
                    vertical: mq.height * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: widget.message.isDeleted
                        ? Colors.grey
                        : isMe
                        ? (Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF0A84FF)  // iMessage dark mode blue
                        : Color(0xFF007AFF)) // iMessage light mode blue
                        : (Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF2C2C2E)  // iMessage dark mode incoming
                        : Color(0xFFE5E5EA)), // iMessage light mode incoming (the signature grey)
                    border: Border.all(
                      color: widget.message.isDeleted
                          ? Colors.grey
                          : isMe
                          ? (Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF0A84FF)
                          : Color(0xFF007AFF))
                          : (Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF2C2C2E)
                          : Color(0xFFE5E5EA)),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),    // iMessage uses 18px radius
                      topRight: Radius.circular(18),
                      bottomLeft: isMe
                          ? Radius.circular(18)
                          : Radius.circular(2),
                      bottomRight: isMe
                          ? Radius.circular(1)
                          : Radius.circular(18),
                    ),
                  ),
                  child: widget.message.isDeleted
                      ? _buildDeletedMessage()
                      : widget.message.type == MessageType.text
                      ? _buildTextMessage(isMe)
                      : _buildImageMessage(),
                ),
              ),
            ),

            if (!isMe) const Spacer(flex: 1),
          ],
        ),

        // Message info (time, edited status, read status)
        _buildMessageInfo(isMe),
      ],
    );
  }

  Widget _buildReplyContext() {
    bool isMe = APIS.user.uid == widget.message.fromID;

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isMe) const Spacer(flex: 1),

        Flexible(
          flex: 3,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04,
              vertical: mq.height * 0.005,
            ),
            margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04),
            decoration: BoxDecoration(
              color: (isMe ? Colors.lightBlue.shade50 : Colors.grey.shade100),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                left: BorderSide(
                  color: isMe ? Colors.lightBlue : Colors.grey,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.message.replyToMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        if (!isMe) const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildTextMessage(bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingText)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            _displayText ?? widget.message.originalMsg,
            style: TextStyle(
              fontSize: 14,
              color: isMe ? Colors.white : null,
            ),
          ),
      ],
    );
  }

  Widget _buildImageMessage() {
    if(widget.message.imageUrl == null || widget.message.imageUrl!.isEmpty){
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.grey),
            Text('Image not available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => FullScreenImageViewer(
              imageUrl: widget.message.imageUrl!,
              senderName: APIS.user.uid == widget.message.fromID ? "You" : null,
              timestamp: MyDateUtil.getFormattedTime(context: context, time: widget.message.sent)
          ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.message.imageUrl!,
          width: mq.width * 0.6,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: mq.width * 0.6,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: mq.width * 0.6,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 40),
                Text('Failed to load image', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          'This message was deleted',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInfo(bool isMe) {
    return Padding(
      padding: EdgeInsets.only(
        right: isMe ? mq.width * 0.04 : 0,
        left: isMe ? 0 : mq.width * 0.04,
        top: 2,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Edit indicator
          if (widget.message.isEdited) ...[
            Text(
              'edited',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Time
          Text(
            _formatTime(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),

          // Read status for sent messages
          if (isMe && !widget.message.isDeleted) ...[
            const SizedBox(width: 4),
            Icon(
              widget.message.read.isEmpty ? Icons.done : Icons.done_all,
              color: widget.message.read.isEmpty ? Colors.grey : Colors.blue,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime() {
    final sent = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.message.sent));
    return '${sent.hour}:${sent.minute.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions(BuildContext context) {
    final isMe = APIS.user.uid == widget.message.fromID;

    // Debug logging
    log('Message isDeleted: ${widget.message.isDeleted}');
    log('Can delete: ${APIS.canPerformMessageAction(widget.message, 'delete')}');
    log('Can edit: ${APIS.canPerformMessageAction(widget.message, 'edit')}');
    log('Can reply: ${APIS.canPerformMessageAction(widget.message, 'reply')}');

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply option
            if (!widget.message.isDeleted)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onReply != null) {
                    widget.onReply!(widget.message);
                  }
                },
              ),

            // Copy option for text messages
            if (widget.message.type == MessageType.text && !widget.message.isDeleted)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(
                    text: _displayText ?? widget.message.originalMsg,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied')),
                  );
                },
              ),

            // Edit option (only for own messages, text only, within time limit)
            if (isMe && APIS.canPerformMessageAction(widget.message, 'edit'))
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onEdit != null) {
                    widget.onEdit!(widget.message);
                  }
                },
              ),

            // Delete option
            if (APIS.canPerformMessageAction(widget.message, 'delete'))
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, isMe);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isMyMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text(isMyMessage
            ? 'How do you want to delete this message?'
            : 'Delete this message for yourself?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (!isMyMessage) ...[
            // For other users' messages, only "Delete for me" option
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(false);
              },
              child: const Text('Delete for me'),
            ),
          ] else ...[
            // For your own messages, both options
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(false);
              },
              child: const Text('Delete for me'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(true);
              },
              child: const Text('Delete for everyone'),
            ),
          ],
        ],
      ),
    );
  }

  void _deleteMessage(bool deleteForEveryone) async {
    try {
      final chatUserId = widget.message.toID == APIS.user.uid
          ? widget.message.fromID
          : widget.message.toID;

      final success = await APIS.deleteMessage(
        chatUserId,
        widget.message.sent,
        deleteForEveryone,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              deleteForEveryone
                  ? 'Message deleted for everyone'
                  : 'Message deleted for you'
          )),
        );
      }
    } catch (e) {
      log('Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete message')),
        );
      }
    }
  }
}



