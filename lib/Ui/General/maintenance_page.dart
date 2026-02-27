import 'package:flutter/material.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/theme.dart';

class MaintenancePage extends StatelessWidget {
  static const routeName = "/maintenance";

  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: PeanutTheme.transparent,
        body: PeanutTheme.background(
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: PeanutTheme.white,
        border: Border.all(color: PeanutTheme.greyDivider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "We'll Be Right Back!",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(
            Configs().customMaintenanceMsg ??
                "Peanut is down for required maintenance, but you should be able to get back on within a few minutes. Thanks for your patience as we improve the App.",
            style: const TextStyle(color: PeanutTheme.almostBlack, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
