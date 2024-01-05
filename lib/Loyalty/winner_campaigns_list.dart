import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Loyalty/winner_campaigns_details.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WinnerCampaignsList extends StatefulWidget {
  @override
  _WinnerCampaignsListState createState() => _WinnerCampaignsListState();
}

class _WinnerCampaignsListState extends State<WinnerCampaignsList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController();

  Color mainColor = Style().primaryColor;
  final _appconfig = AppConfig();

  String _fontFamily = "Ubuntu";
  final _provider = FunctionProvider();

  bool _loading = true;
  List _campaignsList = [];

  final _apiurl = ApiUrl();
  final dateformat = DateFormat("d MMM y");

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    var _winnercamList =
        _provider.getDecrypt(prefs.getString('winnercampaignslist'));
    if (_winnercamList != null &&
        _winnercamList != "" &&
        _winnercamList != "0") {
      _campaignsList =
          _provider.getJsonDecrypt(prefs.getString('winnercampaignslist'));
      if (_campaignsList.length > 0) {
        _loading = false;
      }
    }
    getCampaignsList();
    setState(() {});
  }

  getCampaignsList() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetgrandpricewoncampaign';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
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

    debugPrint("get winner campaigns body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        //debugPrint("get winner campaigns result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _campaignsList = result['datalist'];
          prefs.setString("winnercampaignslist",
              _provider.setJsonEncrypt(result['datalist']));
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            getCampaignsList();
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

  // photoViewer({images, type, index}) async {
  //   List<String> imagesList = [];
  //   for (var i = 0; i < images.length; i++) {
  //     imagesList.add(images[i]['imageurl']);
  //   }
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //           topLeft: Radius.circular(25.0), topRight: Radius.circular(25.0)),
  //     ),
  //     backgroundColor: Colors.white,
  //     builder: (context) {
  //       return PhotoViewer(images: imagesList, type: type, index: index);
  //     },
  //   );
  // }

  void _onRefresh() async {
    await getCampaignsList();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await getCampaignsList();
    _refreshController.loadComplete();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(milliseconds: 600),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget onLoading() {
      return Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 6,
              spreadRadius: -2,
              offset: Offset(1.5, 1.5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
              width: MediaQuery.of(context).size.width,
              height: (MediaQuery.of(context).size.width) / 3,
              color: Colors.grey[200],
            ),
            Container(
              padding:
                  EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "",
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
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "",
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
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    Widget buildCampaign(index) {
      return GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WinnerCampaignDetails(_campaignsList[index]),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(left: 10, right: 10, bottom: 8),
          // width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 6,
                spreadRadius: -2,
                offset: Offset(1.5, 1.5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              (_campaignsList[index]['imagelist'].length > 0)
                  ? (_campaignsList[index]['imagelist'].length == 1)
                      ? Container(
                          // padding:
                          //     EdgeInsets.only(left: 15, right: 15, top: 15),
                          // alignment: Alignment.center,
                          // margin: EdgeInsets.only(bottom: 15),
                          width: MediaQuery.of(context).size.width,
                          height: (MediaQuery.of(context).size.width) / 2,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                          ),
                          child: CachedNetworkImage(
                            // placeholder: (context, url) => Container(
                            //   child: SpinKitFadingCircle(
                            //     color: Colors.black54,
                            //     size: 24,
                            //   ),
                            // ),
                            // errorWidget: (context, url, error) => Container(
                            //   child: SpinKitFadingCircle(
                            //     color: Colors.black54,
                            //     size: 24,
                            //   ),
                            // ),
                            imageUrl: _campaignsList[index]['imagelist'][0]
                                ['imageurl'],
                            placeholder: (context, url) => Container(),
                            errorWidget: (context, url, error) => Container(),
                            fit: BoxFit.cover,
                            // fit: BoxFit.fitHeight,
                          ),
                        )
                      : Container(
                          margin: EdgeInsets.only(bottom: 15),
                          padding:
                              EdgeInsets.only(left: 15, right: 15, top: 15),
                          child: CarouselSlider.builder(
                            options: CarouselOptions(
                              height:
                                  (MediaQuery.of(context).size.width) * 0.45,
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
                              onPageChanged: (position, reason) {
                                setState(() {
                                  // _current = index;
                                });
                              },
                            ),
                            itemCount:
                                _campaignsList[index]['imagelist'].length,
                            itemBuilder: (context, position, id) {
                              return Container(
                                // padding: EdgeInsets.only(left: 2.5, right: 2.5),
                                // alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width,
                                height: (MediaQuery.of(context).size.width) / 2,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                ),
                                child: CachedNetworkImage(
                                  // placeholder: (context, url) => Container(
                                  //   child: SpinKitFadingCircle(
                                  //     color: Colors.black54,
                                  //     size: 24,
                                  //   ),
                                  // ),
                                  // errorWidget: (context, url, error) =>
                                  //     Container(
                                  //   child: SpinKitFadingCircle(
                                  //     color: Colors.black54,
                                  //     size: 24,
                                  //   ),
                                  // ),
                                  imageUrl: _campaignsList[index]['imagelist']
                                      [position]['imageurl'],
                                  placeholder: (context, url) => Container(),
                                  errorWidget: (context, url, error) =>
                                      Container(),
                                  fit: BoxFit.cover,
                                  // fit: BoxFit.fitHeight,
                                ),
                              );
                            },
                          ),
                        )
                  : Container(),
              Container(
                padding:
                    EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _campaignsList[index]['camname'],
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: (_campaignsList[index]['status'] == "001")
                                    ? "Open"
                                    : (_campaignsList[index]['status'] == "002")
                                        ? "Closed"
                                        : "Upcoming",
                                style: TextStyle(
                                  color:
                                      (_campaignsList[index]['status'] == "001")
                                          ? Colors.green
                                          : (_campaignsList[index]['status'] ==
                                                  "002")
                                              ? Colors.red
                                              : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.top,
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 15,
                                  color: Colors.green,
                                ),
                              ),
                              TextSpan(
                                text: "  " +
                                    showDate(_campaignsList[index]
                                        ['activationdate']),
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
                        RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.top,
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 15,
                                  color: Colors.red,
                                ),
                              ),
                              TextSpan(
                                text: "  " +
                                    showDate(_campaignsList[index]
                                        ['expirationdate']),
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
                      ],
                    ),
                  ],
                ),
              )
            ],
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
          "Winners",
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
        // enablePullUp: (_loading) ? false : true,
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
        enablePullDown: (_loading) ? false : true,
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
                      children: (_campaignsList.length == 0)
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
                              _campaignsList.length,
                              (index) {
                                return buildCampaign(index);
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
