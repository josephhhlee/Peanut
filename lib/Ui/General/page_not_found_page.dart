import 'package:flutter/material.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';

class PageNotFoundPage extends StatelessWidget {
  static const routeName = "/page-not-found";

  const PageNotFoundPage({super.key});

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
              child: _content(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
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
            "ERROR 404\nPAGE NOT FOUND",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          const Text(
            "Page No Longer Exist.",
            style: TextStyle(color: PeanutTheme.almostBlack, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _goToHomeBtn(context),
        ],
      ),
    );
  }

  Widget _goToHomeBtn(BuildContext context) => ElevatedButton(
        onPressed: () => Navigation.popUntilHome(context),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.all(20),
        ),
        child: const Text(
          "Back to Main Page",
          style: TextStyle(color: PeanutTheme.white, fontSize: 18),
        ),
      );
}
