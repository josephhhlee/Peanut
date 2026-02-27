import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:peanut/App/configs.dart';
import 'dart:developer';
import 'package:peanut/App/router.dart';
import 'package:peanut/Ui/General/maintenance_page.dart';
import 'package:peanut/Ui/General/no_network_page.dart';
import 'package:peanut/Ui/General/page_not_found_page.dart';
import 'package:peanut/Ui/Entrance/splash_screen_page.dart';
import 'package:peanut/Ui/Messenger/chat_page.dart';
import 'package:peanut/Ui/Quests/quest_page.dart';

class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static late final StreamSubscription<ConnectivityResult>? listener;
  static Uri? _pageToResume;
  static Timer? _networkTimer;

  static Future<void> init() async {
    await _initConnection();
    _networkListener();
  }

  static StreamSubscription<void> _networkListener() => listener = _connectivity.onConnectivityChanged.listen((_updateConnectionStatus));

  static Future<void> _initConnection() async {
    try {
      var result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      log('Couldn\'t check connectivity status', error: e);
    }
  }

  static void _updateConnectionStatus(ConnectivityResult result) {
    void handleNoNetwork() {
      if (_networkTimer!.isActive || result != ConnectivityResult.none) return;
      Configs().connected = false;
      Navigation.navigator?.routeManager.clearAndPush(Uri.parse(NoNetworkPage.routeName));
    }

    if (result == ConnectivityResult.none) {
      _pageToResume = Navigation.navigator?.currentConfiguration!;
      _networkTimer = Timer(const Duration(seconds: 2), handleNoNetwork);
    } else {
      Configs.initRemoteConfig();
      Configs().connected = true;
      _networkTimer?.cancel();

      if (_pageToResume != null) {
        var nonResumablePage = _pageToResume!.path.isEmpty ||
            _pageToResume!.path == PageNotFoundPage.routeName ||
            _pageToResume!.path == NoNetworkPage.routeName ||
            _pageToResume!.path == MaintenancePage.routeName ||
            _pageToResume!.path == QuestPage.routeName ||
            _pageToResume!.path == ChatPage.routeName;

        if (nonResumablePage) {
          Navigation.navigator?.routeManager.clearAndPush(Uri.parse(SplashScreenPage.routeName));
        } else {
          Navigation.navigator?.routeManager.clearAndPushAll([Uri.parse(SplashScreenPage.routeName), _pageToResume!]);
        }
        _pageToResume = null;
      }
    }
  }

  static void dispose() {
    listener?.cancel();
    _networkTimer?.cancel();
  }
}
