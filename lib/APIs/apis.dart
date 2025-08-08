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
      // .where('id', isNotEqualTo: user.uid)
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
    await ref.doc().set(message.toJson());
  }

  // update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromID)}/messages/')
        .doc(message.sent)
        .update({'read':DateTime.now().millisecondsSinceEpoch.toString()});
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
}

// final user = ChatUser(image: image, about: about, name: name, id: id, isOnline: isOnline, email: email);
//   return (await firestore
//       .collection('users')
//       .doc(auth.currentUser!.uid)
//       .get())
//       .exists;


// await firestore.collection('users')
//     .doc(user.uid)
//     .set(chatUser.toJson());