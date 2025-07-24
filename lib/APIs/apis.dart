import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect/models/chat_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class APIS{
  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //for accessing cloud firestore database
  static User get user => auth.currentUser!;

  //for accessing cloud firestore db
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

// to check if a user exists or not
static Future<bool> userExists() async{
  return (await firestore
      .collection('users')
      .doc(user.uid)
      .get())
      .exists;
}

// to create a new user
  static Future<void> createUser() async{
    // final time = DateTime.now();
        // .millisecondsSinceEpoch.toString();

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