import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Loyalty/coupons_list.dart';
import 'package:loyalty/functionProvider.dart';
// import 'package:loyalty/Widgets/photo_viewer.dart';
import 'package:loyalty/photo_viewer.dart';
import 'package:loyalty/style.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CampaignDetails extends StatefulWidget {
  final passData;
  CampaignDetails(this.passData);

  @override
  _CampaignDetailsState createState() => _CampaignDetailsState();
}

class _CampaignDetailsState extends State<CampaignDetails> {
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

  @override
  void initState() {
    super.initState();
    _passData = widget.passData;
    for (var i = 0; i < _passData['imagelist'].length; i++) {
      _imageList.add(_passData['imagelist'][i]['imageurl']);
    }
    descriptionController.text = _passData['description'];
    getcouponsList();
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

  @override
  Widget build(BuildContext context) {
    Widget _buildGrandPrice(i) {
      return Row(
        children: [
          (_passData['grandpricelist'][i]['grandpriceimagelist'].length > 0)
              ? GestureDetector(
                  onTap: () {
                    photoViewer(
                        images: _passData['grandpricelist'][i]
                            ['grandpriceimagelist'],
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
                      imageUrl: _passData['grandpricelist'][i]
                          ['grandpriceimagelist'][0]['imageurl'],
                      // fit: BoxFit.fitHeight,
                    ),
                  ),
                )
              : Container(),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: Text(
                      _textWonPrice(_passData['grandpricelist'][i]['prize'],
                          _passData['grandpricelist'][i]['instanttype']),
                      overflow: TextOverflow.ellipsis,
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
                            text: formatter.format(int.parse(
                                _passData['grandpricelist'][i]['amt'])),
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
                            text: "Qty: ",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                            ),
                          ),
                          TextSpan(
                            text: _passData['grandpricelist'][i]['qty'],
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
          (_passData['grandpricelist'].length > 0)
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
          (_passData['grandpricelist'].length > 0)
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
              ? Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: _passData['grandpricelist'].length,
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
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(right: 20, left: 20, bottom: 10),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CouponsList(_passData['camid'], _couponsList),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(top: 7.0, bottom: 7.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_num_outlined),
                SizedBox(width: 10),
                Text(
                  "My coupons",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
