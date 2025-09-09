import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/models/languages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat_user.dart';

// Screen to view another user's profile (read-only)
class UserProfileScreen extends StatefulWidget {
  final ChatUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar
      appBar: AppBar(
        title: Text('${widget.user.name}\'s Profile'),
        actions: [
          // Call button instead of chat
          IconButton(
              onPressed: () {
                _showCallOptions();
              },
              icon: const Icon(Icons.call)
          ),
          IconButton(
              onPressed: () {
                // More options menu
                _showMoreOptions();
              },
              icon: const Icon(Icons.more_vert)
          ),
        ],
      ),

      // Body
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Space
              SizedBox(width: mq.width, height: mq.height * 0.03),

              // Profile picture (read-only)
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * 0.1),
                child: CachedNetworkImage(
                  width: mq.height * 0.2,
                  height: mq.height * 0.2,
                  fit: BoxFit.cover,
                  imageUrl: widget.user.image,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const CircleAvatar(
                      child: Icon(CupertinoIcons.person)
                  ),
                ),
              ),

              SizedBox(width: mq.width, height: mq.height * 0.03),

              // User name
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(width: mq.width, height: mq.height * 0.02),

              // User email
              Text(
                widget.user.email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              SizedBox(width: mq.width, height: mq.height * 0.04),

              // User info cards
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'About',
                content: widget.user.about.isEmpty ? 'No information available' : widget.user.about,
              ),

              SizedBox(width: mq.width, height: mq.height * 0.02),

              _buildInfoCard(
                icon: Icons.language,
                title: 'Preferred Language',
                content: _getLanguageDisplayName(),
              ),

              SizedBox(width: mq.width, height: mq.height * 0.02),

              _buildInfoCard(
                icon: Icons.access_time,
                title: 'Status',
                content: '',
                isStatusCard: true,
              ),

              SizedBox(width: mq.width, height: mq.height * 0.02),

              _buildInfoCard(
                icon: Icons.person_add,
                title: 'Joined',
                content: _getJoinedText(),
              ),

              SizedBox(width: mq.width, height: mq.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build info cards
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    bool isStatusCard = false,
  }) {
    if (isStatusCard) {
      // Use StreamBuilder for real-time status updates
      return StreamBuilder(
        stream: APIS.getUserStatus(widget.user.id),
        builder: (context, snapshot) {
          final statusData = APIS.parseUserStatus(snapshot.data, widget.user);
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(icon, color: Colors.blue),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                statusData['statusText'],
                style: TextStyle(
                  fontSize: 14,
                  color: statusData['isOnline'] ? Colors.green : Colors.grey,
                ),
              ),
              trailing: statusData['isOnline']
                  ? const Icon(Icons.circle, color: Colors.green, size: 12)
                  : null,
            ),
          );
        },
      );
    }

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          content,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  // Get language display name using LanguageConstants
  String _getLanguageDisplayName() {
    final langCode = widget.user.preferredLanguage;

    // Handle null or empty language codes
    if (langCode == null || langCode.isEmpty) {
      return 'English'; // Default fallback
    }

    // Use LanguageConstants to get proper display name
    if (LanguageConstants.isSupported(langCode)) {
      return LanguageConstants.getFullDisplayName(langCode);
    } else {
      // Handle unsupported language codes
      return 'Unknown Language ($langCode)';
    }
  }

  // Get joined date text
  String _getJoinedText() {
    if (widget.user.createdAt != null) {
      final joinDate = widget.user.createdAt!;
      final now = DateTime.now();
      final difference = now.difference(joinDate);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'Member for ${years}y';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'Member for ${months}mo';
      } else if (difference.inDays > 0) {
        return 'Member for ${difference.inDays}d';
      } else {
        return 'New member';
      }
    }
    return 'Member since ${DateTime.now().year}';
  }

  // Show call options modal
  void _showCallOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: mq.height * 0.02,
            bottom: mq.height * 0.05,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Call ${widget.user.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Voice Call Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.call, color: Colors.green, size: 28),
                ),
                title: const Text(
                  'Voice Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Make an audio call'),
                onTap: () {
                  Navigator.pop(context);
                  _startVoiceCall();
                },
              ),

              const SizedBox(height: 16),

              // Video Call Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam, color: Colors.blue, size: 28),
                ),
                title: const Text(
                  'Video Call',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Make a video call'),
                onTap: () {
                  Navigator.pop(context);
                  _startVideoCall();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Start voice call
  void _startVoiceCall() {
    // Implement voice call functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting voice call with ${widget.user.name}...'),
        backgroundColor: Colors.green,
      ),
    );
    log('Starting voice call with ${widget.user.id}');
  }

  // Start video call
  void _startVideoCall() {
    // Implement video call functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting video call with ${widget.user.name}...'),
        backgroundColor: Colors.blue,
      ),
    );
    log('Starting video call with ${widget.user.id}');
  }

  // Show more options bottom sheet
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            top: mq.height * 0.02,
            bottom: mq.height * 0.05,
          ),
          children: [
            const Text(
              'More Options',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.call, color: Colors.green),
              title: const Text('Voice Call'),
              onTap: () {
                Navigator.pop(context);
                _startVoiceCall();
              },
            ),

            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.blue),
              title: const Text('Video Call'),
              onTap: () {
                Navigator.pop(context);
                _startVideoCall();
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation();
              },
            ),

            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
          ],
        );
      },
    );
  }

  // Show block confirmation dialog
  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser();
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Block user functionality
  void _blockUser() async {
    try {
      // You can implement blocking logic here using your APIS
      // For now, showing a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.user.name} has been blocked'),
          backgroundColor: Colors.red,
        ),
      );
      log('Blocked user: ${widget.user.id}');
    } catch (e) {
      log('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to block user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Report user functionality
  void _reportUser() async {
    try {
      // You can implement reporting logic here using your APIS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.user.name} has been reported'),
          backgroundColor: Colors.orange,
        ),
      );
      log('Reported user: ${widget.user.id}');
    } catch (e) {
      log('Error reporting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to report user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


// import 'dart:developer';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:connect/models/languages.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import '../main.dart';
// import '../models/chat_user.dart';
//
//
// // Screen to view another user's profile (read-only)
// class UserProfileScreen extends StatefulWidget {
//   final ChatUser user;
//
//   const UserProfileScreen({super.key, required this.user});
//
//   @override
//   State<UserProfileScreen> createState() => _UserProfileScreenState();
// }
//
// class _UserProfileScreenState extends State<UserProfileScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // App bar
//       appBar: AppBar(
//         title: Text('${widget.user.name}\'s Profile'),
//         actions: [
//           // Optional: Add more actions like block user, report, etc.
//           IconButton(
//               onPressed: () {
//                 // You can add functionality like starting a chat
//                 _startChat();
//               },
//               icon: const Icon(Icons.chat)
//           ),
//           IconButton(
//               onPressed: () {
//                 // More options menu
//                 _showMoreOptions();
//               },
//               icon: const Icon(Icons.more_vert)
//           ),
//         ],
//       ),
//
//       // Floating action button for messaging
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: Colors.blue,
//         onPressed: () {
//           _startChat();
//         },
//         label: const Text('Message'),
//         icon: const Icon(Icons.send),
//       ),
//
//       // Body
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Space
//               SizedBox(width: mq.width, height: mq.height * 0.03),
//
//               // Profile picture (read-only)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(mq.height * 0.1),
//                 child: CachedNetworkImage(
//                   width: mq.height * 0.2,
//                   height: mq.height * 0.2,
//                   fit: BoxFit.cover,
//                   imageUrl: widget.user.image,
//                   placeholder: (context, url) => const CircularProgressIndicator(),
//                   errorWidget: (context, url, error) => const CircleAvatar(
//                       child: Icon(CupertinoIcons.person)
//                   ),
//                 ),
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.03),
//
//               // User name
//               Text(
//                 widget.user.name,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.02),
//
//               // User email
//               Text(
//                 widget.user.email,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                 ),
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.04),
//
//               // User info cards
//               _buildInfoCard(
//                 icon: Icons.info_outline,
//                 title: 'About',
//                 content: widget.user.about.isEmpty ? 'No information available' : widget.user.about,
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.02),
//
//               _buildInfoCard(
//                 icon: Icons.language,
//                 title: 'Preferred Language',
//                 content: LanguageConstants.getLanguageName(widget.user.preferredLanguage ?? 'en'),
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.02),
//
//               _buildInfoCard(
//                 icon: Icons.access_time,
//                 title: 'Last Seen',
//                 content: _getLastSeenText(),
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.02),
//
//               _buildInfoCard(
//                 icon: Icons.person_add,
//                 title: 'Joined',
//                 content: _getJoinedText(),
//               ),
//
//               SizedBox(width: mq.width, height: mq.height * 0.05),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Helper method to build info cards
//   Widget _buildInfoCard({
//     required IconData icon,
//     required String title,
//     required String content,
//   }) {
//     return Card(
//       elevation: 2,
//       child: ListTile(
//         leading: Icon(icon, color: Colors.blue),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Text(
//           content,
//           style: const TextStyle(fontSize: 14),
//         ),
//       ),
//     );
//   }
//
//   // Get last seen text
//   String _getLastSeenText() {
//     if (widget.user.isOnline) {
//       return 'Online';
//     } else {
//       // You can format the last active time here
//       // For now, returning a placeholder
//       return 'Last seen recently';
//     }
//   }
//
//   // Get joined date text
//   String _getJoinedText() {
//     // You can format the created time here
//     // For now, returning a placeholder
//     return 'Member since ${DateTime.now().year}';
//   }
//
//   // Start chat with the user
//   void _startChat() {
//     // Navigate to chat screen with this user
//     // You'll need to implement this based on your chat screen
//     Navigator.pop(context); // Go back and potentially open chat
//
//     // Example:
//     // Navigator.push(
//     //   context,
//     //   MaterialPageRoute(
//     //     builder: (context) => ChatScreen(user: widget.user),
//     //   ),
//     // );
//   }
//
//   // Show more options bottom sheet
//   void _showMoreOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       builder: (context) {
//         return ListView(
//           shrinkWrap: true,
//           padding: EdgeInsets.only(
//             top: mq.height * 0.02,
//             bottom: mq.height * 0.05,
//           ),
//           children: [
//             const Text(
//               'More Options',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             ListTile(
//               leading: const Icon(Icons.chat, color: Colors.blue),
//               title: const Text('Send Message'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _startChat();
//               },
//             ),
//
//             ListTile(
//               leading: const Icon(Icons.call, color: Colors.green),
//               title: const Text('Voice Call'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Implement voice call functionality
//               },
//             ),
//
//             ListTile(
//               leading: const Icon(Icons.videocam, color: Colors.orange),
//               title: const Text('Video Call'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Implement video call functionality
//               },
//             ),
//
//             ListTile(
//               leading: const Icon(Icons.block, color: Colors.red),
//               title: const Text('Block User'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showBlockConfirmation();
//               },
//             ),
//
//             ListTile(
//               leading: const Icon(Icons.report, color: Colors.red),
//               title: const Text('Report User'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Implement report functionality
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // Show block confirmation dialog
//   void _showBlockConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Block User'),
//         content: Text('Are you sure you want to block ${widget.user.name}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // Implement block functionality
//               _blockUser();
//             },
//             child: const Text('Block', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Block user functionality
//   void _blockUser() async {
//     try {
//       // You can implement blocking logic here using your APIS
//       // For now, showing a success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('${widget.user.name} has been blocked'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       log('Blocked user: ${widget.user.id}');
//     } catch (e) {
//       log('Error blocking user: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to block user'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }