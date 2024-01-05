import 'dart:convert';
import 'dart:io';

import 'package:badges/badges.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Home/notification.dart';
import 'package:loyalty/Home/tab_service.dart';
import 'package:flutter/material.dart';
import 'package:loyalty/Config/tabsettings.dart';
import 'package:loyalty/Home/more.dart';
import 'package:loyalty/Loyalty/all_coupons_list.dart';
import 'package:loyalty/Loyalty/campaigns_list.dart';
import 'package:loyalty/Loyalty/scan_loyalty.dart';
import 'package:loyalty/MenuDrawer/menu.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:loyalty/globle.dart' as globals;

import '../globle.dart';

class TabsPage extends StatefulWidget {
  final int openTab;
  List tabsLists = [];
  final int msgTab;
  final String update;
  final int postindex;
  TabsPage(
      {Key key,
      @required this.openTab,
      @required this.tabsLists,
      this.msgTab,
      this.update,
      this.postindex})
      : super(key: key);
  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String notificationCount = "0";

  TabController _tabController;
  TabService _tabService = TabService();

  Color mainColor = Style().primaryColor;
  String _fontFamily = "Ubuntu";

  List _pageList = [];
  List _arrayTab = [];

  List _defaultTab = TabSettings().defaultTab;
  final _provider = FunctionProvider();

  final _appconfig = AppConfig();
  final _apiurl = ApiUrl();

  String _deviceid = "";
  String _domaindesc = "";

  var _userData = {};

