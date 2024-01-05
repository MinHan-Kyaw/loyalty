import 'dart:convert';
// import 'dart:html';
import 'dart:io' show Platform;

import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Config/appsettings.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Loyalty/all_coupons_list.dart';
import 'package:loyalty/Loyalty/campaigns_list.dart';
import 'package:loyalty/Loyalty/rules.dart';
import 'package:loyalty/Loyalty/scan_loyalty.dart';
import 'package:loyalty/Loyalty/winner_campaigns_list.dart';
import 'package:loyalty/MenuDrawer/profile.dart';
import 'package:flutter/material.dart';
import 'package:loyalty/MenuDrawer/sign_out.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class MoreApp extends StatefulWidget {
  @override
  _MoreAppState createState() => _MoreAppState();
}

class _MoreAppState extends State<MoreApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Color mainColor = Style().primaryColor;
  final _provider = FunctionProvider();

  final _apiurl = ApiUrl();
  List _pageList = [];

  List _arrayTab = [];
  var _userData = {};

  String _version = AppConfig().version;
  String _fontfamily = "Ubuntu";

  List _arrayCard = AppSettings().arrayCard;
  final _appconfig = AppConfig();

  @override
  void initState() {
    super.initState();
    getData();
    getPages();
    setState(() {});
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    setState(() {});
  }

  getPages() async {
    final prefs = await SharedPreferences.getInstance();
    _arrayTab = _provider.getJsonDecrypt(prefs.getString('menulist'));
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    _pageList = [
      {"t4": "ScanLoyalty()", "page": ScanLoyalty()},
      {"t4": "CampaignsList()", "page": CampaignsList(true)},
      {"t4": "AllCouponsList()", "page": AllCouponsList(null, true)},
      {"t4": "WinnerCampaignsList()", "page": WinnerCampaignsList()},
      {"t4": "Rules()", "page": Rules()},
    ];
    // preNotiCount(_userData);
    setState(() {});
  }

  checkDomain() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'checkdomain';

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

  gotoPage(index) async {
    var a = 0;
    int tab = 0;
    for (var j = 0; j < _arrayTab.length; j++) {
      if (_arrayTab[j]['pagename'] == _arrayCard[index]["pagename"]) {
        a = 1;
        tab = j;
      }
    }
    if (a == 0) {
      var b = 0;
      int page = 0;
      for (var i = 0; i < _pageList.length; i++) {
        if (_arrayCard[index]["pagename"] == _pageList[i]["t4"]) {
          b = 1;
          page = i;
        }
      }
      if (b == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _pageList[page]['page'],
          ),
        );
      } else {
        _showSnackBar("Not available.");
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TabsPage(
            openTab: tab,
            tabsLists: _arrayTab,
          ),
        ),
      );
    }
  }

  showTime(time) {
    if (time.length > 8) {
      var check1 = time.substring(0, 4);
      if (check1 == "12::" || check1 == "12: ") {
        return time;
      } else {
        var hmin, ampm;
        hmin = time.substring(0, 5);
        ampm = time.substring(time.indexOf(' '), time.length);
        return hmin + ' ' + ampm;
      }
    } else {
      return time;
    }
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
    Widget _buildGridItem(index) {
      return GestureDetector(
        onTap: () {
          gotoPage(index);
        },
        child: Card(
          color: Colors.grey[50],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      height: 25,
                      width: 25,
                      margin: EdgeInsets.only(left: 5),
                      child: Badge(
                        shape: BadgeShape.circle,
                        showBadge: false,
                        position: BadgePosition.topEnd(top: -5, end: -15),
                        padding: EdgeInsets.all(4),
                        toAnimate: false,
                        badgeContent: Container(
                          alignment: Alignment.center,
                          width: 22,
                          child: Text(
                            "2",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        child: Image(
                          image: AssetImage(_arrayCard[index]["url"]),
                          // color: mainColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  children: <Widget>[
                    Container(
                      constraints: BoxConstraints(
                        minWidth: 50,
                        maxWidth: MediaQuery.of(context).size.width * 0.40,
                      ),
                      child: Text(
                        _arrayCard[index]["name"],
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: "Pyidaungsu",
                        ),
                      ),
                    ),
                  ],
                ),
                (_arrayCard[index]["noti"] == "" ||
                        _arrayCard[index]["noti"] == "0")
                    ? Container()
                    : Row(
                        children: [
                          new Container(
                            width: 7.0,
                            height: 7.0,
                            decoration: new BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 3),
                          Expanded(
                            child: Container(
                              child: Text(
                                _arrayCard[index]["noti"] + " new",
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  fontFamily: "Pyidaungsu",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(_userData),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              padding: EdgeInsets.only(right: 10, top: 10, bottom: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300], width: 1),
                ),
                color: Colors.white,
              ),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5, right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                        ),
                        child: (_userData['imagename'] != "" &&
                                _userData['imagename'] != null)
                            ? CachedNetworkImage(
                                imageUrl: _userData['imagename'],
                                placeholder: (context, url) => Image(
                                  image: AssetImage("assets/images/man.png"),
                                  height: 35,
                                  width: 35,
                                  color: Colors.grey,
                                ),
                                height: 35,
                                width: 35,
                                fit: BoxFit.cover,
                              )
                            : Image(
                                image: AssetImage("assets/images/man.png"),
                                height: 35,
                                width: 35,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_userData.length == 0)
                              ? "User Name"
                              : (_userData['username'] == "")
                                  ? _userData['userid']
                                  : _userData['username'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "See your profile",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 7, right: 7, top: 7, bottom: 10),
            child: StaggeredGridView.countBuilder(
              shrinkWrap: true,
              crossAxisCount: 4,
              physics: ScrollPhysics(),
              itemCount: _arrayCard.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildGridItem(index);
              },
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              staggeredTileBuilder: (int index) => new StaggeredTile.fit(2),
            ),
          ),
          GestureDetector(
            onTap: () async {
              setState(() {
                displayLogout(context, false);
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 40,
              alignment: Alignment.center,
              margin: EdgeInsets.only(right: 10, left: 10, bottom: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                "Log out",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(),
            child: GestureDetector(
              onTap: () {
                if (Platform.isAndroid) {
                  try {
                    launch("market://details?id=" + _appconfig.androidAppId);
                  } on PlatformException catch (e) {
                    launch("https://play.google.com/store/apps/details?id=" +
                        _appconfig.androidAppId);
                  } finally {
                    launch("https://play.google.com/store/apps/details?id=" +
                        _appconfig.androidAppId);
                  }
                } else {
                  StoreRedirect.redirect(
                      androidAppId: _appconfig.androidAppId,
                      iOSAppId: _appconfig.iOSAppId);
                }
              },
              child: Text(
                _version,
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontfamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
