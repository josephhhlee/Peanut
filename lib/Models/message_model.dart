import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Services/image_picker_service.dart';
import 'package:peanut/Utils/text_utils.dart';
import 'dart:developer';

import 'file_model.dart';

String formatChatId(String author, String peer) => author.hashCode > peer.hashCode ? "$author-$peer" : "$peer-$author";

class Attachment {
  late final String? path;
  late final String? thumbnail;
  late final FileType type;

  String? url;
  String? blurHash;
  MessageStatus status = MessageStatus.sending;

  Attachment({this.thumbnail, required this.path, required this.type, this.blurHash});

  Attachment.fromJson(Map<String, dynamic> json) {
    path = null;
    url = json["url"];
    thumbnail = json["thumbnail"];
    type = FileType.values.firstWhere((element) => element.name == json["type"]);

    if (url != null) status = MessageStatus.sent;
  }

  Map<String, dynamic> toJson() => {
        "url": url,
        "blurHash": blurHash,
        "type": type.name,
      };
}

class Message {
  late final String id;
  late final String from;
  late final String to;
  late final String? text;
  late final String? hideMessage;
  late final int createdOn;
  late final MessageType type;
  List<Attachment>? attachments;
  MessageStatus status = MessageStatus.sending;

  String get chatId => formatChatId(from, to);
  DateTime get createdOnDateTime => DateTime.fromMillisecondsSinceEpoch(createdOn);

  Message({required this.to, this.type = MessageType.standard, this.text, this.attachments}) {
    from = DataStore().currentUser!.uid;
    id = FirestoreService.messagesCol(chatId).doc().id;
    createdOn = DateTime.now().millisecondsSinceEpoch;
  }

  Message.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map;

    id = doc.id;
    from = data["from"];
    to = data["to"];
    text = data["message"];
    hideMessage = data["hideMessage"];
    createdOn = data["createdOn"].millisecondsSinceEpoch;
    type = MessageType.values.firstWhere((element) => element.name == data["type"]);

    if (data["attachments"] != null) {
      final list = List.from(data["attachments"]);
      attachments = list.map<Attachment>((e) => Attachment.fromJson(e)).toList();
    }

    status = doc.metadata.hasPendingWrites ? MessageStatus.sending : MessageStatus.sent;
  }

  Map<String, dynamic> _toJson() => {
        "id": id,
        "from": from,
        "to": to,
        "message": text,
        "createdOn": createdOnDateTime,
        "type": type.name,
      };

  Future<void> create(bool read) async {
    try {
      final ref = FirestoreService.messagesCol(chatId).doc(id);
      final fromMessenger = Chat(id: from, chatId: chatId, lastMessage: text ?? type.name.toCapitalized(), lastMessageUser: from, lastMessageDateTime: createdOn);
      final toMessenger = Chat(id: to, chatId: chatId, lastMessage: text ?? type.name.toCapitalized(), lastMessageUser: from, lastMessageDateTime: createdOn);
      await FirestoreService.runTransaction(
        (transaction) async {
          transaction.set(ref, _toJson());
          fromMessenger.create(transaction);
          toMessenger.create(transaction, incrementUnread: !read);
        },
      );
      status = MessageStatus.sent;
    } catch (e) {
      log(e.toString());
      status = MessageStatus.failed;
    }
  }

  void hide(Transaction transaction) {
    transaction.update(FirestoreService.messagesCol(chatId).doc(id), {"hideMessage": DataStore().currentUser!.uid});
  }

  Future<void> remove() async {
    await FirestoreService.messagesCol(chatId).doc(id).delete();
  }
}

class MediaMessage extends Message {
  MediaMessage({required super.attachments, super.text, required super.to}) : super(type: MessageType.media);

  @override
  Map<String, dynamic> _toJson() => {
        "id": id,
        "from": from,
        "to": to,
        "message": text,
        "createdOn": createdOnDateTime,
        "type": type.name,
        "attachments": attachments?.map((e) => e.toJson()).toList(),
      };

  @override
  Future<void> create(bool read) async {
    try {
      await ImagePickerService.uploadToStorage(this);

      final ref = FirestoreService.messagesCol(chatId).doc(id);
      final fromMessenger = Chat(id: from, chatId: chatId, lastMessage: text ?? type.name.toCapitalized(), lastMessageUser: from, lastMessageDateTime: createdOn);
      final toMessenger = Chat(id: to, chatId: chatId, lastMessage: text ?? type.name.toCapitalized(), lastMessageUser: from, lastMessageDateTime: createdOn);
      await FirestoreService.runTransaction(
        (transaction) async {
          transaction.set(ref, _toJson());
          fromMessenger.create(transaction);
          toMessenger.create(transaction, incrementUnread: !read);
        },
      );
      status = MessageStatus.sent;
    } catch (e) {
      log(e.toString());
      status = MessageStatus.failed;
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  failed,
}

enum MessageType {
  standard,
  media,
  file,
  location,
  voice,
}

extension MessageTypeExtension on MessageType {
  String get name => toString().split('.').last;
}

class Chat {
  late final String id;
  late final String chatId;
  late final String lastMessage;
  late final String lastMessageUser;
  late final int? hideChatFromDateTime;
  late final int lastMessageDateTime;
  late final int unreadCount;
  late bool read;
  late int lastSeen;

  Chat({required this.id, required this.chatId, required this.lastMessage, required this.lastMessageUser, required this.lastMessageDateTime});

  Chat.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map;

    id = doc.id;
    chatId = data["chatId"];
    lastMessage = data["lastMessage"];
    lastMessageUser = data["lastMessageUser"];
    hideChatFromDateTime = data["hideChatFromDateTime"]?.millisecondsSinceEpoch;
    lastMessageDateTime = data["lastMessageDateTime"].millisecondsSinceEpoch;
    unreadCount = data["unreadCount"];
    read = data["read"] ?? false;
    lastSeen = data["lastSeen"]?.millisecondsSinceEpoch ?? 0;
  }

  Map<String, dynamic> _toJson(bool incrementUnread) => {
        "id": id,
        "chatId": chatId,
        "lastMessage": lastMessage,
        "lastMessageUser": lastMessageUser,
        "lastMessageDateTime": DateTime.fromMillisecondsSinceEpoch(lastMessageDateTime),
        "unreadCount": incrementUnread ? FieldValue.increment(1) : 0,
      };

  void create(Transaction transaction, {bool incrementUnread = false}) {
    final ref = FirestoreService.usersInChatCol(chatId).doc(id);
    transaction.set(ref, _toJson(incrementUnread), SetOptions(merge: true));
  }

  Future<void> updateHideChatFrom(int timestamp) async => await FirestoreService.usersInChatCol(chatId).doc(id).update({"hideChatFromDateTime": DateTime.fromMillisecondsSinceEpoch(timestamp)});
}