  @override
  void initState() {
    super.initState();
    getfooter();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  getfooter() {
    _arrayTab = _defaultTab;

    _tabController = new TabController(length: _arrayTab.length, vsync: this);
    _tabController.index = widget.openTab;
    _tabService.setCurrentIndex(_tabController.index);
    _tabController.addListener(() {
      _tabService.setCurrentIndex(_tabController.index);
      setState(() {});
    });
    getPages();
  }

  getPages() async {
    _pageList = [
      {"t4": "ScanLoyalty()", "page": ScanLoyalty()},
      {"t4": "CampaignsList()", "page": CampaignsList(true)},
      {"t4": "AllCouponsList()", "page": AllCouponsList(_scaffoldKey, true)},
      {"t4": "NotificationPage()", "page": NotificationPage()},
      {"t4": "MoreApp()", "page": MoreApp()},
    ];
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("menulist", _provider.setJsonEncrypt(_arrayTab));
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    if (_userData['domaindesc'] != null) {
      _domaindesc = _userData['domaindesc'];
      print("DOMAIN DESC>>> $_domaindesc");
    }
    getUser(_userData);
    getNotiCount();
    checkDomain();
    setState(() {});
  }

  getUser(user) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/signin';
    var fcmtoken = _provider.getDecrypt(prefs.getString("fcm_Token"));
    var domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
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

    debugPrint("signin user body 111 >>>>" + body);

    debugPrint("ATok>> $token");

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin user result 111 >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString('userdata', _provider.setJsonEncrypt(result));
          _userData = result;
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          getUser(user);
          setState(() {});
        } else {
          // _showSnackBar(result['status']);
        }
      } else {
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getNotiCount() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetnoticount';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            // _loading = false;
            debugPrint(_provider.connectionError);
          });
        });

    debugPrint("get noti count body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get noti count result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          for (var i = 0; i < _arrayTab.length; i++) {
            if (_arrayTab[i]['pagename'] == "NotificationPage()") {
              _arrayTab[i]['noti'] = result['list'].toString();
              globals.notiresult.value = result['list'].toString();
              // print("NOTICOUNT>> ${globals.notiresult.value}");
            }
          }
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          getNotiCount();
        } else {
          // _loading = false;
          // _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        // _loading = false;
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  checkDomain() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'checkdomain';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token =
        _provider.getDecrypt(prefs.getString("app_to_provider.getDecrypt(ken"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            // _loading = false;
            debugPrint(_provider.connectionError);
          });
        });

    debugPrint("check domain body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("check domain result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString(
              "domain_data", _provider.setJsonEncrypt(result['domain']));
          prefs.setString("organizationslist",
              _provider.setJsonEncrypt(result['organizations']));
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          checkDomain();
        } else {
          // _loading = false;
          // _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        // _loading = false;
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  onTabTapped(aIndex) {
    _tabController.index = aIndex;
  }

  @override
  Widget build(BuildContext context) {
    Widget _bottomTab(index) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            onTabTapped(index);
            setState(() {});
          },
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF607B8B),
                  width: 0.3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ValueListenableBuilder(
                    valueListenable: globals.notiresult,
                    builder: (context, value, widget) {
                      return Container(
                        height: 20,
                        width: 20,
                        child: Badge(
                          shape: BadgeShape.circle,
                          showBadge: (value == "0")
                              ? false
                              : (_arrayTab[index]["noti"] == "" ||
                                      _arrayTab[index]["noti"] == null ||
                                      _arrayTab[index]["noti"] == "[]" ||
                                      _arrayTab[index]["noti"] == '0')
                                  ? false
                                  : true,
                          position: BadgePosition.topEnd(top: -5, end: -15),
                          padding: EdgeInsets.all(4),
                          toAnimate: false,
                          badgeContent: Container(
                            alignment: Alignment.center,
                            width: 22,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                          ),
                          child: Image(
                            image: AssetImage(_arrayTab[index]["url"]),
                            color: (_tabService.currentIndex == index)
                                ? Color(0xFF0498D4)
                                : Color(0xFF607B8B),
                          ),
                        ),
                      );
                    }),
                SizedBox(height: 3),
                Text(
                  _arrayTab[index]["name"],
                  style: TextStyle(
                    color: (_tabService.currentIndex == index)
                        ? Color(0xFF0498D4)
                        : Color(0xFF607B8B),
                    fontSize: 10,
                    fontWeight: (_tabService.currentIndex == index)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _bottomTabCircle(index) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            onTabTapped(index);
            setState(() {});
          },
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF607B8B),
                  width: 0.3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: (_tabService.currentIndex == index)
                        ? Color(0xFF0498D4)
                        : Color(0xFF607B8B),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue[200],
                        blurRadius: 2,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Badge(
                    shape: BadgeShape.circle,
                    showBadge: (_arrayTab[index]["noti"] == "" ||
                            _arrayTab[index]["noti"] == null ||
                            _arrayTab[index]["noti"] == '0')
                        ? false
                        : true,
                    position: BadgePosition.topEnd(top: -5, end: -15),
                    padding: EdgeInsets.all(4),
                    toAnimate: false,
                    badgeContent: Container(
                      alignment: Alignment.center,
                      width: 22,
                      child: Text(
                        _arrayTab[index]["noti"],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    child: Image(
                      image: AssetImage(_arrayTab[index]["url"]),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _arrayTab.length,
      child: WillPopScope(
        onWillPop: _tabService.currentIndex != 0
            ? () async {
                _tabController.index = 0;
                _tabService.setCurrentIndex(_tabController.index);
                setState(() {});
                return false;
              }
            : () async {
                exit(0);
              },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          // drawer: MenuPage(),
          appBar: (_arrayTab[_tabController.index]['pagename'] !=
                  "AllCouponsList()")
              ? AppBar(
                  elevation: 0,
                  iconTheme: IconThemeData(color: mainColor),
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.white,
                  centerTitle: true,
                  title: Text(
                    _domaindesc,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      fontSize: 20,
                    ),
                  ),
                )
              : null,
          body: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              _arrayTab.length,
              (index) {
                var a = 0;
                int page = 0;
                for (var i = 0; i < _pageList.length; i++) {
                  if (_arrayTab[index]["pagename"].toString() ==
                      _pageList[i]["t4"].toString()) {
                    a = 1;
                    page = i;
                  }
                }
                return (a == 1) ? _pageList[page]['page'] : null;
              },
            ),
            controller: _tabController,
          ),
          bottomNavigationBar: (_arrayTab.length > 1)
              ? BottomAppBar(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _arrayTab.length,
                      (index) {
                        return (_arrayTab[index]['pagename'] == "ScanLoyalty()")
                            ? _bottomTabCircle(index)
                            : _bottomTab(index);
                      },
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
