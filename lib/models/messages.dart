// enum MessageType { text, image, video }
//
// extension MessageTypeExtension on MessageType {
//   String get value {
//     switch (this) {
//       case MessageType.text:
//         return 'text';
//       case MessageType.image:
//         return 'image';
//       case MessageType.video:
//         return 'video';
//     }
//   }
// }

class Message {
 late final String toID;
 late final String msg;
 late final String originalMsg;
 late final String read;
 late final String? imageUrl;
 late final MessageType type;
 late final String fromID;
 late final String sent;
 late final String senderLanguage;
 late final String recipientLanguage;
 late final bool wasTranslated;
 late final bool translationSucceeded;
 // NEW: Edit functionality
 late final bool isEdited;
 late final String? editedAt;
 late final String? originalMessage; // Store original before edit
 // NEW: Reply functionality
 late final String? replyToMessageId;
 late final String? replyToMessage; // Store replied message content
 // NEW: Delete functionality
 late final bool isDeleted;
 late final String? deletedAt;
 late final String? deletedBy;


  Message({
    required this.toID,
    required this.msg,
    required this.originalMsg,
    required this.read,
    required this.type,
    required this.fromID,
    required this.sent,
    required this.senderLanguage,
    required this.recipientLanguage,
    required this.wasTranslated,
    required this.translationSucceeded,
    this.imageUrl,
    // NEW: Enhanced message features
    this.isEdited = false,
    this.editedAt,
    this.originalMessage,
    this.replyToMessageId,
    this.replyToMessage,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

   Message.fromJson(Map<String, dynamic> json) {
    toID = json['toID'].toString();
    msg = json['msg'].toString();
    originalMsg = json['originalMsg'].toString();
    read = json['read'].toString();
    type = json['type'].toString() == MessageType.image.name ? MessageType.image : MessageType.text ;
    fromID = json['fromID'].toString();
    sent = json['sent'].toString();
    senderLanguage = json['senderLanguage']?.toString() ?? 'en';
    recipientLanguage = json['recipientLanguage']?.toString() ?? 'en';
    wasTranslated = json['wasTranslated'] ?? false;
    translationSucceeded = json['translationSucceeded'] ?? false;
    imageUrl = json['imageUrl']?.toString();
    // NEW: Enhanced features
    isEdited = json['isEdited'] ?? false;
    editedAt = json['editedAt']?.toString();
    originalMessage = json['originalMessage']?.toString();
    replyToMessageId = json['replyToMessageId']?.toString();
    replyToMessage = json['replyToMessage']?.toString();
    isDeleted = json['isDeleted'] ?? false;
    deletedAt = json['deletedAt']?.toString();
    deletedBy = json['deletedBy']?.toString();
   }


    Map<String, dynamic> toJson(){
     final data = <String, dynamic>{};
     data['toID'] = toID;
     data['msg'] = msg;
     data['originalMsg'] = originalMsg;
     data['read'] = read;
     data['type'] = type.name;
     data['fromID'] = fromID;
     data['sent'] = sent;
     // 🆕 Translation metadata
     data['senderLanguage'] = senderLanguage;
     data['recipientLanguage'] = recipientLanguage;
     data['wasTranslated'] = wasTranslated;
     data['translationSucceeded'] = translationSucceeded;
     if (imageUrl != null) data['imageUrl'] = imageUrl;
     // NEW: Enhanced features
     data['isEdited'] = isEdited;
     if (editedAt != null) data['editedAt'] = editedAt;
     if (originalMessage != null) data['originalMessage'] = originalMessage;
     if (replyToMessageId != null) data['replyToMessageId'] = replyToMessageId;
     if (replyToMessage != null) data['replyToMessage'] = replyToMessage;
     data['isDeleted'] = isDeleted;
     if (deletedAt != null) data['deletedAt'] = deletedAt;
     if (deletedBy != null) data['deletedBy'] = deletedBy;
     return data;
    }

 // Helper method to check if user can edit this message
 bool canEdit(String currentUserId) {
   return fromID == currentUserId &&
       !isDeleted &&
       type == MessageType.text &&
       DateTime.now().difference(
           DateTime.fromMillisecondsSinceEpoch(int.parse(sent))
       ).inMinutes <= 10; // Allow editing within 10 minutes
 }

 // Helper method to check if user can delete this message
 bool canDelete(String currentUserId) {
   return fromID == currentUserId && !isDeleted;
 }


 Message copyWith({
   String? msg,
   String? read,
   bool? wasTranslated,
   bool? translationSucceeded,
   String? imageUrl,
 }) {
   return Message(
     toID: toID,
     msg: msg ?? this.msg,
     originalMsg: originalMsg,
     read: read ?? this.read,
     type: type,
     fromID: fromID,
     sent: sent,
     senderLanguage: senderLanguage,
     recipientLanguage: recipientLanguage,
     wasTranslated: wasTranslated ?? this.wasTranslated,
     translationSucceeded: translationSucceeded ?? this.translationSucceeded,
     imageUrl: imageUrl ?? this.imageUrl,
   );
 }
}

enum MessageType { text, image }

// factory Message.fromJson(Map<String, dynamic> json) {
//   return Message(
//     toID: json['toID'] ?? '',
//     msg: json['msg'] ?? '',
//     read: json['read'] ?? '',
//     type: json['type'] ?? '',
//     fromID: json['fromID'] ?? '',
//     sent: json['sent'] ?? '',
//   );
// }


// Map<String, dynamic> toJson() {
//   return {
//     'toID': toID,
//     'msg': msg,
//     'read': read,
//     'type': type,
//     'fromID': fromID,
//     'sent': sent,
//   };
// }