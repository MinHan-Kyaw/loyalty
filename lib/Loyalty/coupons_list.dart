import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Widgets/clip_shadow_path.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CouponsList extends StatefulWidget {
  final String camid;
  final List couponsList;
  CouponsList(this.camid, this.couponsList);
  @override
  _CouponsListState createState() => _CouponsListState();
}

class _CouponsListState extends State<CouponsList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController();
  GlobalKey _stackKey = GlobalKey();

  Color mainColor = Style().primaryColor;
  String _fontFamily = "Ubuntu";

  final _appconfig = AppConfig();
  final _provider = FunctionProvider();

  bool _loading = false;
  List _couponsList = [];

  final _apiurl = ApiUrl();
  final dateformat = DateFormat("d MMM y");

  var formatter = NumberFormat('#,##0', "en_US");
  var _loyaltykey;

  @override
  void initState() {
    super.initState();
    _couponsList = widget.couponsList;
    _loyaltykey = "";
    if (_couponsList.length == 0) {
      _loading = true;
      getCouponsList();
    }
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
    _refreshController.dispose();
    super.dispose();
  }

  getCouponsList() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetscannedcoupon';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
      "key": _loyaltykey,
      "camid": widget.camid,
      "userid": _userData['userid'],
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
            //debugPrint(_provider.connectionError);
          });
        });

    //debugPrint("get Coupons body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        //debugPrint("get Coupons result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          if (_loyaltykey == "") {
            _couponsList = result['datalist'];
          } else {
            for (var i = 0; i < result['datalist'].length; i++) {
              final check = _couponsList
                  .where((element) =>
                      element["coupon"] == result['datalist'][i]["coupon"])
                  .isNotEmpty;
              if (check == false) {
                _couponsList.add(result['datalist'][i]);
              }
            }
          }
          _loyaltykey = result['LastEvaluatedKey'];
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            getCouponsList();
          }
        } else {
          _loading = false;
          _showSnackBar("Sever Error");
          setState(() {});
        }
      } else {
        _loading = false;
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  showDate(date) {
    DateTime binddate = _provider.bindDateMMM(date);
    var _date = dateformat.format(binddate);
    return _date.replaceAll(",", "");
  }

  void _onRefresh() async {
    _loyaltykey = "";
    await getCouponsList();
    _refreshController.refreshCompleted();
    setState(() {});
  }

  void _onLoading() async {
    if (_loyaltykey != "") {
      await getCouponsList();
    }
    _refreshController.loadComplete();
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(milliseconds: 600),
    ));
  }

  _textWonPrice(price, type) {
    bool checkNum = _provider.isNumeric(price);
    if (checkNum && type == "002") {
      return formatter.format(int.parse(price)).toString();
    } else {
      return price;
    }
  }

  _buildGrandPrizeWidget(List wonprice) {
    var checkGrandPrize =
        wonprice.where((element) => element["type"] == "002").isNotEmpty;

    if (checkGrandPrize) {
      return Positioned(
        top: 2,
        left: 55,
        child: Container(
          alignment: Alignment.center,
          child: Image(
            width: 25,
            height: 25,
            image: AssetImage("assets/images/winner.png"),
          ),
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    Widget onLoading() {
      return Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: ClipShadowPath(
          clipper: _MyClipper(holeRadius: 20),
          shadow: Shadow(
            color: Colors.grey,
            blurRadius: 6,
            offset: Offset(1.5, 1.5),
          ),
          child: Container(
            padding: EdgeInsets.only(left: 30, right: 20, top: 15, bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(6),
                  padding: EdgeInsets.only(right: 20),
                  child: Image(
                    image: AssetImage("assets/images/coupon_list.png"),
                    height: 50,
                    width: 50,
                    color: Colors.grey,
                  ),
                ),
                Dash(
                  direction: Axis.vertical,
                  length: 65,
                  dashLength: 5,
                  dashThickness: 3,
                  dashColor: Colors.grey,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 15,
                          width: (MediaQuery.of(context).size.width) / 2,
                          color: Colors.grey[200],
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 5, bottom: 5),
                          height: 15,
                          width: (MediaQuery.of(context).size.width) / 3,
                          color: Colors.grey[200],
                        ),
                        Container(
                          height: 15,
                          width: (MediaQuery.of(context).size.width) / 2,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildCoupon(index) {
      return Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: ClipShadowPath(
          clipper: _MyClipper(holeRadius: 20),
          shadow: Shadow(
            color: Colors.grey,
            blurRadius: 6,
            offset: Offset(1.5, 1.5),
          ),
          child: Container(
            padding: EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 20),
            decoration: BoxDecoration(
              color: (_couponsList[index]['wonprice'].length > 0)
                  ? Colors.blue[50]
                  : Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(6),
                  padding: EdgeInsets.only(right: 20),
                  child: Image(
                    image: AssetImage("assets/images/coupon_list.png"),
                    height: 50,
                    width: 50,
                    color: Colors.grey,
                  ),
                ),
                Dash(
                  direction: Axis.vertical,
                  length: 56,
                  dashLength: 5,
                  dashThickness: 3,
                  dashColor: Colors.grey,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(
                            _couponsList[index]['coupon'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        (_couponsList[index]['wonprice'].length > 0)
                            ? Container(
                                margin: EdgeInsets.only(top: 5, bottom: 5),
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Won: ",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: _fontFamily,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _textWonPrice(
                                            _couponsList[index]['wonprice'][0]
                                                ['price'],
                                            _couponsList[index]['wonprice'][0]
                                                ['instanttype']),
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: _fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                margin: EdgeInsets.only(top: 5, bottom: 5),
                                child: Text(
                                  "Thank You",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                              ),
                        Container(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Scan: ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                                TextSpan(
                                  text: showDate(_couponsList[index]['date']),
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Coupons",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            fontSize: 20,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          )
        ],
        // bottom: (_loading)
        //     ? PreferredSize(
        //         preferredSize: const Size.fromHeight(5),
        //         child: LinearProgressIndicator(
        //           backgroundColor: Colors.black12,
        //           valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        //         ),
        //       )
        //     : PreferredSize(
        //         preferredSize: const Size.fromHeight(0),
        //         child: Container(),
        //       ),
      ),
      body: SmartRefresher(
        enablePullUp: true,
        header: CustomHeader(
          builder: (context, mode) {
            return Container(
              height: 60.0,
              child: Container(
                height: 20.0,
                width: 20.0,
                child: CupertinoTheme(
                  data: CupertinoTheme.of(context)
                      .copyWith(brightness: Brightness.light),
                  child: CupertinoActivityIndicator(),
                ),
              ),
            );
          },
        ),
        footer: CustomFooter(
          loadStyle: LoadStyle.ShowAlways,
          builder: (context, mode) {
            if (mode == LoadStatus.loading) {
              return Container(
                height: 60.0,
                child: Container(
                  height: 20.0,
                  width: 20.0,
                  child: CupertinoTheme(
                    data: CupertinoTheme.of(context)
                        .copyWith(brightness: Brightness.light),
                    child: CupertinoActivityIndicator(),
                  ),
                ),
              );
            } else
              return Container();
          },
        ),
        enablePullDown: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: (_loading)
            ? Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: SpinKitFadingCircle(
                    color: Colors.black54,
                    size: 24,
                  ),
                ),
              )
            : ListView(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Column(
                      children: (_couponsList.length == 0)
                          ? <Widget>[
                              Center(
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
                            ]
                          : List.generate(
                              _couponsList.length,
                              (index) {
                                return GestureDetector(
                                  onTap: () {},
                                  child: Stack(
                                    children: [
                                      buildCoupon(index),
                                      (_couponsList[index]['wonprice'].length >
                                              0)
                                          ? Positioned(
                                              top: 5,
                                              left: 10,
                                              child: Stack(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10),
                                                    child: ClipPath(
                                                      clipper: GiftBanner(),
                                                      child: Container(
                                                        width: 30,
                                                        height: 18,
                                                        color: Colors.green,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 1),
                                                          child: Text(""),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 18,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 2,
                                                              top: 1,
                                                              bottom: 1),
                                                      child: Text(
                                                        "won",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 1,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(),
                                      _buildGrandPrizeWidget(
                                          _couponsList[index]['wonprice'])
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  SizedBox(height: 40)
                ],
              ),
      ),
    );
  }
}

class _MyClipper extends CustomClipper<Path> {
  final double holeRadius;

  _MyClipper({@required this.holeRadius});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(
          0.0, size.height - (size.height / 2 - holeRadius / 2) - holeRadius)
      ..arcToPoint(
        Offset(0, size.height - (size.height / 2 - holeRadius / 2)),
        clockwise: true,
        radius: Radius.circular(1),
      )
      ..lineTo(0.0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - (size.height / 2 - holeRadius / 2))
      ..arcToPoint(
        Offset(size.width,
            size.height - (size.height / 2 - holeRadius / 2) - holeRadius),
        clockwise: true,
        radius: Radius.circular(1),
      );

    path.lineTo(size.width, 0.0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class GiftBanner extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(size.width, 0);

    path.lineTo(0.0, size.height);

    path.lineTo(size.width, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper old) {
    return old != this;
  }
}
