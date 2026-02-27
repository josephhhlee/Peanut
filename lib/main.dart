import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/properties.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/Services/location_service.dart';
import 'package:peanut/Services/maintenance_service.dart';
import 'package:peanut/Services/network_service.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'package:peanut/firebase_options.dart';
import 'package:provider/provider.dart';

void main({env = "dev"}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform(env: env));

  await Configs().init(env: env);
  await DataStore().init();
  Properties().init();

  if (env != "prod") await DataStore.pref.remove("onboarding");

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: PeanutTheme.transparent, statusBarIconBrightness: Brightness.dark));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: env == "prod" ? 1 : 0),
        ChangeNotifierProvider(create: (_) => DataStore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      await DataStore().currentUser?.updateOnlineStatus(false);
      await DataStore.secureStorage.clearCache();
    } else {
      if (state != AppLifecycleState.resumed) {
        await DataStore().currentUser?.updateOnlineStatus(false);
        NetworkService.listener?.pause();
        MaintenanceService.listener?.pause();
      } else {
        await DataStore().currentUser?.updateOnlineStatus(true);
        NetworkService.listener?.resume();
        MaintenanceService.listener?.resume();
      }
    }
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NetworkService.dispose();
    MaintenanceService.dispose();
    LocationService.dispose();
    Properties.dispose();
    DataStore().dispose();
    super.dispose();
  }

  Future<void> _init() async {
    Navigation.init();
    WidgetsBinding.instance.addObserver(this);
    await NetworkService.init();
    MaintenanceService.init();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLoaderOverlay(
      useDefaultLoading: false,
      overlayWidget: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3.0,
          sigmaY: 3.0,
        ),
        child: CommonUtils.loadingIndicator(),
      ),
      switchInCurve: Curves.bounceIn,
      switchOutCurve: Curves.bounceOut,
      overlayColor: PeanutTheme.almostBlack,
      overlayOpacity: 0.5,
      child: MaterialApp.router(
        title: "Peanut",
        theme: PeanutTheme.defaultTheme(),
        darkTheme: PeanutTheme.defaultTheme(),
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale.fromSubtags(languageCode: 'en', countryCode: 'SG')],
        routeInformationParser: InformationParser(),
        routerDelegate: Navigation.navigator,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
