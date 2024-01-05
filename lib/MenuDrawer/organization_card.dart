import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:gzx_dropdown_menu/gzx_dropdown_menu.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrganizationCard extends StatefulWidget {
  String titlename;
  OrganizationCard(this.titlename);
  @override
  _OrganizationCardState createState() => _OrganizationCardState();
}

class _OrganizationCardState extends State<OrganizationCard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController _scrollController = ScrollController();

  Color mainColor = Style().primaryColor;
  String _fontFamily = "Ubuntu";

  List _orgList = [];
  final _provider = FunctionProvider();

  var _userData = {};
  bool _loading = true;

  String _titlename = "";
  final _appconfig = AppConfig();

  int _current = 0;
  final CarouselController _controller = CarouselController();

  List<String> _arrayStatus = ["Digital ID", "Rewards"];
  List _allorgList = [];

  final _apiurl = ApiUrl();

  GlobalKey _stackKey = GlobalKey();

  GZXDropdownMenuController _dropdownMenuController =
      GZXDropdownMenuController();

  @override
  void initState() {
    super.initState();
    _titlename = widget.titlename;
    getData();
    setState(() {});
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    _allorgList = _provider.getJsonDecrypt(prefs.getString('organizationslist')) ?? [];
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    for (var i = 0; i < _allorgList.length; i++) {
      if (_titlename == "Rewards") {
        if (_allorgList[i]["orgtype"] == "003") {
          _orgList.add(_allorgList[i]);
        }
      } else {
        if (_allorgList[i]["orgtype"] != "003") {
          _orgList.add(_allorgList[i]);
        }
      }
    }
    if (_orgList.length > 0) {
      _loading = false;
    }
    _getUserOrganizations();
    setState(() {});
  }

  _getUserOrganizations() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/getorg';

    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var _domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id")) ?? "";

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": _domainid,
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
            _loading = false;
            debugPrint(_provider.connectionError);
          });
        });

    debugPrint("org body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("organization result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString("organizationslist",_provider.setJsonEncrypt(result['list']));
          prefs.setString("domain_admin",_provider.setEncrypt(result['domainadmin']));
          prefs.setString("domain_admin_name",_provider.setEncrypt(result['domaindesc']));
          prefs.setString("domain_url",_provider.setEncrypt( result['domainurl']));
          prefs.setString("domainlist", _provider.setJsonEncrypt(result['domainlist']));
          _allorgList = result['list'];
          getOrgCard();
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          _getUserOrganizations();
        } else {
          _loading = false;
          _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        _loading = false;
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getOrgCard() {
    var orgList = [];
    for (var i = 0; i < _allorgList.length; i++) {
      if (_titlename == "Rewards") {
        if (_allorgList[i]["orgtype"] == "003") {
          orgList.add(_allorgList[i]);
        }
      } else {
        if (_allorgList[i]["orgtype"] != "003") {
          orgList.add(_allorgList[i]);
        }
      }
    }
    _orgList = orgList;
    debugPrint(_orgList.toString());
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(seconds: 3),
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

    Widget _buildListItemCard(index) {
      return Stack(
        children: [
          Container(
            margin: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3,
                        color: mainColor,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: (_orgList[index]['orgimageurl'] != "" &&
                                _orgList[index]['orgimageurl'] != null)
                            ? CachedNetworkImage(
                                imageUrl: _orgList[index]['orgimageurl'],
                                placeholder: (context, url) => Image(
                                  image: AssetImage(
                                      "assets/images/profile_orgadmin.png"),
                                  height: 40,
                                  width: 40,
                                ),
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              )
                            : Image(
                                image: AssetImage(
                                    "assets/images/profile_orgadmin.png"),
                                height: 40,
                                width: 40,
                              ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10, left: 10),
                        constraints: BoxConstraints(
                            minWidth: 10,
                            maxWidth: (MediaQuery.of(context).size.width / 2)),
                        child: Text(
                          _orgList[index]["name"],
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 3,
                          color: Colors.white,
                        ),
                        right: BorderSide(
                          width: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(
                              width: 2,
                              color: mainColor,
                            ),
                            color: Colors.grey[300],
                          ),
                          child: (_userData['imagename'] != "" &&
                                  _userData['imagename'] != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(3.0),
                                  child: CachedNetworkImage(
                                    imageUrl: _userData['imagename'],
                                    placeholder: (context, url) => Image(
                                      image:
                                          AssetImage("assets/images/man.png"),
                                      height: 85,
                                      width: 85,
                                      color: Colors.grey,
                                    ),
                                    height: 85,
                                    width: 85,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image(
                                  image: AssetImage("assets/images/man.png"),
                                  height: 85,
                                  width: 85,
                                  color: Colors.grey,
                                ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                child: Text(
                                  (_userData['username'] == "")
                                      ? _userData['userid']
                                      : _userData['username'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Container(
                                child: Text(
                                  _orgList[index]["type"],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  "ID: " + _userData['userid'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          alignment: Alignment.bottomCenter,
                          child: QrImage(
                            data: _userData['userid'],
                            size: 110,
                            foregroundColor: Colors.black,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildListMemberCard(index) {
      return RotatedBox(
        quarterTurns: 3,
        child: Stack(
          children: [
            Container(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: (_orgList[index]['orgimageurl'] != "" &&
                                  _orgList[index]['orgimageurl'] != null)
                              ? CachedNetworkImage(
                                  imageUrl: _orgList[index]['orgimageurl'],
                                  placeholder: (context, url) => Image(
                                    image: AssetImage(
                                        "assets/images/profile_orgadmin.png"),
                                    height: 40,
                                    width: 40,
                                  ),
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                )
                              : Image(
                                  image: AssetImage(
                                      "assets/images/profile_orgadmin.png"),
                                  height: 40,
                                  width: 40,
                                ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.only(top: 10, bottom: 10, left: 10),
                          constraints: BoxConstraints(
                            minWidth: 10,
                            maxWidth: (MediaQuery.of(context).size.width * 1.5),
                          ),
                          child: Text(
                            _orgList[index]["name"],
                            style: TextStyle(
                              color: mainColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      decoration: BoxDecoration(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    (_userData['username'] == "")
                                        ? _userData['userid']
                                        : _userData['username'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    _userData['userid'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: QrImage(
                              data: _userData['userid'],
                              size: 100,
                              foregroundColor: Colors.black,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    margin: EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: mainColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildListItemCardTwo(index) {
      return Stack(
        children: [
          ClipPath(
            clipper: CurveClipper(),
            child: Container(
              color: mainColor,
              height: 150.0,
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: (_orgList[index]['orgimageurl'] != "" &&
                                _orgList[index]['orgimageurl'] != null)
                            ? CachedNetworkImage(
                                imageUrl: _orgList[index]['orgimageurl'],
                                placeholder: (context, url) => Image(
                                  image: AssetImage(
                                      "assets/images/profile_orgadmin.png"),
                                  height: 40,
                                  width: 40,
                                  color: Colors.white,
                                ),
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              )
                            : Image(
                                image: AssetImage(
                                    "assets/images/profile_orgadmin.png"),
                                height: 40,
                                width: 40,
                                color: Colors.white,
                              ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10, left: 10),
                        constraints: BoxConstraints(
                            minWidth: 10,
                            maxWidth: (MediaQuery.of(context).size.width / 2)),
                        child: Text(
                          _orgList[index]["name"],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 3,
                          color: mainColor,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              width: 5,
                              color: Colors.white,
                            ),
                            color: Colors.grey[300],
                          ),
                          child: (_userData['imagename'] != "" &&
                                  _userData['imagename'] != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: CachedNetworkImage(
                                    imageUrl: _userData['imagename'],
                                    placeholder: (context, url) => Image(
                                      image:
                                          AssetImage("assets/images/man.png"),
                                      height: 85,
                                      width: 85,
                                      color: Colors.grey,
                                    ),
                                    height: 85,
                                    width: 85,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image(
                                  image: AssetImage("assets/images/man.png"),
                                  height: 85,
                                  width: 85,
                                  color: Colors.grey,
                                ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                child: Text(
                                  (_userData['username'] == "")
                                      ? _userData['userid']
                                      : _userData['username'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Container(
                                child: Text(
                                  _orgList[index]["type"],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  "ID: " + _userData['userid'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          alignment: Alignment.bottomCenter,
                          child: QrImage(
                            data: _userData['userid'],
                            size: 110,
                            foregroundColor: Colors.black,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildListMemberCardTwo(index) {
      return RotatedBox(
        quarterTurns: 3,
        child: Stack(
          children: [
            ClipPath(
              clipper: CurveClipper(),
              child: Container(
                color: mainColor,
                height: 150.0,
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: (_orgList[index]['orgimageurl'] != "" &&
                                  _orgList[index]['orgimageurl'] != null)
                              ? CachedNetworkImage(
                                  imageUrl: _orgList[index]['orgimageurl'],
                                  placeholder: (context, url) => Image(
                                    image: AssetImage(
                                        "assets/images/profile_orgadmin.png"),
                                    height: 40,
                                    width: 40,
                                    color: Colors.white,
                                  ),
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                )
                              : Image(
                                  image: AssetImage(
                                      "assets/images/profile_orgadmin.png"),
                                  height: 40,
                                  width: 40,
                                  color: Colors.white,
                                ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.only(top: 10, bottom: 10, left: 10),
                          constraints: BoxConstraints(
                            minWidth: 10,
                            maxWidth: (MediaQuery.of(context).size.width * 1.5),
                          ),
                          child: Text(
                            _orgList[index]["name"],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    (_userData['username'] == "")
                                        ? _userData['userid']
                                        : _userData['username'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    _userData['userid'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 10),
                            alignment: Alignment.bottomRight,
                            child: QrImage(
                              data: _userData['userid'],
                              size: 100,
                              foregroundColor: Colors.black,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                        ],
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

    Widget _buildListItemCardThree(index) {
      return Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: ClipPath(
              clipper: WaveClipperOpacity(),
              child: Container(
                color: mainColor,
                height: 200,
              ),
            ),
          ),
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              color: mainColor,
              height: 180.0,
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: (_orgList[index]['orgimageurl'] != "" &&
                                _orgList[index]['orgimageurl'] != null)
                            ? CachedNetworkImage(
                                imageUrl: _orgList[index]['orgimageurl'],
                                placeholder: (context, url) => Image(
                                  image: AssetImage(
                                      "assets/images/profile_orgadmin.png"),
                                  height: 40,
                                  width: 40,
                                  color: Colors.white,
                                ),
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              )
                            : Image(
                                image: AssetImage(
                                    "assets/images/profile_orgadmin.png"),
                                height: 40,
                                width: 40,
                                color: Colors.white,
                              ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10, left: 10),
                        constraints: BoxConstraints(
                            minWidth: 10,
                            maxWidth: (MediaQuery.of(context).size.width / 2)),
                        child: Text(
                          _orgList[index]["name"],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                        // border: Border(
                        //   bottom: BorderSide(
                        //     width: 3,
                        //     color: mainColor,
                        //   ),
                        // ),
                        ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            // border: Border.all(
                            //   width: 5,
                            //   color: Colors.white,
                            // ),
                            color: Colors.grey[300],
                          ),
                          child: (_userData['imagename'] != "" &&
                                  _userData['imagename'] != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: CachedNetworkImage(
                                    imageUrl: _userData['imagename'],
                                    placeholder: (context, url) => Image(
                                      image:
                                          AssetImage("assets/images/man.png"),
                                      height: 85,
                                      width: 85,
                                      color: Colors.grey,
                                    ),
                                    height: 85,
                                    width: 85,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image(
                                  image: AssetImage("assets/images/man.png"),
                                  height: 85,
                                  width: 85,
                                  color: Colors.grey,
                                ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                child: Text(
                                  (_userData['username'] == "")
                                      ? _userData['userid']
                                      : _userData['username'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Container(
                                child: Text(
                                  _orgList[index]["type"],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  "ID: " + _userData['userid'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          alignment: Alignment.bottomCenter,
                          child: QrImage(
                            data: _userData['userid'],
                            size: 110,
                            foregroundColor: Colors.black,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildListMemberCardThree(index) {
      return RotatedBox(
        quarterTurns: 3,
        child: Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: ClipPath(
                clipper: WaveClipperOpacity(),
                child: Container(
                  color: mainColor,
                  height: 180,
                ),
              ),
            ),
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: mainColor,
                height: 160.0,
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: (_orgList[index]['orgimageurl'] != "" &&
                                  _orgList[index]['orgimageurl'] != null)
                              ? CachedNetworkImage(
                                  imageUrl: _orgList[index]['orgimageurl'],
                                  placeholder: (context, url) => Image(
                                    image: AssetImage(
                                        "assets/images/profile_orgadmin.png"),
                                    height: 40,
                                    width: 40,
                                    color: Colors.white,
                                  ),
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                )
                              : Image(
                                  image: AssetImage(
                                      "assets/images/profile_orgadmin.png"),
                                  height: 40,
                                  width: 40,
                                  color: Colors.white,
                                ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.only(top: 10, bottom: 10, left: 10),
                          constraints: BoxConstraints(
                            minWidth: 10,
                            maxWidth: (MediaQuery.of(context).size.width * 1.5),
                          ),
                          child: Text(
                            _orgList[index]["name"],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    (_userData['username'] == "")
                                        ? _userData['userid']
                                        : _userData['username'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    _userData['userid'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 10),
                            alignment: Alignment.bottomRight,
                            child: QrImage(
                              data: _userData['userid'],
                              size: 100,
                              foregroundColor: Colors.black,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                        ],
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        child: AppBar(
          elevation: 0,
        ),
        preferredSize: Size.fromHeight(0),
      ),
      body: Stack(key: _stackKey, children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 8.0, left: 50, right: 20.0),
              child: GZXDropDownHeader(
                items: [
                  GZXDropDownHeaderItem(_titlename),
                ],
                stackKey: _stackKey,
                height: 56.0,
                controller: _dropdownMenuController,
                iconColor: Colors.black,
                borderWidth: 0,
                borderColor: Colors.white,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  fontSize: 20,
                ),
                dropDownStyle: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  fontSize: 20,
                ),
              ),
            ),
            (_loading)
                ? LinearProgressIndicator(
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  )
                : Container(),
            (_orgList.length == 0)
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 10,
                      ),
                      child: Text(
                        "Empty",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey),
                      ),
                    ),
                  )
                : Container(),
            (_orgList.length > 0)
                ? Expanded(
                    child: CarouselSlider.builder(
                      carouselController: _controller,
                      options: CarouselOptions(
                        height: (MediaQuery.of(context).size.width) * 1.3,
                        autoPlay: false,
                        aspectRatio: 0,
                        initialPage: 0,
                        enableInfiniteScroll: false,
                        reverse: false,
                        autoPlayInterval: Duration(seconds: 3),
                        autoPlayAnimationDuration: Duration(milliseconds: 800),
                        autoPlayCurve: Curves.fastOutSlowIn,
                        scrollDirection: Axis.horizontal,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        },
                      ),
                      itemCount: _orgList.length,
                      itemBuilder: (context, index, id) {
                        return Container(
                          height: (MediaQuery.of(context).size.width) * 1,
                          margin: EdgeInsets.only(
                              left: 5, right: 5, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            // color: Color(0xffdde9f2),
                            color: (_orgList[index]['layout'] == "001")
                                ? Color(0xffdde9f2)
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 6,
                                spreadRadius: 2,
                                offset: Offset(1.5, 1.5),
                              )
                            ],
                          ),
                          child: (_titlename == "Rewards")
                              ? (_orgList[index]['layout'] == "001")
                                  ? _buildListMemberCard(index)
                                  : (_orgList[index]['layout'] == "002")
                                      ?_buildListMemberCardTwo(index)
                                      : _buildListMemberCardThree(index)
                              : (_orgList[index]['layout'] == "001")
                                  ? _buildListItemCard(index)
                                  : (_orgList[index]['layout'] == "002")
                                      ? _buildListItemCardTwo(index)
                                      : _buildListItemCardThree(index),
                        );
                      },
                    ),
                  )
                : Container(),
            (_orgList.length > 0)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _orgList.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _controller.animateToPage(entry.key),
                        child: Container(
                          width: 12.0,
                          height: 12.0,
                          margin: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _current == entry.key
                                ? Colors.grey
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Container(),
          ],
        ),
        GZXDropDownMenu(
          controller: _dropdownMenuController,
          animationMilliseconds: 150,
          menus: [
            GZXDropdownMenuBuilder(
                dropDownHeight: calculatedropDownHeight(),
                dropDownWidget: buildDropDownListWidget(_arrayStatus)),
          ],
        ),
        Positioned(
          top: 8,
          left: 5,
          child: BackButton(color: mainColor),
        ),
      ]),
    );
  }

  calculatedropDownHeight() {
    final tmpHeight = 45 * _arrayStatus.length + .0;
    final halfScreenHeight = MediaQuery.of(context).size.height / 2;
    if ((tmpHeight) > halfScreenHeight) {
      return halfScreenHeight + .0;
    } else {
      return tmpHeight;
    }
  }

  buildDropDownListWidget(items) {
    return ListView.separated(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) =>
          Divider(height: 1.0),
      itemBuilder: (BuildContext context, int index) {
        return dropdowngestureDetector(items, index, context);
      },
    );
  }

  Material dropdowngestureDetector(items, int index, BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () {
          setState(() {
            _dropdownMenuController.hide();
            _titlename = items[index];
            getOrgCard();
          });
        },
        child: Container(
          height: 45,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
              ),
              Expanded(
                child: Text(
                  "${items[index]}",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
              SizedBox(width: 10),
              _titlename == items[index]
                  ? Icon(
                      Icons.radio_button_checked,
                      color: Colors.blue,
                      size: 15,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      size: 15,
                    ),
              SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    int curveHeight = 40;
    Offset controlPoint = Offset(size.width / 2, size.height + curveHeight);
    Offset endPoint = Offset(size.width, size.height - curveHeight);

    Path path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
          controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy)
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Offset firstControlPoint = Offset(size.width / 4, size.height);
    Offset firstEndPoint = Offset(size.width / 2.25, size.height - 30);

    Offset secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 65);
    Offset secondEndPoint = Offset(size.width, size.height - 40);

    Path path = Path()
      ..lineTo(0, size.height - 20)
      ..quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
          firstEndPoint.dx, firstEndPoint.dy)
      ..quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
          secondEndPoint.dx, secondEndPoint.dy)
      ..lineTo(size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class WaveClipperOpacity extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Offset firstControlPoint = Offset(size.width / 4, size.height - 20);
    Offset firstEndPoint = Offset(size.width / 2.25, size.height - 50);

    Offset secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 85);
    Offset secondEndPoint = Offset(size.width, size.height - 40);

    Path path = Path()
      ..lineTo(0, size.height - 20)
      ..quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
          firstEndPoint.dx, firstEndPoint.dy)
      ..quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
          secondEndPoint.dx, secondEndPoint.dy)
      ..lineTo(size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
