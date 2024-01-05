import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Loyalty/noti_campaign_details.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/globle.dart' as globals;
import 'package:loyalty/style.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class NotificationPage extends StatefulWidget {
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController();

  SlidableController slidableController = SlidableController();

  Color mainColor = Style().primaryColor;
  final _appconfig = AppConfig();

  String _fontFamily = "Ubuntu";
  final _provider = FunctionProvider();

  bool _loading = true;
  final _apiurl = ApiUrl();

  List _notiList = [];
  String _end = "";

  @override
  void initState() {
    super.initState();
    getData();
    setState(() {});
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    var _noti = _provider.getDecrypt(prefs.getString('notilist'));
    if (_noti != null && _noti != "" && _noti != "0") {
      _notiList = _provider.getJsonDecrypt(prefs.getString('notilist'));
      if (_notiList.length > 0) {
        _loading = false;
      }
    }
    getNotificationList();
    setState(() {});
  }

  getNotificationList() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetnotilist';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token,
      "end": _end
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

    debugPrint("get notification list body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get notification list result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          if (_end == "") {
            _notiList = result['list'];
            prefs.setString(
                "notilist", _provider.setJsonEncrypt(result['list']));
          } else {
            for (var i = 0; i < result['list'].length; i++) {
              final check = _notiList
                  .where((element) =>
                      element["notiid"] == result['list'][i]["notiid"])
                  .isNotEmpty;
              if (check == false) {
                _notiList.add(result['list'][i]);
              }
            }
          }
          _end = result['end'];
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          getNotificationList();
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

  getNotiDetail(noti) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltygetnotidetail';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token,
      "notiid": noti['notiid']
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

    debugPrint("get notification detail body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("get notification detail result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _loading = false;
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          getNotiDetail(noti);
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

  deleteNotification(index, noti) async {
    final prefs = await SharedPreferences.getInstance();
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));
    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    final url = _apiurl.iamurl + 'loyaltydeletenoti';

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": domainid,
      "appid": _appconfig.appid,
      "atoken": token,
      "notiid": noti['notiid']
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
            _notiList.insert(index, noti);
          });
        });

    debugPrint("delete notification body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("delete notification result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          // getNotificationList();
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          deleteNotification(index, noti);
          setState(() {});
        } else {
          _loading = false;
          _showSnackBar(result['status']);
          _notiList.insert(index, noti);
          setState(() {});
        }
      } else {
        _loading = false;
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        _notiList.insert(index, noti);
        setState(() {});
      }
    }
  }

  checkDate(date) {
    var year, month, day, hour, min, amorpm;
    year = date.substring(0, 4);
    month = date.substring(4, 6);
    day = date.substring(6, 8);
    hour = date.substring(8, 10);
    min = date.substring(10, 12);
    var currentyear = DateFormat("yyyy").format(DateTime.now());
    DateTime msgDate =
        DateTime(int.parse(year), int.parse(month), int.parse(day));
    DateTime today = DateTime.now();
    int totDays = today.difference(msgDate).inDays;
    if (totDays == 0) {
      hour = int.parse(hour);
      if (hour > 12) {
        hour = hour - 12;
        if (hour == 0) {
          amorpm = "AM";
        } else {
          amorpm = "PM";
        }
      } else {
        if (hour == 12) {
          amorpm = "PM";
        } else {
          amorpm = "AM";
        }
      }

      return hour.toString() + ':' + min + ' ' + amorpm;
    } else if (totDays == 1) {
      return "Yesterday";
    } else {
      if (currentyear == year) {
        return DateFormat("MMM d").format(msgDate);
      } else {
        return DateFormat("MMM d y").format(msgDate);
      }
    }
  }

  void _onRefresh() async {
    _end = "";
    await getNotificationList();
    _refreshController.refreshCompleted();
    setState(() {});
  }

  void _onLoading() async {
    if (_end != "") {
      await getNotificationList();
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

  showAlertDetail(notidata) {
    return showDialog(
      context: context,
      builder: (_context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        // title: GestureDetector(
        //   onTap: () {
        //     Navigator.pop(context);
        //   },
        //   child: Container(
        //     padding: EdgeInsets.all(10),
        //     alignment: FractionalOffset.topRight,
        //     child: Icon(
        //       Icons.clear,
        //     ),
        //   ),
        // ),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Container(
                height: 50,
                width: 50,
                margin: EdgeInsets.only(bottom: 15),
                child: Image(
                  image: AssetImage("assets/images/notification.png"),
                ),
              ),
              Text(
                notidata['title'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 5),
              Text(
                notidata['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10, left: 20, right: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        primary: mainColor,
                      ),
                      child: Text(
                        "Ok",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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

  showWonDetail(notidata) {
    return showDialog(
      context: context,
      builder: (_context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        // title: GestureDetector(
        //   onTap: () {
        //     Navigator.pop(context);
        //   },
        //   child: Container(
        //     padding: EdgeInsets.all(10),
        //     alignment: FractionalOffset.topRight,
        //     child: Icon(
        //       Icons.clear,
        //     ),
        //   ),
        // ),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Container(
                height: 150,
                width: 150,
                margin: EdgeInsets.only(bottom: 10),
                child: Image(
                  image: AssetImage("assets/images/won_detail.png"),
                ),
              ),
              Text(
                notidata['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10, left: 20, right: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        primary: mainColor,
                      ),
                      child: Text(
                        "Ok",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    Widget _buildLoading() {
      return ListTile(
        contentPadding: EdgeInsets.all(0),
        onTap: () {},
        title: Container(
          padding: EdgeInsets.only(top: 10, bottom: 10, right: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.only(left: 5, right: 5, top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 15,
                        width: (MediaQuery.of(context).size.width) / 3,
                        color: Colors.grey[200],
                      ),
                      SizedBox(height: 3),
                      Container(
                        height: 9,
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
      );
    }

    Widget _buildSentMsgNoti(index) {
      return ListTile(
        contentPadding: EdgeInsets.all(0),
        onTap: () {
          _notiList[index]['seen'] = true;
          getNotiDetail(_notiList[index]);
          setState(() {            
            // print("CLICKK NOTI>>${globals.notiCounts}");
            if (globals.notiresult.value != "0") {
              globals.notiresult.value =
                  (int.parse(globals.notiresult.value) - 1).toString();
              // print("NCCC>> ${globals.notiCounts}");
            }
          });

          if (_notiList[index]['notitype'] == "001") {
            showAlertDetail(_notiList[index]);
          } else {
            // showWonDetail(_notiList[index]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotiCampaignDetails(_notiList[index]),
              ),
            );
          }
          setState(() {});
        },
        title: Container(
          padding: EdgeInsets.only(top: 5, bottom: 5, right: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.only(left: 5, right: 5, top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_notiList[index]['seen']) ? Colors.white : mainColor,
                ),
              ),
              (_notiList[index]['notitype'] == "001")
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.blue[50],
                            width: 1.5,
                          ),
                        ),
                        child: (_notiList[index]['domainimage'] != "" &&
                                _notiList[index]['domainimage'] != null)
                            ? CachedNetworkImage(
                                imageUrl: _notiList[index]['domainimage'],
                                placeholder: (context, url) => Image(
                                  image:
                                      AssetImage("assets/images/bell_noti.png"),
                                  height: 50,
                                  width: 50,
                                  // color: mainColor,
                                ),
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              )
                            : Image(
                                image:
                                    AssetImage("assets/images/bell_noti.png"),
                                height: 50,
                                width: 50,
                                // color: mainColor,
                              ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.blue[50],
                            width: 1.5,
                          ),
                        ),
                        child: Image(
                          image: AssetImage("assets/images/win_noti.png"),
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ),
              SizedBox(width: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _notiList[index]['title']
                                      .replaceAll('\n', " "),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _notiList[index]['description']
                                      .replaceAll('\n', " "),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10, top: 3),
                      child: Text(
                        checkDate(_notiList[index]['sort']),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          // fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SmartRefresher(
        enablePullUp: (_loading) ? false : true,
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
        child: ListView(
          children: <Widget>[
            Container(
              // margin: EdgeInsets.only(top: 10),
              child: Column(
                children: (_loading)
                    ? List.generate(
                        10,
                        (index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200],
                                  width: 2,
                                ),
                              ),
                            ),
                            child: _buildLoading(),
                          );
                        },
                      )
                    : (_notiList.length == 0)
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
                            _notiList.length,
                            (index) {
                              return Slidable(
                                enabled: false,
                                controller: slidableController,
                                actionPane: SlidableScrollActionPane(),
                                actionExtentRatio: 0.17,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _notiList[index]['seen']
                                        ? Colors.white
                                        : Colors.blue[50],
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _notiList[index]['seen']
                                            ? Colors.grey[200]
                                            : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: _buildSentMsgNoti(index),
                                ),
                                secondaryActions: <Widget>[
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _notiList[index]['seen']
                                          ? Colors.white
                                          : Colors.blue[50],
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _notiList[index]['seen']
                                              ? Colors.grey[200]
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: IconSlideAction(
                                      iconWidget: Container(
                                        padding: EdgeInsets.all(8.0),
                                        child: new Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      color: Colors.red,
                                      onTap: () {
                                        setState(() {
                                          if (!_loading) {
                                            var noti = _notiList[index];
                                            _notiList.remove(_notiList[index]);
                                            deleteNotification(index, noti);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                ],
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
