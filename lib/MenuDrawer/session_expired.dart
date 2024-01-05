import 'dart:convert';

import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Verify/verification.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/loading.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionExpired extends StatefulWidget {
  @override
  _SessionExpiredState createState() => _SessionExpiredState();
}

class _SessionExpiredState extends State<SessionExpired> {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  final _provider = FunctionProvider();

  var _userData = {};
  List _allAccList = [];

  List _arrayTab = [];
  Color mainColor = Style().primaryColor;

  String _deviceid = "";
  final _appconfig = AppConfig();

  final _apiurl = ApiUrl();

  @override
  void initState() {
    super.initState();
    getData();
    setState(() {});
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceid = await FlutterUdid.udid;
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    _allAccList = _provider.getJsonDecrypt(prefs.getString('userlist'));
    setState(() {});
  }

  updateUser(user, domain) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/signin';
    var fcmtoken = _provider.getDecrypt(prefs.getString("fcm_Token"));

    var body = jsonEncode({
      "username": user['username'],
      "userid": user['userid'],
      "imagename": user['imagename'],
      "domain": domain,
      "domaintype": 1,
      "atoken": user['atoken'],
      "appid": _appconfig.appid,
      "uuid": _deviceid,
      "fcmtoken": fcmtoken,
      "n1": _appconfig.appName,
      "version": _appconfig.version1
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            Navigator.pop(context);
            _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("signin user body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin user result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          getMenu(result, user['atoken']);
        } else if (result['returncode'] == "210") {
          for (var i = 0; i < _allAccList.length; i++) {
            if (user['userid'] == _allAccList[i]['userid']) {
              _allAccList.remove(_allAccList[i]);
            }
          }
          oneLogOut();
        } else {
          Navigator.pop(context);
          _showSnackBar(result['status']);
        }
      } else {
        Navigator.pop(context);
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getMenu(userData, token) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'getpolicy';

    var body = jsonEncode({
      "userid": userData['userid'],
      "appid": _appconfig.appid,
      "domain": userData['domain'],
      "type": "0", // 0 for menu
      "atoken": token,
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            Navigator.pop(context);
            _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("menu body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("menu result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString("menulist", _provider.setJsonEncrypt(result['json']));
          _arrayTab = result['json'];
          gotoHome(userData, token);
        } else {
          Navigator.pop(context);
          _showSnackBar(result['message']);
        }
      } else {
        Navigator.pop(context);
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  gotoHome(userData, token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("kun_verify",_provider.setEncrypt("true"));
    prefs.setString("kunyek_domain",_provider.setEncrypt(userData['domain']));
    prefs.setString('userdata', _provider.setJsonEncrypt(userData));
    prefs.setString('userlist', _provider.setJsonEncrypt(_allAccList));
    prefs.setString('app_token',_provider.setEncrypt(token));
    prefs.setString('menutype',_provider.setEncrypt('all'));
    prefs.setString('showmore', _provider.setEncrypt("0"));
    prefs.setString('campaignslist', _provider.setEncrypt("0"));
    prefs.setString('winnercampaignslist', _provider.setEncrypt("0"));
    prefs.setString('couponslist', _provider.setEncrypt("0"));
    prefs.setString("coupon_filtercode", _provider.setEncrypt("0"));
    prefs.setString("notilist", _provider.setEncrypt("0"));
    prefs.setString('showmore_profile', _provider.setEncrypt("0"));
    prefs.setString("domain_data", _provider.setEncrypt("0"));
    prefs.setString("organizationslist", _provider.setEncrypt("0"));

    Navigator.pop(context);
    Navigator.pop(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TabsPage(
          openTab: 0,
          tabsLists: _arrayTab,
        ),
      ),
    );
  }

  oneLogOut() async {
    for (var i = 0; i < _allAccList.length; i++) {
      if (_userData['userid'] == _allAccList[i]['userid']) {
        _allAccList.remove(_allAccList[i]);
      }
    }
    if (_allAccList.length > 0) {
      LoadingPage.showLoadingDialog(context, _keyLoader);
      updateUser(_allAccList[0], _allAccList[0]['domains'][0]['shortcode']);
    } else {
      goLogout();
    }
  }

  goLogout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("kun_verify", _provider.setEncrypt("false"));
    prefs.setString("userdata", _provider.setJsonEncrypt({}));
    prefs.setString('userlist', _provider.setJsonEncrypt([]));
    prefs.setString("menulist", _provider.setJsonEncrypt([]));
    prefs.setString('menutype', _provider.setEncrypt('all'));
    prefs.setString('showmore', _provider.setEncrypt("0"));
    prefs.setString('campaignslist', _provider.setEncrypt("0"));
    prefs.setString('winnercampaignslist', _provider.setEncrypt("0"));
    prefs.setString('couponslist', _provider.setEncrypt("0"));
    prefs.setString("coupon_filtercode", _provider.setEncrypt("0"));
    prefs.setString("notilist", _provider.setEncrypt("0"));
    prefs.setString('showmore_profile', _provider.setEncrypt("0"));
    prefs.setString("domain_data", _provider.setEncrypt("0"));
    prefs.setString("organizationslist", _provider.setEncrypt("0"));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return VerifyPage();
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      elevation: 24.0,
      content: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[350],
                width: 1.0,
              ),
            ),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  "Session Expired",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                child: Text(
                  "Please Sign In Again.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            oneLogOut();
          },
          child: Container(
            width: 300,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
