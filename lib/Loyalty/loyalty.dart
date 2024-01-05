import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Loyalty/all_coupons_list.dart';
import 'package:loyalty/Loyalty/campaigns_list.dart';
import 'package:loyalty/Loyalty/scan_loyalty.dart';
import 'package:loyalty/Loyalty/winner_campaigns_list.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart';

class Loyalty extends StatefulWidget {
  @override
  _LoyaltyState createState() => _LoyaltyState();
}

class _LoyaltyState extends State<Loyalty> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String _fontFamily = "Ubuntu";
  Color mainColor = Style().primaryColor;
  final _provider = FunctionProvider();

  List _arrayCard = [];

  String _titlename = "MIT";
  List<String> _arrayStatus = ["MIT"];

  List _defaultCard = [
    {
      "syskey": "001",
      "pagename": "ScanLoyalty()",
      "namemm": "QR Scan",
      "order": "1",
      "url": "assets/images/qr_scan.png",
      "name": "QR Scan",
      "domain": "demo",
      "subtitle": "",
      "noti": "",
    },
    {
      "syskey": "002",
      "pagename": "CampaignsList()",
      "namemm": "Campaigns",
      "order": "2",
      "url": "assets/images/campaigns.png",
      "name": "Campaigns",
      "domain": "demo",
      "subtitle": "",
      "noti": "",
    },
    {
      "syskey": "003",
      "pagename": "AllCouponsList()",
      "namemm": "Coupons",
      "order": "3",
      "url": "assets/images/coupon.png",
      "name": "Coupons",
      "domain": "demo",
      "subtitle": "",
      "noti": "",
    },
    {
      "syskey": "004",
      "pagename": "WinnerCampaignsList()",
      "namemm": "Winner",
      "order": "4",
      "url": "assets/images/winner_cup.png",
      "name": "Winner",
      "domain": "demo",
      "subtitle": "",
      "noti": "",
    },
  ];

  List _pageList = [
    {"t4": "ScanLoyalty()", "page": ScanLoyalty()},
    {"t4": "CampaignsList()", "page": CampaignsList(false)},
    {"t4": "AllCouponsList()", "page": AllCouponsList(null, false)},
    {"t4": "WinnerCampaignsList()", "page": WinnerCampaignsList()},
  ];

  @override
  void initState() {
    super.initState();
    _arrayCard = _defaultCard;
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  gotoPage(aIndex) async {
    var a = 0;
    int page = 0;
    for (var i = 0; i < _pageList.length; i++) {
      if (_arrayCard[aIndex]['pagename'].toString() ==
          _pageList[i]['t4'].toString()) {
        a = 1;
        page = i;
      }
    }
    if (a == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _pageList[page]['page'],
        ),
      );
    } else {
      _showSnackBar("Not available.");
    }
  }

  gotoHome() async {
    final prefs = await SharedPreferences.getInstance();
    var _arrayTab = _provider.getJsonDecrypt(prefs.getString('menulist'));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TabsPage(
          openTab: _arrayTab.length - 1,
          tabsLists: _arrayTab,
        ),
      ),
    );
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(milliseconds: 600),
    ));
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem> menuItemStatusList = _arrayStatus
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      val,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    _titlename == val
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                            size: 15,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            size: 15,
                          ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Loyalty",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            fontSize: 20,
          ),
        ),
        // title: Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     DropdownButton<String>(
        //       hint: Text(
        //         _titlename,
        //         style: TextStyle(
        //           color: Colors.black,
        //           fontWeight: FontWeight.w600,
        //           fontFamily: _fontFamily,
        //           fontSize: 20,
        //         ),
        //       ),
        //       elevation: 1,
        //       style: TextStyle(
        //         color: Colors.black,
        //         fontSize: 16,
        //       ),
        //       underline: SizedBox(),
        //       onChanged: (newValue) async {
        //         _titlename = newValue;
        //         setState(() {});
        //       },
        //       items: menuItemStatusList,
        //     ),
        //   ],
        // ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          gotoHome();
          return false;
        },
        child: Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: GridView.count(
            primary: false,
            crossAxisCount: 3,
            children: List.generate(
              _arrayCard.length,
              (index) {
                return Container(
                  width: MediaQuery.of(context).size.width / 3,
                  height: MediaQuery.of(context).size.width / 3,
                  child: GestureDetector(
                    onTap: () {
                      gotoPage(index);
                    },
                    child: Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 6,
                            spreadRadius: -2,
                            offset: Offset(1.5, 1.5),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 10),
                          // Container(
                          //   width: 27,
                          //   height: 27,
                          //   child: Image(
                          //     image: AssetImage(_arrayCard[index]["t3"]),
                          //     color: _iconColor,
                          //   ),
                          // ),
                          Container(
                            height: 27,
                            width: 27,
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
                                  "1",
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
                          SizedBox(height: 5),
                          Text(
                            _arrayCard[index]["name"],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
