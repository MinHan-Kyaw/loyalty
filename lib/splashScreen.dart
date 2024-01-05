import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Verify/verification.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty/globle.dart' as globals;

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _fontFamily = "Ubuntu";
  List _arrayTab = [];

  bool _checkGoPage = true;
  Color mainColor = Style().primaryColor;
  final _provider = FunctionProvider();
  final _appconfig = AppConfig();
  bool _fromNoti = false;

  // Noti Code
  var _msgData = {};
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings androidInitializationSettings;
  IOSInitializationSettings iosInitializationSettings;
  InitializationSettings initializationSettings;
  String _message = "";
  String _body = "";

  @override
  void initState() {
    super.initState();
    initializing();
    _configureFirebaseListeners();
    checkVerify();
    globals.main();
    setState(() {});
  }

  // Notification Code Start
  void initializing() async {
    androidInitializationSettings =
        AndroidInitializationSettings('mipmap/ic_launcher');
    iosInitializationSettings = IOSInitializationSettings();
    initializationSettings = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payLoad) async {
    goNotification();
  }

  _configureFirebaseListeners() async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        RemoteNotification notification = message.notification;
        print("Get Message Data =>>>");
        print(message.data);
        _navigateToPage(message.data);
        print("firebase message all >>>> $notification");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'channel.id',
                notification.title,
                channelDescription: notification.body,
                icon: 'launch_background',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      print('A new onMessageOpenedApp event was published!');
      _checkGoPage = false;
      print("Opened Data =>>>");
      print(event.data);
      var data = event.data;
      _navigateToPage(data);
    });

    return true;
  }

  Future _navigateToPage(_msgData) async {
    print("Navigate To Page");
    _fromNoti = true;
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    var _verify = _provider.getDecrypt(prefs.getString("kun_verify"));
    if (_verify == "true") {
      print("Verify True");
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return TabsPage(openTab: 3, tabsLists: _arrayTab);
      }));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return VerifyPage();
      }));
    }
  }
  // Notification Code End

  goNotification() async {
    _fromNoti = true;
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    var _verify = _provider.getDecrypt(prefs.getString("kun_verify"));
    if (_verify == "true") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return TabsPage(openTab: 3, tabsLists: _arrayTab);
      }));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return VerifyPage();
      }));
    }
  }

  checkVerify() async {
    // final data = await _configureFirebaseListeners();
    final prefs = await SharedPreferences.getInstance();
    var _verify = _provider.getDecrypt(prefs.getString("kun_verify"));

    if (_verify == "true") {
      await Future.delayed(Duration(seconds: 5));
      if (!_fromNoti) {
        goHome();
      }
    } else {
      _checkGoPage = false;
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return VerifyPage();
      }));
    }
  }

  goHome() async {
    if (_checkGoPage) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return TabsPage(openTab: 0, tabsLists: _arrayTab);
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(
            image: AssetImage("${_appconfig.projectLogo}"),
            width: 100,
            height: 100,
          ),
          Text(
            "Welcome to ${_appconfig.projectName}!",
            style: TextStyle(
              color: mainColor,
              fontSize: 25,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: Container(
              height: 30,
              child: SpinKitWave(
                color: mainColor,
                type: SpinKitWaveType.start,
                size: 40.0,
                itemCount: 5,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 35.0),
          child: Text(
            _appconfig.version,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
