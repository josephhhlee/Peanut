// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/Models/quest_model.dart';
import 'package:peanut/Models/user_model.dart';
import 'package:peanut/Services/authentication_service.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Services/location_service.dart';
import 'package:peanut/Ui/Global/home_page.dart';
import 'dart:developer';

class SplashScreenViewModel {
  final datastore = DataStore();

  Future<void> init(BuildContext context) async {
    if (Configs.pause) return;
    final loggedIn = await AuthenticationService.checkForLogin(redirect: true);
    if (loggedIn) {
      await LocationService.init(context);
      await initMapTheme();
      await initCurrentUser();
      // await _troubleshoot();
      DataStore().setDataInitialized(true);
      Navigation.push(context, HomePage.routeName, clear: true);
    }
  }

  Future<void> initCurrentUser() async {
    datastore.currentUser = NutUser.fromSnapshot(await FirestoreService.usersCol.doc(FirebaseAuth.instance.currentUser!.uid).get());
    await datastore.currentUser?.updateOnlineStatus(true);
  }

  Future<void> initMapTheme() async => datastore.mapTheme ??= await rootBundle.loadString('assets/map_theme.json');

  // ignore: unused_element
  Future<void> _troubleshoot() async {
    try {
      final snapshot = await FirestoreService.questsCol.get();
      for (final doc in snapshot.docs) {
        final quest = Quest.fromSnapshot(doc);
        quest.status = quest.taker != null ? QuestStatus.taken : QuestStatus.untaken;
        if (quest.taker != null && quest.takenOn == null) quest.takenOn = DateTime.now().millisecondsSinceEpoch;
        await doc.reference.set(quest.toJson());
        await FirestoreService.runTransaction((transaction) async {
          quest.update(transaction);
        });
      }
    } catch (e) {
      log("TROUBLESHOOT ERROR : $e");
    }
  }
}
