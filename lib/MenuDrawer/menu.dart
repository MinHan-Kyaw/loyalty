import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:loyalty/MenuDrawer/add_account.dart';
import 'package:loyalty/MenuDrawer/profile.dart';
import 'package:loyalty/MenuDrawer/sign_out.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/loading.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:store_redirect/store_redirect.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  TextEditingController domaintextController = new TextEditingController();

  TextEditingController apptextController = new TextEditingController();
  TextEditingController usertextController = new TextEditingController();

  String _fontfamily = "Ubuntu";
  final _provider = FunctionProvider();

  bool _checkSettings = false;
  String _verify = "true";

  var _userData = {};
  List _allAccList = [];

  List _arrayTab = [];
  Color mainColor = Style().primaryColor;

  String _version = AppConfig().version;
  String _deviceid = "";

  List _profileList = [];
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

    debugPrint("user" + _userData.toString());
    debugPrint("user list" + _allAccList.toString());
    var profileList = _provider.getDecrypt(prefs.getString('profileList'));
    if (profileList != null && profileList != "" && profileList != "0") {
      _profileList = _provider.getJsonDecrypt(prefs.getString('profileList'));
    }

    getUser(_userData);
    getProfile(_userData, _allAccList);

    for (var i = 0; i < _allAccList.length; i++) {
      getDomain(_allAccList[i]['userid'], _allAccList[i]['atoken'], i);
    }
    setState(() {});
  }

  getUser(user) async {
    debugPrint("USR>> $user");
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/signin';
    var fcmtoken = _provider.getDecrypt(prefs.getString("fcm_Token"));
    var domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));
    var token = _provider.getDecrypt(prefs.getString('app_token'));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "username": user['username'],
      "userid": user['userid'],
      "imagename": user['imagename'],
      "domain": domain,
      "domainid": domainid,
      "domaintype": 1,
      "atoken": token,
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
            // _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("get user body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get user result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString('userdata', _provider.setJsonEncrypt(result));
          _userData = result;
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          getUser(user);
          setState(() {});
        } else {
          _showSnackBar(result['status']);
          // severError(result.toString(), user, token, domain);
          debugPrint("G U ERROR11 >>");
        }
      } else {
        debugPrint("G U ERROR >>");
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getDomain(phone, token, index) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'getdomain';
    var domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode(
        {"appid": _appconfig.appid, "userid": phone, "atoken": token});

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {});

    debugPrint("domain body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("domain result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          for (var i = 0; i < _allAccList.length; i++) {
            if (_allAccList[i]['userid'] == phone) {
              _allAccList[i]['domains'] = result['domains'];
            }
          }
          prefs.setString('userlist', _provider.setJsonEncrypt(_allAccList));
          setState(() {});
        } else if (result['returncode'] == "200") {
          await autoGetToken(context, index, phone, token, domain, domainid);
          getDomain(phone, _allAccList[index]['atoken'], index);
        }
      }
    }
  }

  getProfile(user, allusers) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/getprofile';
    var domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));
    var token = _provider.getDecrypt(prefs.getString('app_token'));

    var body = jsonEncode({
      "userid": user['userid'],
      "domain": domain,
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token,
      "list": allusers
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            // _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("get profile body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get user profile >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _profileList = result['list'];
          prefs.setString(
              'profileList', _provider.setJsonEncrypt(result['list']));
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          getProfile(user, allusers);
        }
      }
    }
  }

  autoGetToken(context, index, phone, token, domain, domainid) async {
    final url = _apiurl.urlname + 'checktokenkunyek';

    var body = jsonEncode({
      "userid": phone,
      "domain": domain,
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token,
      "password": "",
      "recaptcha": "",
      "uuid": _deviceid,
      "skip": "true"
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {});

    debugPrint("signin body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _allAccList[index]['atoken'] = result['atoken'];
          setState(() {});
        }
      }
    }
  }

  goUserDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(_userData),
      ),
    );
  }

  updateUser(user, domain, domainid) async {
    // debugPrint("UU>> $domain || $domainid");
    debugPrint("UU11>> $user");
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
          // getMenu(result, user['atoken'], domainid);

          getMenu(result, user['atoken'], domainid);
        } else if (result['returncode'] == "210") {
          reSignin(context, user, user['atoken'], domain, domainid);
        } else {
          Navigator.pop(context);
          _showSnackBar(result['status']);
          // severError(result.toString(), user, fcmtoken, domain);
        }
      } else {
        Navigator.pop(context);
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getMenu(userData, token, domainid) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'getpolicy';

    var body = jsonEncode({
      "userid": userData['userid'],
      "appid": _appconfig.appid,
      "domain": userData['domain'],
      "domainid": domainid,
      // userData['domain'] == null
      //     ? userData['domains'][0]['shortcode']
      //     : userData['domain'],
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
          gotoHome(userData, token, domainid);
        }
        // else if (result['returncode'] == "200") {
        //   await reSignin(context, userData, token, domain, domainid);
        //   // getMenu(userData, domain, domainid);
        // }
        else {
          Navigator.pop(context);
          _showSnackBar(result['message']);
          // severError(result.toString(), userData, token, userData['domain']);
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
    var userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
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
          // severError(result.toString(), user, token, domain);
        }
      }
    }
  }

  gotoHome(userData, token, domainid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("kun_verify", _provider.setEncrypt("true"));
    prefs.setString("kunyek_domain", _provider.setEncrypt(userData['domain']));
    prefs.setString("kunyek_domain_id", _provider.setEncrypt(domainid));
    prefs.setString('userdata', _provider.setJsonEncrypt(userData));
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TabsPage(
          openTab: 0,
          tabsLists: _arrayTab,
        ),
      ),
    );
  }

  displayLogout(context, all) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SignOutDialog(_userData, all);
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
    return Drawer(
      child: Column(
        children: <Widget>[
          _createHeader(),
          SizedBox(height: 5),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(0),
              children: <Widget>[
                _checkSettings
                    ? _createDrawerItem(
                        onTap: () {},
                        image: Image(
                          image: AssetImage('assets/images/language.png'),
                          height: 22,
                          width: 22,
                          color: Colors.grey,
                        ),
                        text: "Language",
                        checkBorder: false,
                        checkArrow: false,
                        checkPadding: true,
                      )
                    : Container(),
                _checkSettings
                    ? _createDrawerItem(
                        onTap: () {},
                        image: Image(
                          image: AssetImage('assets/images/theme.png'),
                          height: 22,
                          width: 22,
                          color: Colors.grey,
                        ),
                        text: "Theme",
                        checkBorder: false,
                        checkArrow: false,
                        checkPadding: true,
                      )
                    : Container(),
                _checkSettings
                    ? _createDrawerItem(
                        onTap: () {},
                        image: Image(
                          image: AssetImage('assets/images/placeholder.png'),
                          height: 22,
                          width: 22,
                          color: Colors.grey,
                        ),
                        text: "Set WFH Location",
                        checkBorder: true,
                        checkArrow: false,
                        checkPadding: true,
                      )
                    : Container(),
                Container(
                  padding: EdgeInsets.only(left: 20, top: 10),
                  alignment: Alignment.centerLeft,
                  // height: 35,
                  child: Text(
                    "Accounts",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: _fontfamily,
                    ),
                  ),
                ),
                Column(
                  children: List.generate(
                    _allAccList.length,
                    (index) {
                      return Column(
                        children: List.generate(
                            _allAccList[index]['domains'].length, (position) {
                          return _createAccItem(index, position);
                        }),
                      );
                    },
                  ),
                ),
                // _createDrawerItem(
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => AddAccountPage(),
                //       ),
                //     );
                //   },
                //   image: Image(
                //     image: AssetImage("assets/images/plus_icon.png"),
                //     height: 17,
                //     width: 17,
                //   ),
                //   text: "Add Account",
                //   checkBorder: true,
                //   checkArrow: false,
                //   checkPadding: false,
                // ),
                (_verify == "true")
                    ? _createDrawerItem(
                        onTap: () {
                          if (_allAccList.length > 1) {
                            displayLogout(context, true);
                          } else {
                            displayLogout(context, false);
                          }
                        },
                        image: Image(
                          image: AssetImage("assets/images/logout.png"),
                          height: 25,
                          width: 25,
                          color: Colors.grey[600],
                        ),
                        text: "Sign Out",
                        checkBorder: true,
                        checkArrow: false,
                        checkPadding: false,
                      )
                    : Container(),
                Container(
                  height: 45,
                  margin: EdgeInsets.only(top: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(),
                  child: GestureDetector(
                    onTap: () {
                      // StoreRedirect.redirect(
                      //     androidAppId: _appconfig.androidAppId,
                      //     iOSAppId: _appconfig.iOSAppId);
                    },
                    child: Text(
                      _version,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontfamily,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createHeader() {
    return Container(
      decoration: new BoxDecoration(
        color: mainColor,
      ),
      height: 205,
      // height: 220,
      child: DrawerHeader(
        margin: EdgeInsets.only(bottom: 0),
        padding: EdgeInsets.only(left: 0, right: 0, bottom: 0, top: 0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            goUserDetail();
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: 90,
                                width: 90,
                                margin: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                    ),
                                    child: (_userData['imagename'] != "" &&
                                            _userData['imagename'] != null)
                                        ? CachedNetworkImage(
                                            imageUrl: _userData['imagename'],
                                            placeholder: (context, url) =>
                                                Image(
                                              image: AssetImage(
                                                  "assets/images/man.png"),
                                              height: 85,
                                              width: 85,
                                              color: Colors.grey,
                                            ),
                                            height: 85,
                                            width: 85,
                                            fit: BoxFit.cover,
                                          )
                                        : Image(
                                            image: AssetImage(
                                                "assets/images/man.png"),
                                            height: 85,
                                            width: 85,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    goUserDetail();
                                  },
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            goUserDetail();
                          },
                          child: Text(
                            (_userData.length == 0)
                                ? "User Name"
                                : (_userData['username'] == "")
                                    ? _userData['userid']
                                    : _userData['username'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontfamily,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        GestureDetector(
                          onTap: () {
                            goUserDetail();
                          },
                          child: Text(
                            (_userData.length == 0)
                                ? "Phone Number"
                                : (_userData['username'] != "")
                                    ? _userData['userid']
                                    : "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w100,
                              fontFamily: _fontfamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Positioned(
              //   top: 0,
              //   right: 0,
              //   child: Container(
              //     child: Row(
              //       children: [
              //         GestureDetector(
              //           onTap: () {
              //             goUserDetail();
              //           },
              //           child: Container(
              //             child: Icon(
              //               Icons.edit_outlined,
              //               color: Colors.grey[200],
              //             ),
              //           ),
              //         ),
              //         SizedBox(width: 10),
              //         GestureDetector(
              //           onTap: () {},
              //           child: Container(
              //             child: Icon(
              //               Icons.qr_code,
              //               color: Colors.grey[200],
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createDrawerItem(
      {IconData icon,
      Image image,
      String text,
      bool checkBorder,
      bool checkArrow,
      bool checkPadding,
      GestureTapCallback onTap}) {
    return Container(
      height: 45,
      margin: EdgeInsets.only(left: 5, right: 5),
      padding:
          checkPadding ? EdgeInsets.only(left: 25) : EdgeInsets.only(left: 15),
      decoration: checkBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE1E0E0),
                  width: 1.3,
                ),
              ),
            )
          : BoxDecoration(),
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        title: Container(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 35,
                child: image,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: checkPadding ? Colors.black54 : Colors.black,
                    fontSize: checkPadding ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontfamily,
                  ),
                ),
              ),
              checkArrow
                  ? Container(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: _checkSettings
                          ? Image(
                              image: AssetImage('assets/images/down_arrow.png'),
                              color: Colors.grey,
                              width: 17.0,
                              height: 17.0,
                            )
                          : Image(
                              image: AssetImage('assets/images/next_arrow.png'),
                              color: Colors.grey,
                              width: 17.0,
                              height: 17.0,
                            ),
                    )
                  : Container(),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _createAccItem(aIndex, aPosition) {
    var imageurl = "";
    for (var i = 0; i < _profileList.length; i++) {
      if (_profileList[i]['userid'] == _allAccList[aIndex]['userid'] &&
          _profileList[i]['domain'] ==
              _allAccList[aIndex]['domains'][aPosition]['shortcode']) {
        debugPrint("user profile get");
        imageurl = _profileList[i]['imagename'];
      }
    }
    return Container(
      height: (aIndex != _allAccList.length - 1) ? 48 : 53,
      margin: EdgeInsets.only(left: 5, right: 5),
      padding: EdgeInsets.only(left: 15),
      decoration: (aPosition == _allAccList[aIndex]['domains'].length - 1)
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE1E0E0),
                  width: 1.3,
                ),
              ),
            )
          : BoxDecoration(),
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        title: Container(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: <Widget>[
              Container(
                padding: (imageurl != "" && imageurl != null)
                    ? EdgeInsets.all(0)
                    : EdgeInsets.all(7.5),
                width: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.grey,
                ),
                child: (imageurl != "" && imageurl != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: CachedNetworkImage(
                          imageUrl: imageurl,
                          placeholder: (context, url) => Image(
                            image: AssetImage('assets/images/accIcon.png'),
                            height: 20,
                            width: 20,
                            color: Colors.grey[300],
                          ),
                          height: 35,
                          width: 35,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image(
                        image: AssetImage('assets/images/accIcon.png'),
                        color: Colors.grey[300],
                        width: 20,
                        height: 20,
                      ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      (_allAccList[aIndex]['domains'][aPosition]
                                  ['description'] ==
                              "Public")
                          // ? "Public"
                          ? "Town Hall"
                          : _allAccList[aIndex]['domains'][aPosition]
                              ['description'],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontfamily,
                      ),
                    ),
                    Text(
                      _allAccList[aIndex]['userid'],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontfamily,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              (_allAccList[aIndex]['domains'][aPosition]['shortcode'] ==
                          _userData['domain'] &&
                      _allAccList[aIndex]['userid'] == _userData['userid'])
                  ? Container(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image(
                        image: AssetImage('assets/images/btn_img.png'),
                        color: mainColor,
                        width: 17,
                        height: 17,
                      ),
                    )
                  : Container(
                      width: 17,
                      height: 17,
                    ),
            ],
          ),
        ),
        onTap: () {
          if (_allAccList[aIndex]['domains'][aPosition]['shortcode'] ==
                  _userData['domain'] &&
              _allAccList[aIndex]['userid'] == _userData['userid']) {
            debugPrint("Already Switch");
          } else {
            LoadingPage.showLoadingDialog(context, _keyLoader);
            updateUser(
                _allAccList[aIndex],
                _allAccList[aIndex]['domains'][aPosition]['shortcode'],
                _allAccList[aIndex]['domains'][aPosition]['domainid']);
          }
        },
      ),
    );
  }
}
