import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/splashScreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const bool isProduction = bool.fromEnvironment('dart.vm.product');

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();

    if (isProduction) {
      debugPrint = (String message, {int wrapWidth}) => null;
    }
    runApp(MyApp());
  }, (error, stack) {
  }, zoneSpecification: new ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
    // Print only in debug mode

    if (kDebugMode) {
      parent.print(zone, message);
    }
  }));
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final _provider = FunctionProvider();

  @override
  void initState() {
    getPerFcm();
    _clearApp();
    imageCache.clear();
    super.initState();
    FlutterStatusbarcolor.setStatusBarColor(Color(0xFFADD8E6));
    FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
  }

  getPerFcm() async {
    _getFCMToken();
  }

  _getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    FirebaseMessaging.instance.getToken().then((value) {
      prefs.setString("fcm_Token", value.toString());
    });

    var tok = prefs.getString("fcm_Token")??"";
    print("FCM_TOKEN>>> $tok");

  }

  _clearApp() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("backdate_dialog", _provider.setEncrypt("0"));
    var clearApp = _provider.getDecrypt(prefs.getString("clearApp")) ?? "";
    if (clearApp == "") {
      prefs.setString("clearApp", _provider.setEncrypt("clear"));
      _deleteCacheDir();
    }
  }

  Future<void> _deleteCacheDir() async {
    final cacheDir = Directory((await getTemporaryDirectory()).path);

    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreenPage(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
