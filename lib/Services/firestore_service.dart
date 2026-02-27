import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;
  static final runTransaction = _firestore.runTransaction;

  static final appConfigsCol = _firestore.collection("appConfigs");
  static final usersCol = _firestore.collection("users");
  static final questsCol = _firestore.collection("quests");
  static final messengerCol = _firestore.collection("messenger");

  static final onboardingDoc = appConfigsCol.doc("onboarding");
  static final configsDoc = appConfigsCol.doc("configs");
  static final maintenanceDoc = appConfigsCol.doc("maintenance");

  static DocumentReference peanutCurrencyDoc(String uid) => usersCol.doc(uid).collection("currency").doc("peanut");
  static DocumentReference userQuestListCreatedDoc(String uid) => usersCol.doc(uid).collection("questList").doc("created");
  static DocumentReference userQuestListTakenDoc(String uid) => usersCol.doc(uid).collection("questList").doc("taken");

  static CollectionReference messagesCol(String chatId) => messengerCol.doc(chatId).collection("messages");
  static CollectionReference usersInChatCol(String chatId) => messengerCol.doc(chatId).collection("usersInChat");
}
