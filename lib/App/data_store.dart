import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:location/location.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/properties.dart';
import 'package:peanut/Models/quest_model.dart';
import 'package:peanut/Models/user_model.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;

class DataStore with ChangeNotifier {
  static DataStore? _instance;
  DataStore._();
  factory DataStore() => _instance ??= DataStore._();

  static late final SharedPreferences pref;
  static late final SecureStorage secureStorage;

  Future<void> init() async {
    pref = await SharedPreferences.getInstance();
    secureStorage = SecureStorage();
  }

  @override
  void dispose() {
    _peanutCurrencyListener?.cancel();
    setDataInitialized(false);
    super.dispose();
  }

  String? mapTheme;

  bool dataInitialised = false;

  int? currentUserPeanutCurrency;
  StreamSubscription<DocumentSnapshot>? _peanutCurrencyListener;
  NutUser? _currentUser;
  NutUser? get currentUser => _currentUser;
  set currentUser(NutUser? user) {
    _currentUser = user;
    if (user != null) {
      _peanutCurrencyListener = FirestoreService.peanutCurrencyDoc(user.uid).snapshots().listen((doc) {
        currentUserPeanutCurrency = doc.get("value");
        notifyListeners();
      });
    }
  }

  Future<void> setDataInitialized(bool dataInitialised) async {
    this.dataInitialised = dataInitialised;

    if (!dataInitialised) {
      await currentUser?.updateOnlineStatus(false);
      currentUser = null;
      currentUserPeanutCurrency = null;
      _peanutCurrencyListener?.cancel();
      _peanutCurrencyListener = null;
      Properties.reset();
      secureStorage.clearCache();
    }
    notifyListeners();
  }

  LocationData? locationData;
  void updateLocation(LocationData locationData) {
    this.locationData = locationData;
    notifyListeners();
  }

  void addLocationListener(Function(LocationData? location) function) => addListener(() => function(locationData));

  final Map<String, CacheUser> _userCache = {};
  void addUserCache(NutUser user) {
    final cacheUser = CacheUser(user: user, timestamp: DateTime.now().millisecondsSinceEpoch);
    _userCache[cacheUser.user.uid] = cacheUser;
  }

  Future<NutUser?> getUser(String? uid, {bool fromDB = false}) async {
    Future<NutUser> fetchFromDB() async {
      final doc = await FirestoreService.usersCol.doc(uid).get();
      final user = NutUser.fromSnapshot(doc);
      return user;
    }

    Future<NutUser> fetchFromCache() async {
      if (uid == currentUser!.uid) return currentUser!;

      var cacheUser = _userCache[uid];
      if (cacheUser == null) {
        return await fetchFromDB();
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        final isExpired = (now - cacheUser.timestamp) > Configs.cacheExpiry;
        return isExpired ? await fetchFromDB() : cacheUser.user;
      }
    }

    if (uid == null || uid.isEmpty) return null;

    try {
      if (fromDB) {
        return await fetchFromDB();
      } else {
        return await fetchFromCache();
      }
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  final Map<String, CacheQuest> _questCache = {};
  void addQuestCache(Quest quest) {
    final cacheQuest = CacheQuest(quest: quest, timestamp: DateTime.now().millisecondsSinceEpoch);
    _questCache[cacheQuest.quest.id] = cacheQuest;
  }

  Future<Quest?> getQuest(String? id, {bool fromDB = false}) async {
    Future<Quest> fetchFromDB() async {
      final doc = await FirestoreService.questsCol.doc(id).get();
      final quest = Quest.fromSnapshot(doc);
      return quest;
    }

    Future<Quest> fetchFromCache() async {
      var cacheQuest = _questCache[id];
      if (cacheQuest == null) {
        return await fetchFromDB();
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        final isExpired = (now - cacheQuest.timestamp) > Configs.cacheExpiry;
        return isExpired ? await fetchFromDB() : cacheQuest.quest;
      }
    }

    if (id == null || id.isEmpty) return null;

    try {
      if (fromDB) {
        return await fetchFromDB();
      } else {
        return await fetchFromCache();
      }
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  static Future<void> storeLinkPreview(String link, PreviewData preview) async {
    final data = {"preview": jsonEncode(preview), "timestamp": DateTime.now().millisecondsSinceEpoch};
    await pref.setString("$link-preview", jsonEncode(data));
  }

  static PreviewData? getLinkPreview(String link) {
    final rawData = pref.getString("$link-preview");
    if (rawData == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final offset = now - 604800000;
    final data = jsonDecode(rawData);
    if (data["timestamp"] < offset) return null;
    return PreviewData.fromJson(jsonDecode(data["preview"]));
  }
}

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> clearCache() async {
    await _storage.deleteAll(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(
      key: key,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  Future<dynamic> read(String key) async {
    var value = await _storage.read(
      key: key,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
    return value == null ? value : jsonDecode(value);
  }

  Future<void> write(String key, dynamic value) async {
    await _storage.write(
      key: key,
      value: jsonEncode(value),
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  Future<void> remove(String key) async {
    await _storage.delete(
      key: key,
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  AndroidOptions _getAndroidOptions() => const AndroidOptions(resetOnError: true, encryptedSharedPreferences: false);

  IOSOptions _getIOSOptions() => const IOSOptions(accessibility: KeychainAccessibility.first_unlock);
}

class CachedUserData extends StatefulWidget {
  final String uid;
  final Widget Function(NutUser? user) builder;
  final Widget? placeHolder;

  const CachedUserData({super.key, required this.uid, required this.builder, this.placeHolder});

  @override
  State<CachedUserData> createState() => _CachedUserDataState();
}

class _CachedUserDataState extends State<CachedUserData> {
  NutUser? user;

  @override
  void initState() {
    initialize().whenComplete(() {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  Future initialize() async => user = await DataStore().getUser(widget.uid);

  @override
  Widget build(BuildContext context) {
    return user != null || widget.placeHolder == null ? widget.builder(user) : widget.placeHolder!;
  }
}
