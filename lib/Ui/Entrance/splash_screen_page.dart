import 'package:flutter/material.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/ViewModels/splash_screen_viewmodel.dart';

class SplashScreenPage extends StatelessWidget {
  static const routeName = "/";

  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => SplashScreenViewModel().init(context));

    final screenSize = MediaQuery.of(context).size;
    final refSize = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final size = refSize / 4;

    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: screenSize.height,
          width: screenSize.width,
          alignment: Alignment.center,
          color: PeanutTheme.primaryColor,
          child: Container(
            height: size,
            width: size,
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 2)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  "assets/entrance_background.jpg",
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
                Container(
                  width: size,
                  height: size,
                  color: PeanutTheme.almostBlack.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: const Text(
                    "PEANUT",
                    style: TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
