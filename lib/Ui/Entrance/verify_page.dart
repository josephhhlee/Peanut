import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Services/authentication_service.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Ui/Entrance/splash_screen_page.dart';

class VerifyPage extends StatelessWidget {
  static const routeName = "/verify";

  VerifyPage(this.enableReset, {super.key});

  final bool? enableReset;
  final _auth = FirebaseAuth.instance;
  final ValueNotifier<int> _count = ValueNotifier(0);
  final int timer = Configs.verificationResendTimer;

  void _initTimer(BuildContext context) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count.value > 0) _count.value--;
      _checkEmailVerified(context, timer);
    });
  }

  Future<void> _checkEmailVerified(BuildContext context, Timer timer) async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      log(e.toString());
    }
    if (_auth.currentUser?.emailVerified ?? false) {
      timer.cancel();
      await FirestoreService.usersCol.doc(_auth.currentUser?.uid).update({"verified": true}).then((_) {
        Navigation.push(context, SplashScreenPage.routeName, clear: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _count.value = (enableReset ?? true) ? 0 : timer;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTimer(context));

    return WillPopScope(
      onWillPop: () async {
        AuthenticationService.logout();
        return true;
      },
      child: Scaffold(
        backgroundColor: PeanutTheme.transparent,
        body: PeanutTheme.background(
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: _body(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    var width = MediaQuery.of(context).size.width < 500 ? MediaQuery.of(context).size.width : 500.0;
    var menuPadding = 30.0;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: menuPadding, vertical: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _backButton(context),
          _title("Check Your Email", "A Verification Link Has Been Sent To"),
          const SizedBox(height: 45),
          _btnMsg(),
          const SizedBox(height: 10),
          _mainButton("resend verification link"),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () {
          AuthenticationService.logout();
          Navigation.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 40,
        ),
      ),
    );
  }

  Widget _title(String header, String desc) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          ),
          Text(
            desc,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            _auth.currentUser?.email ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PeanutTheme.darkOrange),
          ),
        ],
      ),
    );
  }

  Widget _btnMsg() {
    return ValueListenableBuilder(
      valueListenable: _count,
      builder: (_, value, __) => value == 0
          ? const SizedBox.shrink()
          : Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 5,
              children: [
                const Text(
                  "Resend link after",
                  style: TextStyle(color: PeanutTheme.almostBlack),
                ),
                Text(
                  "$value seconds",
                  style: const TextStyle(color: PeanutTheme.darkOrange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  Widget _mainButton(String button) {
    return SizedBox(
      height: 45,
      width: double.infinity,
      child: ValueListenableBuilder(
        valueListenable: _count,
        builder: (_, value, __) => ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
            ),
          ),
          onPressed: value > 0
              ? null
              : () {
                  _auth.currentUser?.sendEmailVerification();
                  _count.value = timer;
                },
          child: Text(button.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
