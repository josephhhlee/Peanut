import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Ui/General/maintenance_page.dart';
import 'package:peanut/Ui/Entrance/splash_screen_page.dart';

class MaintenanceService {
  static late final StreamSubscription<DocumentSnapshot>? listener;

  static StreamSubscription<void> init() => listener = FirestoreService.maintenanceDoc.snapshots().listen(_updateMaintenanceStatus);

  static void _updateMaintenanceStatus(DocumentSnapshot doc) async {
    final platformActivate = Platform.isIOS ? "activateIOS" : "activateAndroid";

    if (doc.get(platformActivate) || doc.get("activate")) {
      Configs().maintenance = true;
      var msg = Map.from(doc.data() as Map)["customDescription"].trim();
      Configs().customMaintenanceMsg = msg.isEmpty ? null : msg;

      if (!Configs().connected) return;

      Navigation.navigator?.routeManager.clearAndPush(Uri.parse(MaintenancePage.routeName));
    } else if (Navigation.navigator?.currentConfiguration?.path == MaintenancePage.routeName) {
      Configs().maintenance = false;
      Navigation.navigator?.routeManager.clearAndPush(Uri.parse(SplashScreenPage.routeName));
    }
  }

  static void dispose() => listener?.cancel();
}
