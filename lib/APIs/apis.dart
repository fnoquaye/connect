import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/models/messages.dart';
import 'package:firebase_auth/firebase_auth.dart';

class APIS{
  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //for accessing cloud firestore database
  static User get user => auth.currentUser!;

  //for accessing cloud firestore db
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //to return current user
  static late ChatUser me;

  // Timer for periodic presence updates
  static Timer? _presenceTimer;

  // App lifecycle tracking
  static bool _isAppInForeground = true;

  // Track if presence tracking is active
  static bool _isPresenceTrackingActive = false;

  // to check if a user exists or not
  static Future<bool> userExists() async{
    return (await firestore
        .collection('users')
        .doc(user.uid)
        .get())
        .exists;
  }

  // to get current user info
  static Future<void> getSelfInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((user) async {
      if(user.exists){
        log('User Data:${user.data()}');
        me = ChatUser.fromJson(user.data()!);
        // IMPORTANT: Initialize presence tracking after getting user info
        await initializePresence();
      }else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // to create a new user
  static Future<void> createUser() async{

    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, Let's Connect",
        image: user.photoURL.toString(),
        createdAt: DateTime.now(),
        isOnline: false,
        lastActive: DateTime.now(),
        pushToken: ''
    );

    return (await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson()));
  }

  // for getting all users from firestore db
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(){
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
    // .where('isFake', isEqualTo: false)
        .snapshots();
  }

  //to update user info
  static Future<void> UpdateUserInfo() async{
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({
      'name': me.name,
      'about': me.about,
    })
    ;
  }

  // Initialize presence tracking
  static Future<void> initializePresence() async {
    try {
      // Set user online when app starts
      await updateUserPresence(true);
      _startPresenceTracking();
      log('Presence tracking initialized');
    } catch (e) {
      log('Error initializing presence: $e');
    }
  }

  // **IMPROVED: Update user online/offline status**
  static Future<void> updateUserPresence(bool isOnline) async {
    try {
      // Check if user is still authenticated
      if (auth.currentUser == null) {
        log('User not authenticated, skipping presence update');
        return;
      }

      final now = DateTime.now();

      await firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastActive': now,
      });
      try{
        // Update local user object if it exists
        me.isOnline = isOnline;
        me.lastActive = now;
        log('Local user object updated');
      }catch (e) {
        log('Local user object not yet initialized: $e');
        // This is fine - means getSelfInfo() hasn't been called yet
      }
      log('Updated presence: ${isOnline ? "Online" : "Offline"} at ${now.toString()}');
    } catch (e) {
      log('Error updating presence: $e');
      // Optionally retry after a delay
      if (isOnline) {
        Timer(const Duration(seconds: 5), () => updateUserPresence(true));
      }
    }
  }

  // **IMPROVED: Start periodic presence tracking**
  static void _startPresenceTracking() {
    // Cancel any existing timer
    _presenceTimer?.cancel();

    if (_isPresenceTrackingActive) {
      log('Presence tracking already active');
      return;
    }

    _isPresenceTrackingActive = true;

    // Update presence every 30 seconds when app is active
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isAppInForeground && auth.currentUser != null) {
        updateUserPresence(true);
      } else {
        // Stop timer if app is in background or user logged out
        timer.cancel();
        _isPresenceTrackingActive = false;
      }
    });

    log('Started periodic presence tracking');
  }

  // **NEW: Handle app lifecycle changes**
  static Future<void> handleAppLifecycleChange(bool isInForeground) async {
    log('App lifecycle changed: ${isInForeground ? "Foreground" : "Background"}');
    _isAppInForeground = isInForeground;

    if (isInForeground) {
      // App came to foreground - user is online
      await updateUserPresence(true);
      _startPresenceTracking();
    } else {
      // App went to background - user is offline
      await updateUserPresence(false);
      _stopPresenceTracking();
    }
  }

  // Stop presence tracking**
  static void _stopPresenceTracking() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _isPresenceTrackingActive = false;
    log('Stopped presence tracking');
  }

  // Call this when user logs out**
  static Future<void> signOut() async {
    try {
      await updateUserPresence(false);
      _stopPresenceTracking();
      // sign out
      await auth.signOut();
      log('User signed out successfully');
    } catch (e) {
      log('Error during sign out: $e');
      // Still attempt to sign out even if presence update fails
      await auth.signOut();
    }
  }

  // Call this when app is disposed/closed**
  static Future<void> dispose() async {
    await updateUserPresence(false);
    _stopPresenceTracking();
  }

  // Get real-time user status**
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStatus(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  // ✅ NEW: Get parsed user status data
  static Map<String, dynamic> parseUserStatus(DocumentSnapshot<Map<String, dynamic>>? snapshot, ChatUser fallbackUser) {
    // Default to offline if no data
    bool isOnline = false;
    DateTime lastActive = fallbackUser.lastActive ?? DateTime.now(); // ✅ Handle nullable lastActive

    if (snapshot != null && snapshot.exists) {
      final data = snapshot.data()!;
      isOnline = data['isOnline'] ?? false;

      // ✅ Handle lastActive - it might be Timestamp or DateTime
      if (data['lastActive'] != null) {
        if (data['lastActive'] is Timestamp) {
          lastActive = (data['lastActive'] as Timestamp).toDate();
        } else if (data['lastActive'] is DateTime) {
          lastActive = data['lastActive'];
        }
      }
    }

    return {
      'isOnline': isOnline,
      'lastActive': lastActive,
      'statusText': getUserStatusText(isOnline, lastActive),
    };
  }

  // Check if user was recently active (within last 5 minutes)**
  static bool wasRecentlyActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    return difference.inMinutes <= 5;
  }

  // Get user status string for display**
  static String getUserStatusText(bool isOnline, DateTime lastActive) {
    if (isOnline) {
      return 'Online';
    } else if (wasRecentlyActive(lastActive)) {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inMinutes < 1) {
        return 'Active now';
      } else {
        return 'Active ${difference.inMinutes}m ago';
      }
    } else {
      // Format last seen time
      final now = DateTime.now();
      final difference = now.difference(lastActive);

      if (difference.inDays > 0) {
        return 'Last seen ${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return 'Last seen ${difference.inHours}h ago';
      } else {
        return 'Last seen ${difference.inMinutes}m ago';
      }
    }
  }

  // Debug method to manually set status (for testing)
  static Future<void> debugSetOnlineStatus(bool isOnline) async {
    log('DEBUG: Manually setting status to: ${isOnline ? "Online" : "Offline"}');
    await updateUserPresence(isOnline);
  }

