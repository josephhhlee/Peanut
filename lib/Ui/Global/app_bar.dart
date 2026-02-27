import 'package:flutter/material.dart';
import 'package:peanut/App/properties.dart';

class PeanutAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PeanutAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Properties.navigationBarIndex,
      builder: (context, value, child) => Visibility(
        visible: value != 0,
        child: Properties.appBars[value],
      ),
    );
  }
}
