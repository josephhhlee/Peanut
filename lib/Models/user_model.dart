import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/Services/firestore_service.dart';

class NutUser {
  late final String uid;
  late final String email;
  late final int createdOn;
  late final PrivateData? private;

  late String displayName;
  late String? displayPhoto;
  late bool verified;
  late bool online;
  late int lastOnline;

  NutUser({required this.uid, required this.email, required this.displayName, this.displayPhoto, this.verified = false, required this.createdOn});

  NutUser.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map;

    uid = data["uid"];
    email = data["email"];
    displayName = data["displayName"];
    displayPhoto = data["displayPhoto"];
    verified = data["verified"];
    createdOn = data["createdOn"]?.millisecondsSinceEpoch;
    online = data["online"];
    lastOnline = data["lastOnline"].millisecondsSinceEpoch;

    DataStore().addUserCache(this);
  }

  Map<String, dynamic> _toJson() => {
        "uid": uid,
        "email": email,
        "displayName": displayName,
        "displayPhoto": displayPhoto,
        "verified": verified,
        "createdOn": DateTime.fromMillisecondsSinceEpoch(createdOn),
      };

  void create(Transaction transaction) => transaction.set(FirestoreService.usersCol.doc(uid), _toJson());

  void update(Transaction transaction) => transaction.update(FirestoreService.usersCol.doc(uid), _toJson());

  Future<int> getPeanutCurrency() async {
    final doc = await FirestoreService.peanutCurrencyDoc(uid).get();
    return doc.get("value");
  }

  void updatePeanutCurrency(int value, Transaction transaction) {
    final ref = FirestoreService.peanutCurrencyDoc(uid);
    final data = {"value": value};
    transaction.set(ref, data, SetOptions(merge: true));
  }

  Future<void> updateOnlineStatus(bool online) async {
    await FirestoreService.usersCol.doc(uid).update({"online": online, "lastOnline": DateTime.now()});
  }
}

class PrivateData {}

class CacheUser {
  final NutUser user;
  final int timestamp;

  const CacheUser({required this.user, required this.timestamp});
}