// Debug method to check current status in Firestore
  static Future<void> debugCheckCurrentStatus() async {
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        log('DEBUG: Current status in Firestore:');
        log('  - isOnline: ${data['isOnline']}');
        log('  - lastActive: ${data['lastActive']}');
        log('  - Presence tracking active: $_isPresenceTrackingActive');
        log('  - App in foreground: $_isAppInForeground');
      }
    } catch (e) {
      log('DEBUG: Error checking status: $e');
    }
  }

// Debug method to force restart presence tracking
  static Future<void> debugRestartPresenceTracking() async {
    log('DEBUG: Restarting presence tracking');
    _stopPresenceTracking();
    await initializePresence();
  }

  ///************* CHAT SCREEN RELATED APIs **************
  // chats (collections) --> conversation_id(doc) --> messages (collection) --> message (doc)

  // useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_ $id'
      : '${id}_ ${user.uid}';

  //to get all messages of a specific conversation
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: false)
        .snapshots();
  }

  //for sending messages
  static Future<void> sendMessage(ChatUser chatUser, String msg) async {
    // message sending time
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // message to send
    final Message message = Message(
        toID: chatUser.id,
        msg: msg,
        read: '',
        type: Type.text,
        fromID: user.uid,
        sent: time);

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson());
  }

  // update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    log('Updating read status for message sent at: ${message.sent}');
    try{
      await firestore
          .collection('chats/${getConversationID(message.fromID)}/messages/')
          .doc(message.sent) //doc ID = timeStamp
          .update({'read':DateTime.now().millisecondsSinceEpoch.toString()
      });
      log('Successfully marked message as read');
    } catch (e) {
      log('Error updating message read status: $e');
    }
  }
  // get only last message of a specific chat
  static Stream <QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // Get only unread messages
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadMessages(ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .where('toID', isEqualTo: APIS.user.uid)  // Messages TO current user
        .where('read', isEqualTo: '')             // Only unread
        .snapshots();
  }

  // **NEW METHOD: Get all messages for unread count**
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessagesForUnreadCount(ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .where('toID', isEqualTo: APIS.user.uid)  // Messages sent TO current user
        .where('read', isEqualTo: '')             // Only unread messages
        .snapshots();
  }

  // **ALTERNATIVE: Get recent messages (last 50) for better performance**
  static Stream<QuerySnapshot<Map<String, dynamic>>> getRecentMessages(ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(50)  // Get last 50 messages
        .snapshots();
  }
}