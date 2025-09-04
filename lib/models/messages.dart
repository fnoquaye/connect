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
 late final MessageType type;
 late final String fromID;
 late final String sent;
 late final String senderLanguage;
 late final String recipientLanguage;
 late final bool wasTranslated;
 late final bool translationSucceeded;


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
     return data;
    }

 Message copyWith({
   String? msg,
   String? read,
   bool? wasTranslated,
   bool? translationSucceeded,
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