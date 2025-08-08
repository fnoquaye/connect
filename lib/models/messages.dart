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
 late final String read;
 late final Type type;
 late final String fromID;
 late final String sent;

  Message({
    required this.toID,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromID,
    required this.sent,
  });

   Message.fromJson(Map<String, dynamic> json) {
    toID = json['toID'].toString();
    msg = json['msg'].toString();
    read = json['read'].toString();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text ;
    fromID = json['fromID'].toString();
    sent = json['sent'].toString();
  }




    Map<String, dynamic> toJson(){
     final data = <String, dynamic>{};
     data['toID'] = toID;
     data['msg'] = msg;
     data['read'] = read;
     data['type'] = type.name;
     data['fromID'] = fromID;
     data['sent'] = sent;
     return data;
    }
}

enum Type { text, image }



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