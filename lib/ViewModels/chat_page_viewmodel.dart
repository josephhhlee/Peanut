import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/Models/file_model.dart';
import 'package:peanut/Models/message_model.dart';
import 'package:peanut/Models/user_model.dart';
import 'package:peanut/Services/firestore_service.dart';

class ChatPageViewModel {
  late ValueNotifier<Chat> chat;
  late ValueNotifier<NutUser> peer;
  late final NutUser author;
  final List<Message> messages = [];

  final typeController = TextEditingController();

  late final StreamSubscription<QuerySnapshot> _recentMsgListener;
  late final StreamSubscription<DocumentSnapshot> _peerListener;
  late final StreamSubscription<DocumentSnapshot> _chatListener;

  late final void Function({bool load}) _refresh;
  ValueNotifier<void Function()?> openAttachment = ValueNotifier(null);

  Future<void> init(peerId, void Function({bool load}) refresh) async {
    _refresh = refresh;
    author = DataStore().currentUser!;
    await _listenToChat(peerId);
    await _listenToPeer(peerId);
    await _initMessages(peerId);
  }

  void dispose() {
    _recentMsgListener.cancel();
    _peerListener.cancel();
    _chatListener.cancel();
    chat.dispose();
    peer.dispose();
    openAttachment.dispose();
    typeController.dispose();
  }

  Future<void> _listenToChat(String peerId) async {
    final ref = FirestoreService.usersInChatCol(formatChatId(author.uid, peerId)).doc(peerId);

    var doc = await ref.get();
    chat = ValueNotifier(Chat.fromSnapshot(doc));

    _chatListener = ref.snapshots().listen((doc) {
      chat.value = Chat.fromSnapshot(doc);
      _refresh();
    });
  }

  Future<void> _listenToPeer(String peerId) async {
    peer = ValueNotifier((await DataStore().getUser(peerId))!);
    _peerListener = FirestoreService.usersCol.doc(peerId).snapshots().listen((doc) {
      peer.value = NutUser.fromSnapshot(doc);
      _refresh();
    });
  }

  Future<void> _initMessages(String peerId) async {
    final ref = FirestoreService.messagesCol(formatChatId(author.uid, peerId)).orderBy("createdOn", descending: true);

    Future<void> getRecent20() async {
      var snapshot = await ref.limit(20).get(const GetOptions(source: Source.cache));
      if (snapshot.size == 0) snapshot = await ref.limit(20).get();
      _buildMessages(snapshot);
    }

    void listenToLatest() {
      _recentMsgListener = ref.limit(5).snapshots(includeMetadataChanges: true).listen((snapshot) {
        _buildMessages(snapshot, append: false);
        _refresh(load: false);
      });
    }

    await getRecent20();
    listenToLatest();
  }

  Future<bool> loadMoreMessages() async {
    final ref = FirestoreService.messagesCol(formatChatId(author.uid, peer.value.uid))
        .orderBy("createdOn", descending: true)
        .limit(10)
        .startAfter([DateTime.fromMillisecondsSinceEpoch(messages.last.createdOn)]);
    var snapshot = await ref.get(const GetOptions(source: Source.cache));
    if (snapshot.size == 0) snapshot = await ref.get();
    _buildMessages(snapshot);
    return snapshot.size != 0;
  }

  void _buildMessages(QuerySnapshot snapshot, {bool append = true}) {
    for (DocumentSnapshot doc in snapshot.docs) {
      final message = Message.fromSnapshot(doc);
      if (message.status == MessageStatus.sending) continue;
      if (message.hideMessage == author.uid) continue;

      final index = messages.indexWhere((element) => element.id == message.id);
      if (index != -1) {
        messages[index] = message;
      } else {
        append ? messages.add(message) : messages.insert(0, message);
      }
    }
  }

  bool shouldDisplayTime(Message message) {
    final index = messages.indexWhere((element) => element.id == message.id);
    final isLastMessage = index == (messages.length - 1);
    final futureMessageDateTime = isLastMessage ? message.createdOnDateTime : messages[index + 1].createdOnDateTime;
    final futureMessageMinute = DateTime(futureMessageDateTime.year, futureMessageDateTime.month, futureMessageDateTime.day, futureMessageDateTime.hour, futureMessageDateTime.minute);
    final messageDateTime = message.createdOnDateTime;
    final messageMinute = DateTime(messageDateTime.year, messageDateTime.month, messageDateTime.day, messageDateTime.hour, messageDateTime.minute);

    return isLastMessage || futureMessageMinute != messageMinute;
  }

  getDateAndTimeFormat(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final thisYear = DateTime(now.year);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final messageYear = DateTime(dateTime.year);
    if (messageDay == today) {
      return "Today ${DateFormat("h:mm a").format(dateTime)}";
    } else if (messageDay == yesterday) {
      return "Yesterday ${DateFormat("h:mm a").format(dateTime)}";
    } else if (messageYear == thisYear) {
      return "${DateFormat("dd MMM").format(dateTime)}, ${DateFormat("h:mm a").format(dateTime)}";
    } else {
      return "${DateFormat("dd/MM/yyyy").format(dateTime)}, ${DateFormat("h:mm a").format(dateTime)}";
    }
  }

  void sendMessage() {
    final msg = Message(to: peer.value.uid, text: typeController.text);
    typeController.clear();
    messages.insert(0, msg);
    msg.create(chat.value.read);
  }

  void sendMediaMessage(List<LocalFile> attachments) {
    final attachmentsMap = attachments.map((e) => e.toAttachment()).toList();
    final message = MediaMessage(to: peer.value.uid, attachments: attachmentsMap, text: typeController.text);
    typeController.clear();
    messages.insert(0, message);
    _refresh();
    message.create(chat.value.read);
  }
}
