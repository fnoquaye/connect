import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
   String image;
   String about;
   String name;
  final String id;
  final DateTime? createdAt;
  late final DateTime? lastActive;
  late final bool isOnline;
  late final String? preferredLanguage;
  final String email;
  final String? pushToken;

   ChatUser({
    required this.image,
    required this.about,
    required this.name,
    required this.id,
    this.createdAt,
    this.lastActive,
    required this.isOnline,
    this.preferredLanguage,
    required this.email,
    this.pushToken,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      image: json['image'] ?? '',
      about: json['about'] ?? '',
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      lastActive: json['lastActive'] != null
          ? (json['lastActive'] as Timestamp).toDate()
          : null,
      isOnline: json['isOnline'] ?? false,
      preferredLanguage : json['preferredLanguage']?.toString(),
      email: json['email'] ?? '',
      pushToken: json['pushToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'about': about,
      'name': name,
      'id' : id,
      'createdAt': createdAt,
      'lastActive': lastActive,
      'isOnline': isOnline,
      'preferredLanguage' : preferredLanguage,
      'email': email,
      'pushToken': pushToken,
    };
  }
}
