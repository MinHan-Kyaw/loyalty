import 'dart:convert';

import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Verify/verification.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:loyalty/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SignOutDialog extends StatefulWidget {
  final userdata;
  bool all;
  SignOutDialog(this.userdata, this.all);
  @override
  _SignOutDialogState createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<SignOutDialog> {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  String _fontfamily = "Ubuntu";

  bool _allAccount = false;
  final _provider = FunctionProvider();

  var _userData = {};
  List _allAccList = [];

  List _arrayTab = [];
  Color mainColor = Style().primaryColor;

  String _deviceid = "";
  final _appconfig = AppConfig();

  final _apiurl = ApiUrl();
  String _outId = "";
  String _outName = "";

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
    _outId = widget.userdata['userid'];
    _outName = widget.userdata['username'];
    _allAccList = _provider.getJsonDecrypt(prefs.getString('userlist'));
    setState(() {});
  }

  updateUser(user, domain, domainid) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/signin';
    var fcmtoken = _provider.getDecrypt(prefs.getString("fcm_Token"));

    var body = jsonEncode({
      "username": user['username'],
      "userid": user['userid'],
      "imagename": user['imagename'],
      "domain": domain,
      "domainid": domainid,
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
          reSignin(context, user, user['atoken'], domain, domainid);
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

  reSignin(context, user, token, domain, domainid) async {
    debugPrint("USER>>> $user");
    final prefs = await SharedPreferences.getInstance();
    var deviceid = await FlutterUdid.udid;

    final url = _apiurl.iamurl + 'signin';

    var body = jsonEncode({
      "userid": user['userid'],
      "password": "",
      "uuid": deviceid,
      "recaptcha": "",
      "appid": _appconfig.appid,
      "skip": "true"
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {});

    debugPrint("resignin body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("resignin result >>>>" + result.toString());
        if (result['returncode'] == "310") {
          prefs.setString('app_token', _provider.setEncrypt(result['atoken']));
          List usr = [
            {
              "syskey": user["syskey"],
              "username": user["username"],
              "userid": user["userid"],
              "imagename": user["imagename"],
              "domains": user["domains"],
              "atoken": result['atoken'],
            }
          ];
          updateUser(usr[0], domain, domainid);

          // debugPrint("NEWUSRE>> ${usr[0]}");
          // getMenu(user, domainid);
        } else {
          // goLogout(context);
          Navigator.pop(context);
          _showSnackBar(result['message']);
        }
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
    imageCache.clear();
    prefs.setString("kun_verify", _provider.setEncrypt("true"));
    prefs.setString("kunyek_domain", _provider.setEncrypt(userData['domain']));
    prefs.setString('userdata', _provider.setJsonEncrypt(userData));
    prefs.setString('userlist', _provider.setJsonEncrypt(_allAccList));
    prefs.setString('app_token', _provider.setEncrypt(token));
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
      updateUser(_allAccList[0], _allAccList[0]['domains'][0]['shortcode'],
          _allAccList[0]['domains'][0]['domainid']);
    } else {
      goLogout();
    }
  }

  oneRemove() async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < _allAccList.length; i++) {
      if (_outId == _allAccList[i]['userid']) {
        _allAccList.remove(_allAccList[i]);
      }
    }
    prefs.setString('userlist', _provider.setJsonEncrypt(_allAccList));
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

  goLogout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("kun_verify", _provider.setEncrypt("false"));
    prefs.setString("userdata", _provider.setJsonEncrypt({}));
    prefs.setString('userlist', _provider.setJsonEncrypt([]));
    prefs.setString("menulist", _provider.setJsonEncrypt([]));
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

  displayLogout(context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          elevation: 24.0,
          title: Text(
            "Choose Account",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontFamily: _fontfamily,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              // height: MediaQuery.of(context).size.height / 5,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height / 5,
                maxHeight: MediaQuery.of(context).size.height / 3,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allAccList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context, _allAccList[index]);
                    },
                    child: Container(
                      child: Row(
                        children: <Widget>[
                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: Colors.black,
                            ),
                            child: Checkbox(
                              value: (_allAccList[index]['userid'] == _outId)
                                  ? true
                                  : false,
                              activeColor: Colors.black,
                              checkColor: Colors.white,
                              onChanged: (bool value) {},
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                (_allAccList[index]['username'] == "")
                                    ? Container()
                                    : Text(
                                        _allAccList[index]['username'],
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: _fontfamily,
                                        ),
                                      ),
                                Text(
                                  _allAccList[index]['userid'],
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontfamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
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
      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
      elevation: 24.0,
      title: Text(
        "Sign Out",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontFamily: _fontfamily,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 5),
            Text(
              "Are you sure you want to sign out?",
              // overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: _fontfamily,
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (_allAccList.length > 1) {
                  var changeuser = await displayLogout(context);
                  if (changeuser != null) {
                    _outId = changeuser['userid'];
                    _outName = changeuser['username'];
                  }
                }
                setState(() {});
              },
              child: Container(
                child: Row(
                  children: <Widget>[
                    Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.black,
                      ),
                      child: Checkbox(
                        value: true,
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        onChanged: (bool value) {},
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          (_outName == "")
                              ? Container()
                              : Text(
                                  _outName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontfamily,
                                  ),
                                ),
                          Text(
                            _outId,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontfamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    (_allAccList.length > 1)
                        ? Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                            size: 20,
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
            (widget.all)
                ? Container(
                    child: Row(
                      children: <Widget>[
                        Theme(
                          data: ThemeData(
                            unselectedWidgetColor: Colors.black,
                          ),
                          child: Checkbox(
                            value: _allAccount,
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                            onChanged: (bool value) {
                              setState(() {
                                _allAccount = value;
                              });
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_allAccount)
                              _allAccount = false;
                            else
                              _allAccount = true;
                            setState(() {});
                          },
                          child: Container(
                            child: Text(
                              "All Account",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: _fontfamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'No',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              if (_allAccount) {
                goLogout();
              } else {
                if (_outId == widget.userdata['userid']) {
                  oneLogOut();
                } else {
                  oneRemove();
                }
              }
            });
          },
          child: Text(
            'Yes',
            style: TextStyle(
              color: mainColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
