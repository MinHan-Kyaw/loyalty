import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Loyalty/coupons_campaign_details.dart';
import 'package:loyalty/Loyalty/redeem_dialog.dart';
import 'package:loyalty/Widgets/clip_shadow_path.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dash/flutter_dash.dart';

class AllCouponsList extends StatefulWidget {
  final globalScaffoldKey;
  final bool tabPage;
  AllCouponsList(this.globalScaffoldKey, this.tabPage);
  @override
  _AllCouponsListState createState() => _AllCouponsListState();
}

class _AllCouponsListState extends State<AllCouponsList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController();

  ScrollController _scrollController = ScrollController();

  Color mainColor = Style().primaryColor;
  String _fontFamily = "Ubuntu";

  final _appconfig = AppConfig();
  final _provider = FunctionProvider();

  bool _loading = false;
  bool _firstloading = true;

  List _couponsList = [];
  var _loyaltykey;

  final _apiurl = ApiUrl();
  final dateformat = DateFormat("d MMM y");

  String _selectFilter = "All";
  var formatter = NumberFormat('#,##0', "en_US");

  String _domaindesc = "";
  var _userData = {};

  @override
  void initState() {
    super.initState();
    _loyaltykey = "";
    getData();
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
    _scrollController.dispose();
    super.dispose();
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    if (_userData['domaindesc'] != null) {
      _domaindesc = _userData['domaindesc'];
    }
    var _couponList = _provider.getDecrypt(prefs.getString('couponslist'));
    if (_couponList != null && _couponList != "" && _couponList != "0") {
      _couponsList = _provider.getJsonDecrypt(prefs.getString('couponslist'));
      if (_couponsList.length > 0) {
        _firstloading = false;
      }
    }

    var filterCode = _provider.getDecrypt(prefs.getString("coupon_filtercode"));
    if (filterCode == null || filterCode == "" || filterCode == "0") {
      filterCode = "0";
    }

    filterCodeToName(filterCode);
    getCouponsList(filterCode);
    setState(() {});
  }

  getCouponsList(String filterCode) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetscannedcoupon';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
      "key": _loyaltykey,
      "camid": "",
      "filter": filterCode,
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
            _firstloading = false;
            _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("get Coupons body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get Coupons result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          if (_loyaltykey == "") {
            _couponsList = result['datalist'];
            prefs.setString(
                "couponslist", _provider.setJsonEncrypt(result['datalist']));
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

          prefs.setString(
              "coupon_filtercode", _provider.setEncrypt(filterCode));
          _loyaltykey = result['LastEvaluatedKey'];
          _loading = false;
          _firstloading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            getCouponsList(filterCode);
          }
        } else {
          _loading = false;
          _firstloading = false;
          _showSnackBar("Sever Error");
          setState(() {});
        }
      } else {
        _loading = false;
        _firstloading = false;
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  redeemWonprice(index, primarykey) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltyrequestredeem';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
      "winnerid": primarykey,
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
            _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("get redeem body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get redeem result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          for (var i = 0; i < _couponsList[index]['wonprice'].length; i++) {
            if (_couponsList[index]['wonprice'][i]['primarykey'] ==
                primarykey) {
              _couponsList[index]['wonprice'][i]['redeemed'] = true;
            }
          }
          _loading = false;
          nametoFilter();
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            redeemWonprice(index, primarykey);
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

  createQRcode(couponData) {
    final plainText = json.encode(couponData);
    final key = encrypt.Key.fromUtf8('thisismysupersecretkeypleasehide');
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    displayQRcode(context, encrypted.base64);
  }

  showDate(date) {
    DateTime binddate = _provider.bindDateMMM(date);
    var _date = dateformat.format(binddate);
    return _date.replaceAll(",", "");
  }

  checkRedeem(wonprice) {
    var a = 0;
    for (var i = 0; i < wonprice.length; i++) {
      if (!wonprice[i]['redeemed']) {
        a = 1;
      }
    }
    if (a == 0) {
      return true;
    } else {
      return false;
    }
  }

  // var _qrloading = false;

  showQRcode(index, wonprizes) async {
    List wonprizeList = [];
    var servertime;

    setState(() {
      loadingQRcode(context);
    });
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'getservertime';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "appid": _appconfig.appid,
      "domainid": domainid,
      "atoken": token
    });
    debugPrint("check servertime body >>>>" + body.toString());

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            Navigator.of(context).pop();
            // _qrloading = false;
            // controller.resumeCamera();
            //debugPrint(error);
            // _showSnackBar(_provider.connectionError);
          });
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("check servertime result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          setState(() {
            // _qrloading = false;
            Navigator.of(context).pop();
          });
          servertime = result['datetime'];

          for (var i = 0; i < wonprizes.length; i++) {
            if (!wonprizes[i]['redeemed']) {
              wonprizeList.add(wonprizes[i]);
            }
          }

          if (wonprizeList.length > 1) {
            var primarykey =
                await displayRedeem(context, _couponsList[index]['wonprice']);
            if (primarykey != null) {
              var couponData = {
                "coupon": _couponsList[index]['coupon'],
                "winnerid": primarykey,
                "date": servertime
              };
              createQRcode(couponData);
            }
          } else {
            var couponData = {
              "coupon": _couponsList[index]['coupon'],
              "winnerid": wonprizeList[0]['primarykey'],
              "date": servertime
            };
            createQRcode(couponData);
          }
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            showQRcode(index, wonprizes);
          }
        } else if (result['returncode'] == "200") {
          setState(() {
            Navigator.of(context).pop();
            // _qrloading = false;
          });
          _showSnackBar("${result['message']}");
          setState(() {});
        } else {
          setState(() {
            Navigator.of(context).pop();
            // _qrloading = false;
          });
          _showSnackBar("Sever Error");

          setState(() {});
        }
      } else {
        setState(() {
          // _qrloading = false;
          Navigator.of(context).pop();
        });

        _showSnackBar("${_provider.showErrMessage(response.statusCode)}");

        setState(() {});
      }
    }
  }

  filterCodeToName(filterCode) {
    String name = "all";
    switch (filterCode) {
      case "0":
        name = "All";
        break;
      case "1":
        name = "Instant";
        break;
      case "2":
        name = "Grand Prizes";
        break;
      case "3":
        name = "Other";
        break;
      case "4":
        name = "Redeemed";
        break;
      default:
        name = "All";
    }

    setState(() {
      _selectFilter = name;
    });
  }

  nametoFilter() {
    String filterCode = "0";
    switch (_selectFilter) {
      case "All":
        filterCode = "0";
        break;
      case "Instant":
        filterCode = "1";
        break;
      case "Grand Prizes":
        filterCode = "2";
        break;
      case "Other":
        filterCode = "3";
        break;
      case "Redeemed":
        filterCode = "4";
        break;
      default:
        filterCode = "0";
    }

    getCouponsList(filterCode);
  }

  returnNametoFilter() {
    String filterCode = "0";
    switch (_selectFilter) {
      case "All":
        filterCode = "0";
        break;
      case "Instant":
        filterCode = "1";
        break;
      case "Grand Prizes":
        filterCode = "2";
        break;
      case "Other":
        filterCode = "3";
        break;
      case "Redeemed":
        filterCode = "4";
        break;
      default:
        filterCode = "0";
    }
    return filterCode;
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

  void _onRefresh() async {
    _loyaltykey = "";
    await getCouponsList(returnNametoFilter());
    _refreshController.refreshCompleted();
    setState(() {});
  }

  void _onLoading() async {
    if (_loyaltykey != "") {
      await getCouponsList(returnNametoFilter());
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

  displayRedeem(context, wonprice) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return RedeemDialog(wonprice);
      },
    );
  }

  displayQRcode(context, qrText) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          elevation: 24.0,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 2 / 3,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height / 5,
                    maxHeight: MediaQuery.of(context).size.height / 3,
                  ),
                  child: QrImage(
                    data: qrText,
                    version: QrVersions.auto,
                    size: MediaQuery.of(context).size.width * 2 / 3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  loadingQRcode(context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          elevation: 24.0,
          content: Container(
              width: MediaQuery.of(context).size.width * 2 / 3,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height / 5,
                maxHeight: MediaQuery.of(context).size.height / 3,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: SpinKitFadingCircle(
                    color: Colors.black54,
                    size: 24,
                  ),
                ),
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget _customPupupMenuItem(String value) {
      return PopupMenuItem(
        child: Row(
          children: <Widget>[
            _selectFilter == value
                ? Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: mainColor,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                    ),
                  ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectFilter == value ? mainColor : Colors.black,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 5),
          ],
        ),
        value: value,
      );
    }

    Widget _buildFilterMenuPopup() {
      return PopupMenuButton<String>(
        icon: Icon(Icons.filter_list),
        // offset: Offset(0, 10),
        onSelected: (value) async {
          setState(() {
            _selectFilter = value;
            _loading = true;
            nametoFilter();
          });
        },
        onCanceled: () {},
        itemBuilder: (context) => [
          _customPupupMenuItem("All"),
          _customPupupMenuItem("Grand Prizes"),
          _customPupupMenuItem("Instant"),
          _customPupupMenuItem("Redeemed"),
          _customPupupMenuItem("Other"),
        ],
      );
    }

    Widget _buildChip(String label) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectFilter = label;
            _loyaltykey = "";
            _loading = true;
            nametoFilter();
          });
        },
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            padding: EdgeInsets.all(8.0),
            width: 100,
            height: 45,
            decoration: BoxDecoration(
              color: _selectFilter == label ? mainColor : Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(24.0)),
              border: Border.all(color: mainColor),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: _selectFilter == label ? Colors.white : mainColor,
                ),
              ),
            )),
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
            padding: EdgeInsets.only(left: 30, right: 20, top: 20, bottom: 20),
            decoration: BoxDecoration(
              color: checkRedeem(_couponsList[index]['wonprice'])
                  ? Colors.white
                  : Colors.blue[50],
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
                                                ['prize'],
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
                          child: Row(
                            children: [
                              Expanded(
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
                                        text: showDate(
                                            _couponsList[index]['date']),
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
                              checkRedeem(_couponsList[index]['wonprice'])
                                  ? Container()
                                  : GestureDetector(
                                      onTap: () async {
                                        if (!_loading) {
                                          showQRcode(index,
                                              _couponsList[index]['wonprice']);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(
                                            left: 15,
                                            right: 15,
                                            top: 5,
                                            bottom: 5),
                                        decoration: BoxDecoration(
                                          color: mainColor,
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Text(
                                          "Redeem",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: _fontFamily,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
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
      appBar: (widget.tabPage)
          ? AppBar(
              elevation: 0,
              iconTheme: IconThemeData(color: mainColor),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              centerTitle: true,
              // leading: GestureDetector(
              //   onTap: () {
              //     setState(() {
              //       widget.globalScaffoldKey.currentState.openDrawer();
              //     });
              //   },
              //   child: Icon(Icons.menu),
              // ),
              title: Text(
                _domaindesc,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  fontSize: 20,
                ),
              ),
              actions: [
                _buildFilterMenuPopup(),
              ],
              bottom: (_loading)
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(5),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(0),
                      child: Container(),
                    ),
            )
          : AppBar(
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
              actions: [
                _buildFilterMenuPopup(),
              ],
              bottom: (_loading)
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(5),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(0),
                      child: Container(),
                    ),
            ),
      body: SmartRefresher(
        enablePullUp: (_loading || _firstloading) ? false : true,
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
        enablePullDown: (_loading || _firstloading) ? false : true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: (_firstloading)
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
                    padding: EdgeInsets.only(top: 10),
                    child: (_couponsList.length == 0)
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
                        : ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            itemCount: _couponsList.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () async {
                                  if (_couponsList[index]['campaigndetails']
                                          .length >
                                      0) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CouponsCampaignDetails(
                                                _couponsList[index],
                                                index,
                                                _couponsList),
                                      ),
                                    );
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    var _couponList = _provider.getDecrypt(
                                        prefs.getString('couponslist'));
                                    if (_couponList != null &&
                                        _couponList != "" &&
                                        _couponList != "0") {
                                      _couponsList = _provider.getJsonDecrypt(
                                          prefs.getString('couponslist'));
                                    }
                                    nametoFilter();
                                  }
                                  setState(() {});
                                },
                                child: Stack(
                                  children: [
                                    buildCoupon(index),
                                    (_couponsList[index]['wonprice'].length > 0)
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
                                                                horizontal: 10,
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
                                                        // letterSpacing: 1,
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
