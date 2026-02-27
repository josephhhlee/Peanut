import 'dart:async';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:peanut/App/data_store.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static StreamSubscription<LocationData>? _listener;

  static Future<void> init(BuildContext context) async {
    if (_listener != null) return;

    Future<bool> requestPermission() async {
      await Permission.locationWhenInUse.request();
      return await Permission.locationWhenInUse.request().isGranted;
    }

    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      await showOkAlertDialog(
        context: context,
        title: "Location Required",
        message: "Peanut App requires location data in order to run, please allow location service for this app from your system settings.",
        onWillPop: () async => false,
        barrierDismissible: false,
      );
      // ignore: use_build_context_synchronously
      return await init(context);
    } else {
      final location = Location();
      DataStore().locationData = await location.getLocation();
      _listener = location.onLocationChanged.listen(DataStore().updateLocation);
    }
  }

  static void dispose() => _listener?.cancel();
}
