import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String image;
  final String about;
  final String name;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final bool isOnline;
  final String email;
  final String? pushToken;

  const ChatUser({
    required this.image,
    required this.about,
    required this.name,
    this.createdAt,
    this.lastActive,
    required this.isOnline,
    required this.email,
    this.pushToken,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      image: json['image'] ?? '',
      about: json['about'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
      lastActive: json['last_active'] != null
          ? (json['last_active'] as Timestamp).toDate()
          : null,
      isOnline: json['is_online'] ?? false,
      email: json['email'] ?? '',
      pushToken: json['push_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'about': about,
      'name': name,
      'created_at': createdAt,
      'last_active': lastActive,
      'is_online': isOnline,
      'email': email,
      'push_token': pushToken,
    };
  }
}
