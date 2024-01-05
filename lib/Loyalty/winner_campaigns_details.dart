import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/photo_viewer.dart';
// import 'package:loyalty/Widgets/photo_viewer.dart';
import 'package:loyalty/style.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WinnerCampaignDetails extends StatefulWidget {
  final passData;
  WinnerCampaignDetails(this.passData);

  @override
  _WinnerCampaignDetailsState createState() => _WinnerCampaignDetailsState();
}

class _WinnerCampaignDetailsState extends State<WinnerCampaignDetails> {
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
  TextEditingController descriptionController = TextEditingController();

  final dateformat = DateFormat("d MMM y");
  var formatter = NumberFormat('#,##0', "en_US");

  bool _showPrice = true;
  List _grandPrizeList = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _passData = widget.passData;
    for (var i = 0; i < _passData['imagelist'].length; i++) {
      _imageList.add(_passData['imagelist'][i]['imageurl']);
    }
    descriptionController.text = _passData['description'];
    getGrandPrizeList();
    // getcouponsList();
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

  getGrandPrizeList() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetwonpricebycampaign';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));

    var body = jsonEncode({
      "camid": _passData['camid'],
      "domain": domain,
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

    debugPrint("get grand prize body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        //debugPrint("get grand prize result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _grandPrizeList = result['datalist'];
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            getcouponsList();
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

  getcouponsList() async {
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
            // _loading = false;
            //debugPrint(_provider.connectionError);
          });
        });

    //debugPrint("get coupons body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        //debugPrint("get coupons result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _couponsList = result['datalist'];
          // _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            getcouponsList();
          }
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

  showDate(date) {
    DateTime binddate = _provider.bindDateMMM(date);
    var _date = dateformat.format(binddate);
    return _date.replaceAll(",", "");
  }

  _textWonPrice(price, type) {
    bool checkNum = _provider.isNumeric(price);
    if (checkNum && type == "002") {
      return formatter.format(int.parse(price)).toString();
    } else {
      return price;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(milliseconds: 600),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget buildCoupon(i, index) {
      return Container(
        padding: EdgeInsets.only(bottom: 10),
        child: ClipPath(
          clipper: _MyClipper(holeRadius: 20),
          child: Container(
            padding: EdgeInsets.only(left: 25, right: 10, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.all(6),
                  padding: EdgeInsets.only(right: 15),
                  child: Image(
                    image: AssetImage("assets/images/coupon_list.png"),
                    height: 30,
                    width: 30,
                    color: Colors.grey,
                  ),
                ),
                Dash(
                  direction: Axis.vertical,
                  length: 35,
                  dashLength: 5,
                  dashThickness: 3,
                  dashColor: Colors.grey,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 5),
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Winner: ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                                TextSpan(
                                  text: (_grandPrizeList[i]['couponlist'][index]
                                              ['username'] !=
                                          "")
                                      ? _grandPrizeList[i]['couponlist'][index]
                                          ['username']
                                      : _grandPrizeList[i]['couponlist'][index]
                                          ['userid'],
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
                        Container(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Coupon: ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                                TextSpan(
                                  text: _grandPrizeList[i]['couponlist'][index]
                                      ['coupon'],
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

    Widget onLoading() {
      return Column(
        children: [
          Row(
            children: [
              Container(
                alignment: Alignment.center,
                margin:
                    EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
                width: 50,
                height: 50,
                color: Colors.grey[200],
              ),
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        height: 15,
                        width: (MediaQuery.of(context).size.width) / 2,
                        color: Colors.grey[200],
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        height: 15,
                        width: (MediaQuery.of(context).size.width) / 3,
                        color: Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            padding: EdgeInsets.only(top: 10),
            height: 15,
            width: (MediaQuery.of(context).size.width) / 3,
            color: Colors.grey[200],
          ),
        ],
      );
    }

    Widget _buildGrandPrice(i) {
      return Column(
        children: [
          Row(
            children: [
              (_grandPrizeList[i]['imagelist'].length > 0)
                  ? GestureDetector(
                      onTap: () {
                        photoViewer(
                            images: _grandPrizeList[i]['imagelist'],
                            type: "gallery",
                            index: 0);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(
                            right: 10, left: 10, top: 10, bottom: 10),
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
                          imageUrl: _grandPrizeList[i]['imagelist'][0]
                              ['imageurl'],
                          // fit: BoxFit.fitHeight,
                        ),
                      ),
                    )
                  : Container(),
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          _textWonPrice(_grandPrizeList[i]['prize'],
                              _grandPrizeList[i]['instanttype']),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                          ),
                        ),
                      ),
                      Container(
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
                                text: formatter.format(
                                    int.parse(_grandPrizeList[i]['amount'])),
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
          Container(
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            padding: EdgeInsets.only(top: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200],
                  width: 1,
                ),
              ),
            ),
            child: Text(
              "Winning Coupons",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 10, right: 10),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _grandPrizeList[i]['couponlist'].length,
              itemBuilder: (context, index) {
                return buildCoupon(i, index);
              },
            ),
          ),
        ],
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
          _passData['camname'],
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
        // actions: [
        //   Container(
        //     alignment: Alignment.center,
        //     margin: EdgeInsets.only(right: 20, left: 10),
        //     child: Text(
        //       (_passData['status'] == "001")
        //           ? "Open"
        //           : (_passData['status'] == "002")
        //               ? "Closed"
        //               : "Upcoming",
        //       style: TextStyle(
        //         color: (_passData['status'] == "001")
        //             ? Colors.green
        //             : (_passData['status'] == "002")
        //                 ? Colors.red
        //                 : Colors.black54,
        //         fontSize: 14,
        //         fontWeight: FontWeight.w600,
        //         fontFamily: _fontFamily,
        //       ),
        //     ),
        //   ),
        // ],
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
          // Container(
          //   margin: EdgeInsets.only(right: 20, left: 20, top: 5),
          //   alignment: Alignment.center,
          //   child: Text(
          //     _passData['camname'],
          //     style: TextStyle(
          //       color: Colors.black,
          //       fontSize: 20,
          //       fontWeight: FontWeight.w600,
          //       fontFamily: _fontFamily,
          //     ),
          //   ),
          // ),
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
          (_grandPrizeList.length > 0)
              ? Container(
                  margin: EdgeInsets.only(right: 20, left: 20, top: 20),
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Open: " + showDate(_passData['grandpriceopeningdate']),
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                    ),
                  ),
                )
              : Container(),
          (_grandPrizeList.length > 0)
              ? Container(
                  margin:
                      EdgeInsets.only(right: 20, left: 20, top: 5, bottom: 10),
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
                            "Grand Prizes",
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
              ? (_loading)
                  ? Container(
                      margin: EdgeInsets.only(top: 20, bottom: 20),
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: 5,
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
                            child: onLoading(),
                          );
                        },
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: _grandPrizeList.length,
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
