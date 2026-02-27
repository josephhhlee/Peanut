import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/Models/map_model.dart';
import 'package:peanut/Services/firestore_service.dart';

class MiniQuest {
  late final String id;
  late final int rewards;
  late final int createdOn;
  late final String creator;

  QuestStatus status = QuestStatus.untaken;
  String? title;
  String? taker;
  int? expiry;
  int? takenOn;
  MapModel? mapModel;

  MiniQuest.empty();

  MiniQuest.fromMap(String key, Map value) {
    id = key;
    mapModel = MapModel(addr: value["address"], lat: value["latitude"], lng: value["longitude"]);
    title = value["title"];
    rewards = value["rewards"];
    createdOn = value["createdOn"].millisecondsSinceEpoch;
    takenOn = value["takenOn"]?.millisecondsSinceEpoch;
    expiry = value["expiry"];
    creator = value["creator"];
    taker = value["taker"];
    status = QuestStatus.values.firstWhere((element) => element.name == value["status"]);
  }

  MiniQuest._fromSnapshot(DocumentSnapshot doc) {
    id = doc.id;
    final data = doc.data() as Map;

    mapModel = MapModel(addr: data["address"], lat: data["latitude"], lng: data["longitude"]);
    title = data["title"];
    rewards = data["rewards"];
    createdOn = data["createdOn"].millisecondsSinceEpoch;
    takenOn = data["takenOn"]?.millisecondsSinceEpoch;
    expiry = data["expiry"];
    creator = data["creator"];
    taker = data["taker"];
    status = QuestStatus.values.firstWhere((element) => element.name == data["status"]);
  }

  Map<String, dynamic> _toJson() => {
        "address": mapModel?.addr,
        "latitude": mapModel?.lat,
        "longitude": mapModel?.lng,
        "title": title,
        "rewards": rewards,
        "createdOn": DateTime.fromMillisecondsSinceEpoch(createdOn),
        "takenOn": takenOn == null ? null : DateTime.fromMillisecondsSinceEpoch(takenOn!),
        "expiry": expiry,
        "creator": creator,
        "taker": taker,
        "status": status.name,
      };

  void _create(Transaction transaction) => transaction.set(FirestoreService.userQuestListCreatedDoc(creator), {id: _toJson()}, SetOptions(merge: true));

  void _update(Transaction transaction) {
    transaction.set(FirestoreService.userQuestListCreatedDoc(creator), {id: _toJson()}, SetOptions(merge: true));
    if (taker != null) transaction.set(FirestoreService.userQuestListTakenDoc(taker!), {id: _toJson()}, SetOptions(merge: true));
  }
}

class Quest extends MiniQuest with ClusterItem {
  String? description;
  int? deposit;

  @override
  LatLng get location => LatLng(mapModel!.lat, mapModel!.lng);

  Quest.empty() : super.empty() {
    creator = DataStore().currentUser!.uid;
  }

  Quest.fromSnapshot(DocumentSnapshot doc) : super._fromSnapshot(doc) {
    final data = doc.data() as Map;

    description = data["description"];
    deposit = data["deposit"];

    DataStore().addQuestCache(this);
  }

  Map<String, dynamic> toJson() {
    final map = super._toJson();
    map.addAll({
      "id": id,
      "geohash": mapModel?.geohash,
      "description": description,
      "deposit": deposit,
    });
    return map;
  }

  void create(Transaction transaction) {
    final questRef = FirestoreService.questsCol.doc();
    id = questRef.id;
    createdOn = DateTime.now().millisecondsSinceEpoch;

    transaction.set(questRef, toJson());
    super._create(transaction);
  }

  void update(Transaction transaction) {
    final ref = FirestoreService.questsCol.doc(id);

    transaction.update(ref, toJson());
    super._update(transaction);
  }

  Future<bool> questIsTaken() async {
    final doc = await FirestoreService.questsCol.doc(id).get();
    return doc.get("taker") != null;
  }

  void assignTaker(String uid) {
    taker = uid;
    status = QuestStatus.taken;
    takenOn = DateTime.now().millisecondsSinceEpoch;
    deposit = Configs.questDepositCost;
  }
}

class CacheQuest {
  final Quest quest;
  final int timestamp;

  const CacheQuest({required this.quest, required this.timestamp});
}

enum QuestStatus {
  untaken,
  taken,
  completed,
  expired,
  forfeited,
}

extension QuestStatusExtension on QuestStatus {
  String get name => toString().split('.').last;
}
