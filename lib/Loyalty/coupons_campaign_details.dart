import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/photo_viewer.dart';
// import 'package:loyalty/Widgets/photo_viewer.dart';
import 'package:loyalty/style.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CouponsCampaignDetails extends StatefulWidget {
  final passData;
  final int index;
  final List couponsList;
  CouponsCampaignDetails(this.passData, this.index, this.couponsList);

  @override
  _CouponsCampaignDetailsState createState() => _CouponsCampaignDetailsState();
}

class _CouponsCampaignDetailsState extends State<CouponsCampaignDetails> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Color mainColor = Style().primaryColor;

  String _fontFamily = "Ubuntu";
  var _passData = {};

  final _apiurl = ApiUrl();
  final _appconfig = AppConfig();

  final _provider = FunctionProvider();
  List _couponsList = [];

  ScrollController _scrollController = ScrollController();
  final CarouselController _controller = CarouselController();

  List<String> _imageList = [];
  String _couponname = "";

  TextEditingController descriptionController = TextEditingController();
  bool _showPrice = true;

  final dateformat = DateFormat("d MMM y");
  var formatter = NumberFormat('#,##0', "en_US");

  List _wonprices = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _couponname = widget.passData['coupon'];
    _passData = widget.passData['campaigndetails'][0];
    _wonprices = widget.passData['wonprice'];

    for (var i = 0; i < _passData['imagelist'].length; i++) {
      _imageList.add(_passData['imagelist'][i]['imageurl']);
    }
    descriptionController.text = _passData['description'];
    _couponsList = widget.couponsList;
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
    _scrollController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  getCouponsList() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetscannedcoupon';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
      "camid": _passData['camid'],
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
            // _showSnackBar(_provider.connectionError);
          });
        });

    //debugPrint("get Coupons body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        //debugPrint("get Coupons result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _couponsList = result['datalist'];
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            getCouponsList();
          }
        } else {
          _loading = false;
          // _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        _loading = false;
        // _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  redeemWonprice(index) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltyrequestredeem';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
      "winnerid": _wonprices[index]['primarykey'],
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

    //debugPrint("get redeem body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        //debugPrint("get redeem result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _wonprices[index]['redeemed'] = true;
          for (var i = 0;
              i < _couponsList[widget.index]['wonprice'].length;
              i++) {
            if (_couponsList[widget.index]['wonprice'][i]['primarykey'] ==
                _wonprices[index]['primarykey']) {
              _couponsList[widget.index]['wonprice'][i]['redeemed'] = true;
            }
          }
          prefs.setString(
              "couponslist", _provider.setJsonEncrypt(_couponsList));
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            redeemWonprice(index);
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

  showQRcode(winnerid) async {
    List wonprizeList = [];
    var servertime;

    setState(() {
      loadingQRcode(context);
    });

    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'getservertime';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));
    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));

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
          var couponData = {
            "coupon": _couponname,
            "winnerid": winnerid,
            "date": servertime
          };
          createQRcode(couponData);

          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            showQRcode(winnerid);
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

  photoViewer({images, type, index}) async {
    List<String> imagesList = [];
    for (var i = 0; i < images.length; i++) {
      imagesList.add(images[i]['imageurl']);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0), topRight: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return PhotoViewer(images: imagesList, type: type, index: index);
      },
    );
  }

  _textWonPrice(price, type) {
    bool checkNum = _provider.isNumeric(price);
    if (checkNum && type == "002") {
      return formatter.format(int.parse(price)).toString();
    } else {
      return price;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(milliseconds: 600),
    ));
  }

  displayLogout(index) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 10, right: 10, top: 20),
          elevation: 24.0,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    "Redeem following item?",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.all(0),
                  title: Container(
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
                          child: Text(
                            _wonprices[index]['price'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
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
                  Navigator.pop(context);
                  _loading = true;
                  redeemWonprice(index);
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

  @override
  Widget build(BuildContext context) {
    Widget _buildGrandPrice(i) {
      return Stack(children: [
        Container(
          // color: Colors.blue[50],
          child: Row(
            children: [
              (_wonprices[i]['imagelist'].length > 0)
                  ? GestureDetector(
                      onTap: () {
                        photoViewer(
                            images: _wonprices[i]['imagelist'],
                            type: "gallery",
                            index: 0);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(
                            right: 5, left: 5, top: 10, bottom: 10),
                        padding: EdgeInsets.only(left: 5, right: 5),
                        width: 100,
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                            child: SpinKitFadingCircle(
                              color: Colors.black54,
                              size: 24,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            child: SpinKitFadingCircle(
                              color: Colors.black54,
                              size: 24,
                            ),
                          ),
                          // width: 55,
                          // height: 55,
                          imageUrl: _wonprices[i]['imagelist'][0]['imageurl'],
                          // fit: BoxFit.fitHeight,
                        ),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(
                          right: 5, left: 10, top: 10, bottom: 10),
                      padding: EdgeInsets.only(left: 5, right: 5),
                      width: 100,
                      child: Image(
                        image: AssetImage(
                            "assets/images/cp_detail_placeholder.png"),
                        height: 55,
                        width: 55,
                        color: Colors.grey,
                      ),
                    ),
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 5, bottom: 5),
                              child: RichText(
                                maxLines: 2,
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
                                          _wonprices[i]['prize'],
                                          _wonprices[i]['instanttype']),
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
                            ),
                            (_wonprices[i]['type'] != "001")
                                ? Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Amount: ",
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: _fontFamily,
                                            ),
                                          ),
                                          TextSpan(
                                            text: formatter.format(int.parse(
                                                _wonprices[i]['amount'])),
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
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      (_wonprices[i]['redeemed'])
                          ? Container()
                          : GestureDetector(
                              onTap: () async {
                                if (!_loading) {
                                  showQRcode(_wonprices[i]['primarykey']);
                                  // displayLogout(i);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(
                                        left: 15, right: 15, top: 5, bottom: 5),
                                    decoration: BoxDecoration(
                                      color: mainColor,
                                      borderRadius: BorderRadius.circular(50),
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
        if (_wonprices[i]['type'] == "002")
          Positioned(
            top: 0,
            right: 5,
            child: Container(
              alignment: Alignment.center,
              child: Image(
                width: 20,
                height: 20,
                image: AssetImage("assets/images/winner.png"),
              ),
            ),
          )
      ]);
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
          (_passData['camname'] != null) ? _passData['camname'] : "",
          overflow: TextOverflow.ellipsis,
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
            },
          )
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
      body: ListView(
        children: [
          (_passData['imagelist'].length > 0)
              ? (_passData['imagelist'].length == 1)
                  ? GestureDetector(
                      onTap: () {
                        photoViewer(
                            images: _passData['imagelist'],
                            type: "gallery",
                            index: 0);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(
                            right: 20, left: 20, top: 10, bottom: 10),
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                            child: SpinKitFadingCircle(
                              color: Colors.black54,
                              size: 24,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            child: SpinKitFadingCircle(
                              color: Colors.black54,
                              size: 24,
                            ),
                          ),
                          imageUrl: _passData['imagelist'][0]['imageurl'],
                          // fit: BoxFit.fitHeight,
                        ),
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.only(
                          right: 20, left: 20, top: 10, bottom: 10),
                      child: CarouselSlider.builder(
                        carouselController: _controller,
                        options: CarouselOptions(
                          height: (MediaQuery.of(context).size.width) * 0.5,
                          autoPlay: false,
                          viewportFraction: 0.9,
                          aspectRatio: 0,
                          initialPage: 0,
                          enableInfiniteScroll: true,
                          reverse: false,
                          autoPlayInterval: Duration(seconds: 3),
                          autoPlayAnimationDuration:
                              Duration(milliseconds: 800),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          scrollDirection: Axis.horizontal,
                          onPageChanged: (index, reason) {
                            setState(() {
                              // _current = index;
                            });
                          },
                        ),
                        itemCount: _passData['imagelist'].length,
                        itemBuilder: (context, index, id) {
                          return GestureDetector(
                            onTap: () {
                              photoViewer(
                                  images: _passData['imagelist'],
                                  type: "gallery",
                                  index: index);
                            },
                            child: Container(
                              padding: EdgeInsets.only(left: 5),
                              alignment: Alignment.center,
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: SpinKitFadingCircle(
                                    color: Colors.black54,
                                    size: 24,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  child: SpinKitFadingCircle(
                                    color: Colors.black54,
                                    size: 24,
                                  ),
                                ),
                                imageUrl: _passData['imagelist'][index]
                                    ['imageurl'],
                                // fit: BoxFit.fitHeight,
                              ),
                            ),
                          );
                        },
                      ),
                    )
              : Container(),

          Container(
            margin: EdgeInsets.only(right: 20, left: 20, top: 5),
            alignment: Alignment.center,
            child: Text(
              _couponname,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 20, left: 20, top: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.top,
                        child: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                      TextSpan(
                        text: "  " + showDate(_passData['activationdate']),
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: _fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.top,
                        child: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                      TextSpan(
                        text: "  " + showDate(_passData['expirationdate']),
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: _fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          (_passData['description'] != "")
              ? Container(
                  margin: EdgeInsets.only(right: 20, left: 20, top: 15),
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    // borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    readOnly: true,
                    controller: descriptionController,
                    minLines: 1,
                    maxLines: null,
                    autofocus: false,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                )
              : Container(),
          // (_passData['grandpricelist'].length > 0)
          //     ? Container(
          //         margin: EdgeInsets.only(right: 20, left: 20, top: 20),
          //         alignment: Alignment.centerRight,
          //         child: Text(
          //           "Open: " + showDate(_passData['grandpriceopeningdate']),
          //           style: TextStyle(
          //             color: Colors.blue[400],
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //             fontFamily: _fontFamily,
          //           ),
          //         ),
          //       )
          //     : Container(),
          // Container(
          //   alignment: Alignment.centerRight,
          //   margin: EdgeInsets.only(right: 20, left: 20, top: 15, bottom: 0),
          //   child: RichText(
          //     overflow: TextOverflow.ellipsis,
          //     text: TextSpan(
          //       children: [
          //         TextSpan(
          //           text: "Coupon: ",
          //           style: TextStyle(
          //             color: Colors.blue[400],
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //             fontFamily: _fontFamily,
          //           ),
          //         ),
          //         TextSpan(
          //           text: _couponname,
          //           style: TextStyle(
          //             color: Colors.blue[400],
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //             fontFamily: _fontFamily,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          (_wonprices.length > 0)
              ? Container(
                  margin:
                      EdgeInsets.only(right: 20, left: 20, top: 15, bottom: 10),
                  decoration: BoxDecoration(
                    color: mainColor,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 7, bottom: 7),
                          child: Text(
                            "Winning Prizes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPrice = !_showPrice;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 7, bottom: 7),
                          child: _showPrice
                              ? Icon(
                                  Icons.remove,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(),
          (_showPrice)
              ? Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: _wonprices.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(
                            left: 20, right: 20, top: 5, bottom: 5),
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
                        child: _buildGrandPrice(index),
                      );
                    },
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
