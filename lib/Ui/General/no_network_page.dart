import 'package:flutter/material.dart';
import 'package:peanut/App/theme.dart';

class NoNetworkPage extends StatelessWidget {
  static const routeName = "/no-network";

  const NoNetworkPage({super.key});

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
        children: const [
          Text(
            "Whoops!",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 36),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Text(
            "No internet connection. You need to be connected to the internet to use Peanut App.",
            style: TextStyle(color: PeanutTheme.almostBlack, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
