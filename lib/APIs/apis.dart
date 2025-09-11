import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect/models/chat_user.dart';
import 'package:connect/models/messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

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

  //
  static String? _currentDeviceId;
  static bool _isInitialized = false;

  // Track if presence tracking is active
  static bool _isPresenceTrackingActive = false;

  // Prevent multiple simultaneous presence updates (CRASH FIX)
  static bool _isUpdatingPresence = false;

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
    // timeout to prevent splashscreen stuck
    try{
      log('📱 Getting self info...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        log('⚠️ No user found, skipping getSelfInfo');
        return;
      }
      await firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10)) //prevent infinite wait time
          .then((user) async {
        if(user.exists) {
          log('User Data:${user.data()}');
          me = ChatUser.fromJson(user.data()!);
          // Initialize presence tracking once per session
          if (!_isInitialized) {
            _isInitialized = true;
            log('🔧 Initializing presence for first time...');
            await initializePresence();
          } else {
            log('⚠️ Presence already initialized, skipping...');
          }
        } else{
          log('👤 User does not exist, creating...');
          await createUser().then((value) => getSelfInfo());
        }
      });
    } catch (e) {
      log('❌ Error getting self info: $e');
      // 🔥 NEW: Don't hang the app - create user if timeout
      if (e.toString().contains('TimeoutException')) {
        log('⏰ Timeout occurred, creating user...');
        try {
          await createUser();
        } catch (createError) {
          log('❌ Error creating user after timeout: $createError');
        }
      }
    }
  }

  // to create a new user
  static Future<void> createUser() async{

    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, Let\'s Connect",
        image: user.photoURL.toString(),
        createdAt: DateTime.now(),
        isOnline: false,
        // preferredLanguage: '',
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

  static Future<ChatUser?> getUserById(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) return ChatUser.fromJson(doc.data()!);
    return null;
  }

  // NEW: Get real-time user profile stream (for ChatScreen AppBar updates)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  // Comprehensive FCM initialization
  static Future<void> initializeFCM() async {
    try {
      log('🔔 Initializing FCM...');

      // Request notification permissions
      await requestNotificationPermission();

      // Update FCM token
      await updateFCMToken();

      // Setup message listeners
      setupMessageHandlers();

      log('✅ FCM initialization complete');
    } catch (e) {
      log('❌ FCM initialization failed: $e');
    }
  }

  // Request notification permission
  static Future<void> requestNotificationPermission() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      log('📱 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        log('⚠️ User granted provisional notification permission');
      } else {
        log('❌ User declined or has not accepted notification permission');
      }
    } catch (e) {
      log('❌ Error requesting notification permission: $e');
    }
    // FirebaseMessaging messaging = FirebaseMessaging.instance;
    //
    // NotificationSettings settings = await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );
    //
    // print('User granted permission: ${settings.authorizationStatus}');
  }

  // Get FCM token and save to user document
  static Future<void> updateFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Get current token
      String? token = await messaging.getToken();

      if (token != null) {
        log('🎫 FCM Token: $token');

        // Update user document with token
        await firestore.collection('users').doc(user.uid).update({
          'pushToken': token,
          'lastActive': DateTime.now().millisecondsSinceEpoch.toString(),
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });

        log('✅ FCM token updated in Firestore');
      } else {
        log('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        log('🔄 FCM token refreshed: $newToken');
        firestore.collection('users').doc(user.uid).update({
          'pushToken': newToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });

    } catch (e) {
      log('❌ Error updating FCM token: $e');
    }
  }

  // Setup comprehensive message handlers
  static void setupMessageHandlers() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📱 Received foreground message: ${message.notification?.title}');

      // You can add custom logic here to show in-app notifications
      // or update UI state based on the message
    });

    // Background/terminated app message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📱 App opened from notification: ${message.data}');

      // Navigate to specific screen based on message data
      // You can add navigation logic here
    });

    // Check for initial message (app opened from terminated state)
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        log('📱 App launched from notification: ${message.data}');
        // Handle initial message navigation
      }
    });
  }

  // Send notification to specific user (call this when sending a message)
  static Future<void> sendNotificationToUser({required String recipientToken, required String title, required String body, required Map<String, String> data,}) async {
    try {
      if (recipientToken.isEmpty) {
        log('⚠️ Recipient token is empty, skipping notification');
        return;
      }

      // You'll need to implement server-side notification sending
      // This is typically done through your backend server for security
      log('📤 Sending notification to token: ${recipientToken.substring(0, 20)}...');

      // For now, just log the notification data
      log('📋 Notification data:');
      log('  Title: $title');
      log('  Body: $body');
      log('  Data: $data');

    } catch (e) {
      log('❌ Error sending notification: $e');
    }
  }

  static void setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // You can show an in-app notification here
      }
    });
  }

  // Get only my added connections
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyConnections() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('connections')
        .snapshots();
  }

  // Send a connection request
  static Future<void> sendConnectionRequest(ChatUser otherUser) async {
    final myId = user.uid;
    final otherId = otherUser.id;

    final batch = firestore.batch();

    // request doc under me -> marked "sent"
    final myRequestRef = firestore
        .collection('users')
        .doc(myId)
        .collection('connection_requests')
        .doc(otherId);

    batch.set(myRequestRef, {
      'id': otherUser.id,
      'name': otherUser.name,
      'email': otherUser.email,
      'status': 'sent',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // request doc under them -> marked "pending"
    final otherRequestRef = firestore
        .collection('users')
        .doc(otherId)
        .collection('connection_requests')
        .doc(myId);

    batch.set(otherRequestRef, {
      'id': me.id,
      'name': me.name,
      'email': me.email,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

// Accept request -> moves to connections & removes pending
  static Future<void> acceptConnectionRequest(ChatUser otherUser) async {
    await addConnection(otherUser); // use your existing addConnection
    // delete request docs on both sides
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('connection_requests')
        .doc(otherUser.id)
        .delete();
    await firestore
        .collection('users')
        .doc(otherUser.id)
        .collection('connection_requests')
        .doc(user.uid)
        .delete();
  }

// Decline request -> just remove pending docs
  static Future<void> declineConnectionRequest(ChatUser otherUser) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('connection_requests')
        .doc(otherUser.id)
        .delete();
    await firestore
        .collection('users')
        .doc(otherUser.id)
        .collection('connection_requests')
        .doc(user.uid)
        .delete();
  }

  // Get incoming requests (others sent to me, waiting for my action)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getIncomingRequests() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('connection_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get outgoing requests (I sent to others, waiting for them to accept/decline)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getOutgoingRequests() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('connection_requests')
        .where('status', isEqualTo: 'sent')
        .snapshots();
  }

  // for adding a friend (pick one user from all users in db)
  static Future<ChatUser?> getUserByEmail(String email) async {
    final query = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ChatUser.fromJson(query.docs.first.data());
    }
    return null;
  }

  // Add another user as a connection (mutual)
  static Future<void> addConnection(ChatUser otherUser) async {
    final myId = user.uid;
    final otherId = otherUser.id;

    // Use a batch so both writes succeed or fail together
    final batch = firestore.batch();

    // Add otherUser to my connections
    final myConnRef = firestore
        .collection('users')
        .doc(myId)
        .collection('connections')
        .doc(otherId);

    batch.set(myConnRef, {
      'id': otherUser.id,
      'name': otherUser.name,
      'email': otherUser.email,
      'image': otherUser.image,
      'about': otherUser.about,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add me to otherUser's connections
    final otherConnRef = firestore
        .collection('users')
        .doc(otherId)
        .collection('connections')
        .doc(myId);

    batch.set(otherConnRef, {
      'id': me.id,
      'name': me.name,
      'email': me.email,
      'image': me.image,
      'about': me.about,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  //to update user info
  static Future<void> UpdateUserInfo() async{
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({
      'name': me.name,
      'about': me.about,
      'preferredLanguage': me.preferredLanguage,
    })
    ;
  }

  // Initialize presence tracking
  static Future<void> initializePresence() async {
    try {

      // 🔥 NEW: Generate unique device ID to prevent conflicts
      _currentDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
      log('🔧 Device ID: $_currentDeviceId');

      // 🔥 NEW: Add device ID to prevent multi-emulator conflicts
      if (_isPresenceTrackingActive) {
        log('⚠️ Presence tracking already active for this device');
        return;
      }
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
    // 🔥 NEW: Prevent multiple simultaneous updates
    if (_isUpdatingPresence) {
      log('Presence update already in progress, skipping');
      return;
    }
    try {
      // 🔥 NEW: Set flag to prevent concurrent updates
      _isUpdatingPresence = true;
      // Check if user is still authenticated
      if (auth.currentUser == null) {
        log('User not authenticated, skipping presence update');
        return;
      }

      final now = DateTime.now();
      // 🔥 NEW: Add device ID to update to prevent conflicts
      final updateData = {
        'isOnline': isOnline,
        'lastActive': now,
        'deviceId': _currentDeviceId ?? 'unknown', // Track which device is updating
        'presenceUpdated': FieldValue.serverTimestamp(),
      };
      await firestore.collection('users').doc(user.uid).update(updateData);
      try{
        // Update local user object if it exists
        me.isOnline = isOnline;
        me.lastActive = now;
        log('Local user object updated');
      }catch (e) {
        log('Local user object not yet initialized: $e');
        // This is fine - means getSelfInfo() hasn't been called yet
      }
      log('Updated presence: ${isOnline ? "Online" : "Offline"} at ${now.toString()} [Device: $_currentDeviceId');
    } catch (e) {
      log('Error updating presence: $e');
      // Optionally retry after a delay
      // if (isOnline) {
      //   Timer(const Duration(seconds: 5), () => updateUserPresence(true));
      // }
    } finally {
      // 🔥 NEW: Always reset flag
      _isUpdatingPresence = false;
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

    // Update presence every 60 seconds when app is active
    _presenceTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_isAppInForeground && auth.currentUser != null) {
        log('🔄 Periodic presence update triggered');
        updateUserPresence(true);
      } else {
        // Stop timer if app is in background or user logged out
        timer.cancel();
        _isPresenceTrackingActive = false;
        log('⏹️ Presence tracking stopped');
      }
    });

    log('Started periodic presence tracking');
  }

  // Block a user (one-way: they won't appear in my list)
  static Future<void> blockUser(ChatUser otherUser) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('blocked')
        .doc(otherUser.id)
        .set({
      'id': otherUser.id,
      'name': otherUser.name,
      'email': otherUser.email,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

// Report a user (goes into a "reports" collection for admin review)
  static Future<void> reportUser(ChatUser otherUser, String reason) async {
    await firestore.collection('reports').add({
      'reportedBy': user.uid,
      'reportedUser': otherUser.id,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> cleanupPreviousSession() async {
    try {
      // 🔥 NEW: Clear any hanging listeners from previous sessions
      await firestore.clearPersistence();
      log('✅ Cleared Firestore persistence');
    } catch (e) {
      log('⚠️ Could not clear persistence (normal on first run): $e');
    }
  }

  // **NEW: Handle app lifecycle changes**
  static Future<void> handleAppLifecycleChange(bool isInForeground) async {
    log('App lifecycle changed: ${isInForeground ? "Foreground" : "Background"}');
    _isAppInForeground = isInForeground;

    if (isInForeground) {
      // App came to foreground - user is online
      log('🟢 Setting user online...');
      await updateUserPresence(true);
      await Future.delayed(const Duration(milliseconds: 500));
      _startPresenceTracking();
    } else {
      // App went to background - user is offline
      log('🔴 Setting user offline...');
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

  // Get parsed user status data
  static Map<String, dynamic> parseUserStatus(DocumentSnapshot<Map<String, dynamic>>? snapshot, ChatUser fallbackUser) {
    // Default to offline if no data
    bool isOnline = false;
    DateTime lastActive = fallbackUser.lastActive ?? DateTime.now(); // ✅ Handle nullable lastActive

    if (snapshot != null && snapshot.exists) {
      final data = snapshot.data()!;
      isOnline = data['isOnline'] ?? false;

      // Handle lastActive - it might be Timestamp or DateTime
      if (data['lastActive'] != null) {
        try{
          if (data['lastActive'] is Timestamp) {
            lastActive = (data['lastActive'] as Timestamp).toDate();
          } else if (data['lastActive'] is DateTime) {
            lastActive = data['lastActive'];
          } else if (data['lastActive'] is String) {
            //  Handle string timestamps (milliseconds)
            final timestamp = int.tryParse(data['lastActive']);
            if (timestamp != null) {
              lastActive = DateTime.fromMillisecondsSinceEpoch(timestamp);
            }
          }
        } catch (e) {
          log('⚠️ Error parsing lastActive: $e');
        }
      }
    }
    return {
      'isOnline': isOnline,
      'lastActive': lastActive,
      'statusText': getUserStatusText(isOnline, lastActive),
    };
  }

  // Check if user was recently active (within last 2 minutes)**
  static bool wasRecentlyActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    return difference.inMinutes <= 2;
  }

  // Get user status string for display**
  static String getUserStatusText(bool isOnline, DateTime lastActive) {
    if (isOnline) {
      return 'Online';
    } else if (wasRecentlyActive(lastActive)) {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inSeconds < 30){
        return 'Active just now';
      } else if (difference.inMinutes < 1) {
        return 'Active ${difference.inSeconds}s ago';
      } else {
        return 'Active ${difference.inMinutes}m ago';
      }
    } else {
      // Format last seen time
      final now = DateTime.now();
      final difference = now.difference(lastActive);

      if (difference.inDays > 7) {
        return 'Last seen ${(difference.inDays/7).floor()}w ago';
      } else if (difference.inDays > 0) {
        return 'Last seen ${difference.inDays}d ago';
      } else if (difference.inHours > 0){
        return 'Last seen ${difference.inHours}h ago';
      } else if(difference.inMinutes > 0){
        return 'Last seen ${difference.inMinutes}m ago';
      } else {
        return 'Last seen just now';
      }
    }
  }

  // Force refresh user status (useful for debugging)
  static Future<void> forceRefreshStatus() async {
    log('🔄 Force refreshing user status...');
    await updateUserPresence(true);
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

  static Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    await firestore
        .collection('chats/$chatId/typing')
        .doc(user.uid)
        .set({'isTyping': isTyping});
  }


  //for sending messages
  static Future<bool> sendMessage(ChatUser chatUser, String msg, {String? imageUrl, MessageType type = MessageType.text,}) async {
    try{
      if (type==MessageType.text && msg.trim().isEmpty)
        return false;

      print('📤 SEND MESSAGE DEBUG:');
      print('  - Original message: "$msg"');

      // Add fallback for preferred language

      // Get FRESH recipient language preference
      final freshRecipientLang = await getUserPreferredLanguage(chatUser.id);
      print('  - Fresh recipient language: "$freshRecipientLang"');

      // Get sender's language preference
      final senderLang = await getUserPreferredLanguage(user.uid);
      print('  - Sender language: "$senderLang"');

      // Determine if translation is needed
      final needsTranslation = type == MessageType.text
          && senderLang != freshRecipientLang;
      print('  - Translation needed: $needsTranslation');

      String translatedMsg = msg;
      bool translationSucceeded = true;

      if (needsTranslation) {
        // Attempt translation
        final translationResult = await translateTextWithFallback(
          text: msg,
          sourceLang: senderLang,
          targetLang: freshRecipientLang,
        );
        translatedMsg = translationResult['text'];
        translationSucceeded = translationResult['success'];

        //debugs
        print('  - Translation result: "$translatedMsg"');
        print('  - Translation succeeded: $translationSucceeded');
      } else if (type != MessageType.text){
        print('  - Skipping translation for non-text message type');
      }

      // message sending time
      final time = DateTime.now().millisecondsSinceEpoch.toString();

      // message to send
      final Message message = Message(
          toID: chatUser.id,
          msg: translatedMsg,
          originalMsg: msg,
          read: '',
          type: type,
          fromID: user.uid,
          sent: time,
          senderLanguage: senderLang,            // NEW: Track sender language
          recipientLanguage: freshRecipientLang, // NEW: Track recipient language
          wasTranslated: needsTranslation,       // NEW: Track if translated
          translationSucceeded: translationSucceeded, // NEW: Track success
          imageUrl: imageUrl,                     // 🔥 save image URL if provided
      );


      print('💾 SAVING MESSAGE:');
      final ref = firestore
          .collection('chats/${getConversationID(chatUser.id)}/messages/');
      await ref.doc(time).set(message.toJson())
          .timeout(const Duration(seconds: 10),
          onTimeout: ()=> throw TimeoutException('FireStore write timeout'));
      print('✅ Message saved to Firestore successfully');
      return true; // ✅ Return success status
    } catch (e) {
      print('Error sending message: $e'); // ✅ Add error handling
      return false;
    }
  }

  // translate text with fallback
  // This Part Wraps Translate Text Method...
  static Future<Map<String, dynamic>> translateTextWithFallback({required String text, required String sourceLang, required String targetLang,}) async {
    try {
      final translatedText = await translateText(text, targetLang);
      final success = translatedText != text;
      return {
        'text': translatedText,
        'success': success,
      };
    } catch (e) {
      print('❌ Translation failed: $e');
      return {
        'text': text,
        'success': false,
      };
    }
  }

  // translate texts using my locally hosted server
  static Future<String> translateText(String text, String targetLang) async {
    if (text.trim().isEmpty) {
      print('⏭️ Skipping translation - empty text');
      return text;
    }
    print('🌐 TRANSLATION DEBUG:');
    print('  - Input text: "$text"');
    print('  - Target language: "$targetLang"');

    // List of URLs to try
    final urls = [
      'http://192.168.137.61:8000/translate', // Your machine's IP
      'http://10.0.2.2:8000/translate',    // Android emulator
      'http://127.0.0.1:8000/translate',    //local loopback
      'http://localhost:8000/translate',    // iOS/general
    ];

    for (String url in urls) {
      try {
        print('🔄 Trying URL: $url');

        final requestBody = {
          'text': text,
          // 'source_lang': 'auto', // automatic detection
          'target_lang': targetLang,
        };

        print('📡 Request body: $requestBody');

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 8));

        print('📡 Response status: ${response.statusCode}');
        // print('📡 Translation response status: ${response.statusCode}'); // Debug
        print('📡 Translation response body: ${response.body}'); // Debug

        if (response.statusCode == 200) {
          try {

            final data = jsonDecode(response.body);
            print('📊 Parsed response data: $data');

            // Check what fields are available
            print('📋 Available fields: ${data.keys.toList()}');

            final translatedText = data['translated_text'] ??
                data['translation'] ??
                data['result'] ??
                text;

            print('✅ Translation result:');
            print('  - Original: "$text"');
            print('  - Translated: "$translatedText"');
            print('  - Changed: ${translatedText != text}');
            return translatedText;
          } catch (e){
            print('❌ Error parsing response JSON: $e');
            print('📄 Raw response: ${response.body}');
            continue;
          }
        } else {

          print('❌ Server error: ${response.statusCode}');
          print('📄 Error response: ${response.body}');
          continue;
        }
      } catch (e) {
        print('Failed with $url: $e');
        continue;
      }
    }
    print('❌ All URLs failed, using original text');
    return text;
  }

  // Get display text (translate if needed)
  static Future<String> getDisplayText(Message message) async {
    // RULE: Always show messages as they were originally displayed/translated

    // Your own messages: always show in the language you wrote them
    if (message.fromID == user.uid) {
      return message.originalMsg;
    }

    // Received messages: show them as they were translated when sent
    // If the message was successfully translated for you, use that translation
    // Otherwise, use the original message
    if (message.wasTranslated && message.translationSucceeded) {
      return message.msg; // Use the translation that was made when message was sent
    } else {
      return message.originalMsg; // Use original if no translation or translation failed
    }

    // This ensures:
    // 1. Your messages always appear in the language you wrote them
    // 2. Received messages appear in the language they were translated to when sent
    // 3. No re-translation happens when you change language preferences
    // 4. Past conversations maintain their original appearance
  }

// ALSO ADD: Method to handle language changes for FUTURE messages only
  static Future<void> onLanguageChanged(String newLanguage) async {
    try {
      await updateMyPreferredLanguage(newLanguage);
      log('✅ Language changed to: $newLanguage');
      log('📝 Note: This will only affect NEW messages. Past messages remain unchanged.');
    } catch (e) {
      log('❌ Error changing language: $e');
    }
    // RULE: Always show messages as they were originally displayed/translated


    // // If it's your own message, show original
    // if (message.fromID == user.uid) {
    //   return message.originalMsg;
    // }
    //
    // final viewerLang = await getUserPreferredLanguage(APIS.user.uid);
    //
    // // if already translated, use it
    // if (message.recipientLanguage == viewerLang &&
    //     message.wasTranslated &&
    //     message.translationSucceeded){
    //   return message.msg;
    // }
    //
    // // If viewer's language is same as sender's language, show original
    // if (message.senderLanguage == viewerLang) {
    //   return message.originalMsg;
    // }

    // // Re-translate if viewer's language is different
    // final retranslated = await translateTextWithFallback(
    //   text: message.originalMsg,
    //   sourceLang: message.senderLanguage,
    //   targetLang: viewerLang,
    // );
    //
    // return retranslated['text'];
  }

  // NEW: Edit an existing message
  static Future<bool> editMessage(String chatUserId, String messageId, String newMessage) async {
    try {
      print('📝 EDITING MESSAGE:');
      print('  - Message ID: $messageId');
      print('  - New content: "$newMessage"');

      final messageRef = firestore
          .collection('chats/${getConversationID(chatUserId)}/messages/')
          .doc(messageId);

      // Get original message first
      final originalDoc = await messageRef.get();
      if (!originalDoc.exists) {
        print('❌ Message not found for editing');
        return false;
      }

      final originalData = originalDoc.data()!;
      final originalMessage = Message.fromJson(originalData);

      // Check if user can edit (must be sender and within time limit)
      if (!originalMessage.canEdit(user.uid)) {
        print('❌ Cannot edit this message');
        return false;
      }

      // Get recipient language for translation
      final recipientLang = await getUserPreferredLanguage(chatUserId);
      final senderLang = await getUserPreferredLanguage(user.uid);

      String translatedMsg = newMessage;
      bool translationSucceeded = true;
      bool needsTranslation = senderLang != recipientLang;

      if (needsTranslation) {
        final translationResult = await translateTextWithFallback(
          text: newMessage,
          sourceLang: senderLang,
          targetLang: recipientLang,
        );
        translatedMsg = translationResult['text'];
        translationSucceeded = translationResult['success'];
      }

      // Update message with edit information
      await messageRef.update({
        'msg': translatedMsg,
        'originalMsg': newMessage,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'originalMessage': originalMessage.isEdited
            ? originalMessage.originalMessage // Keep the very first version
            : originalMessage.originalMsg,
        'wasTranslated': needsTranslation,
        'translationSucceeded': translationSucceeded,
      });

      print('✅ Message edited successfully');
      return true;
    } catch (e) {
      print('❌ Error editing message: $e');
      return false;
    }
  }

  // NEW: Reply to a message
  static Future<bool> replyToMessage(ChatUser chatUser, String replyMessage, Message originalMessage) async {
    try {
      if (replyMessage.trim().isEmpty) return false;

      print('💬 REPLYING TO MESSAGE:');
      print('  - Original: "${originalMessage.msg}"');
      print('  - Reply: "$replyMessage"');

      // Get language preferences
      final freshRecipientLang = await getUserPreferredLanguage(chatUser.id);
      final senderLang = await getUserPreferredLanguage(user.uid);

      // Translate reply if needed
      String translatedReply = replyMessage;
      bool translationSucceeded = true;
      bool needsTranslation = senderLang != freshRecipientLang;

      if (needsTranslation) {
        final translationResult = await translateTextWithFallback(
          text: replyMessage,
          sourceLang: senderLang,
          targetLang: freshRecipientLang,
        );
        translatedReply = translationResult['text'];
        translationSucceeded = translationResult['success'];
      }

      final time = DateTime.now().millisecondsSinceEpoch.toString();

      // Create reply message
      final Message message = Message(
        toID: chatUser.id,
        msg: translatedReply,
        originalMsg: replyMessage,
        read: '',
        type: MessageType.text,
        fromID: user.uid,
        sent: time,
        senderLanguage: senderLang,
        recipientLanguage: freshRecipientLang,
        wasTranslated: needsTranslation,
        translationSucceeded: translationSucceeded,
        // Reply-specific fields
        replyToMessageId: originalMessage.sent,
        replyToMessage: originalMessage.originalMsg.length > 100
            ? '${originalMessage.originalMsg.substring(0, 100)}...'
            : originalMessage.originalMsg,
      );

      final ref = firestore
          .collection('chats/${getConversationID(chatUser.id)}/messages/');
      await ref.doc(time).set(message.toJson())
          .timeout(const Duration(seconds: 10));

      print('✅ Reply sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending reply: $e');
      return false;
    }
  }

  // NEW: Delete a message (soft delete)
  static Future<bool> deleteMessage(String chatUserId, String messageId, bool deleteForEveryone) async {
    try {
      print('🗑️ DELETING MESSAGE:');
      print('  - Message ID: $messageId');
      print('  - Delete for everyone: $deleteForEveryone');

      final messageRef = firestore
          .collection('chats/${getConversationID(chatUserId)}/messages/')
          .doc(messageId);

      // Get original message first
      final originalDoc = await messageRef.get();
      if (!originalDoc.exists) {
        print('❌ Message not found for deletion');
        return false;
      }

      final originalMessage = Message.fromJson(originalDoc.data()!);

      // Check if user can delete
      if (!originalMessage.canDelete(user.uid)) {
        print('❌ Cannot delete this message');
        return false;
      }

      if (deleteForEveryone) {
        // Hard delete - remove completely
        await messageRef.delete();
        print('✅ Message deleted for everyone');
      } else {
        // Soft delete - mark as deleted
        await messageRef.update({
          'isDeleted': true,
          'deletedAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'deletedBy': user.uid,
          'msg': 'This message was deleted',
          'originalMsg': 'This message was deleted',
        });
        print('✅ Message deleted for you');
      }

      return true;
    } catch (e) {
      print('❌ Error deleting message: $e');
      return false;
    }
  }

  // Update message method
  static Future<bool> updateMessage(ChatUser chatUser, Message message, String newMessage) async {
    try {
      print('📝 UPDATING MESSAGE:');
      print('  - Message ID: ${message.sent}');
      print('  - New content: "$newMessage"');

      // Use the existing editMessage method
      return await editMessage(chatUser.id, message.sent, newMessage);
    } catch (e) {
      print('❌ Error in updateMessage wrapper: $e');
      return false;
    }
  }

  // NEW: Get message by ID (useful for reply context)
  static Future<Message?> getMessageById(String chatUserId, String messageId) async {
    try {
      final doc = await firestore
          .collection('chats/${getConversationID(chatUserId)}/messages/')
          .doc(messageId)
          .get();

      if (doc.exists) {
        return Message.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting message: $e');
      return null;
    }
  }

  // NEW: Check if user can perform actions on message
  static bool canPerformMessageAction(Message message, String action) {
    final currentUserId = user.uid;
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(int.parse(message.sent));
    final timeDiff = now.difference(messageTime);

    switch (action) {
      case 'edit':
        return message.fromID == currentUserId &&
            !message.isDeleted &&
            message.type == MessageType.text &&
            timeDiff.inMinutes <= 10; // 10 minute edit window

      case 'delete':
        return !message.isDeleted;

      case 'reply':
        return !message.isDeleted;

      default:
        return false;
    }
  }

  // get user's preferred language
  static Future<String> getUserPreferredLanguage(String userId) async {
    log('📥 Fetching preferred language for user: $userId');
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final lang = doc.data()!['preferredLanguage']?.toString().trim() ?? '';
        await Future.delayed(Duration(seconds: 1));
        log('🌐 preferredLanguage field: "$lang"');
        return lang;
        // return doc.data()!['preferredLanguage']?.toString() ?? '';
      }
    } catch (e) {
      print('Error getting user preferred language: $e');
    }
    return ''; // Default null
  }

  // update current user's preferred language
  static Future<void> updateMyPreferredLanguage(String langCode) async {
    try {
      final userDoc = firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        print('⚠️ User document not found. Creating...');
        await userDoc.set({
          'preferredLanguage': langCode,
          'createdAt': DateTime.now(),
          'id': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'image': user.photoURL ?? '',
          'about': 'Hey, Let\'s Connect',
          'isOnline': false,
          'pushToken': '',
          'lastActive': DateTime.now(),
        });
        print('✅ User document created with preferredLanguage: $langCode');
      } else {
        await userDoc.update({'preferredLanguage': langCode});
        print('✅ Firestore updated with preferredLanguage: $langCode');
      }

      // await firestore.collection('users').doc(user.uid).update({
      //   'preferredLanguage': langCode,
      // });

      print('✅ Firestore updated with preferredLanguage: $langCode');
      // Update local user object
      me.preferredLanguage = langCode;
      print('Updated preferred language to: $langCode');
    } catch (e) {
      print('Error updating preferred language: $e');
    }
  }

  //to get all messages of a specific conversation
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: false)
        .snapshots();
  }

  // upload to cloudinary
  static Future<String?> uploadImageToCloudinary(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dfhmxr0iy/image/upload'), // replace <CLOUD_NAME>
      );

      request.fields['upload_preset'] = 'unsigned_preset'; // your unsigned preset
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      var resStream = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var data = json.decode(resStream.body);
        return data['secure_url']; // this is the URL you store in Firestore
      } else {
        print('Cloudinary upload failed: ${resStream.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
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
  static Stream <QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
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
}