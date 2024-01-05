import 'dart:convert';
import 'dart:io';

import 'package:google_api_availability/google_api_availability.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Verify/otpautofill.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sms_autofill/sms_autofill.dart';

class AddOTPPage extends StatefulWidget {
  String phone;
  AddOTPPage(this.phone);
  @override
  _AddOTPPageState createState() => _AddOTPPageState();
}

class _AddOTPPageState extends State<AddOTPPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _appconfig = AppConfig();

  TextEditingController otptextController = new TextEditingController();
  TextEditingController nametextController = new TextEditingController();

  final _provider = FunctionProvider();
  String _deviceid = '';

  bool _loading = false;
  String _session = "";

  String _fontFamily = "Ubuntu";
  List _arrayTab = [];

  bool _recent = false;
  String _type = "";

  List _userList = [];
  Color mainColor = Style().primaryColor;

  bool verified = false;
  String _token = "";

  String signature;
  final _apiurl = ApiUrl();

  @override
  void initState() {
    super.initState();
    initDeviceId();
    getAllAccount();
    getAppSignature();
    setState(() {});
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  initDeviceId() async {
    _deviceid = await FlutterUdid.udid;
    setState(() {});
  }

  getAppSignature() async {
    if (!Platform.isIOS) {
      signature =
          await SmsAutoFill().getAppSignature.timeout(Duration(seconds: 3));
      GooglePlayServicesAvailability availability = await GoogleApiAvailability
          .instance
          .checkGooglePlayServicesAvailability();
      debugPrint("aaaaa:" + availability.toString());
      if (availability.toString().split('.').last != "serviceInvalid") {
        await SmsAutoFill().listenForCode;
      }
    }
    checkRegister();
    debugPrint("app signature>>>>>>> $signature");
  }

  getAllAccount() async {
    final prefs = await SharedPreferences.getInstance();
    _userList = _provider.getJsonDecrypt(prefs.getString('userlist'));
    setState(() {});
  }

  checkRegister() async {
    final url = _apiurl.iamurl + 'signin';

    var body = jsonEncode({
      "userid": widget.phone,
      "password": "",
      "uuid": _deviceid,
      "recaptcha": "",
      "appid": _appconfig.appid,
      "signature": signature
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            _recent = false;
            _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("signin body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin result >>>>" + result.toString());
        _recent = false;
        _session = result['session'];
        _type = result['type'];
        nametextController.text = result['username'];
        setState(() {});
      } else {
        _recent = false;
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  goVerify() {
    setState(() {
      _loading = true;
      otpverify();
    });
  }

  otpverify() async {
    final url = _apiurl.iamurl + 'verifyuser';

    var body = jsonEncode({
      "userid": widget.phone,
      "username": nametextController.text,
      "uuid": _deviceid,
      "otp": otptextController.text,
      "session": _session,
      "appid": _appconfig.appid
    });

    debugPrint("verifyotp body >>>>" + body);

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          _loading = false;
          _showSnackBar(_provider.connectionError);
          setState(() {});
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("verifyotp result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          getDomain(result['atoken']);
          verified = true;
          _token = result['atoken'];
        } else {
          _loading = false;
          if (result['returncode'] == "200") {
            _showSnackBar("Missing Field!");
          } else if (result['returncode'] == "202") {
            _showSnackBar("Invalid OTP!");
          } else if (result['returncode'] == "210") {
            _showSnackBar("Invalid Request!");
          } else if (result['returncode'] == "220") {
            _showSnackBar("Server Error!");
          } else if (result['returncode'] == "230") {
            _showSnackBar("Unknown Error!");
          }
        }
        setState(() {});
      } else {
        _loading = false;
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getDomain(token) async {
    final url = _apiurl.iamurl + 'getdomain';

    var body = jsonEncode(
        {"appid": _appconfig.appid, "userid": widget.phone, "atoken": token});

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

    debugPrint("domain body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("domain result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          var domain = result['domains'][0]['shortcode'];
          var domainid = result['domains'][0]['domainid'];
          if (result['domains'].length > 1) {
            domain = result['domains'][1]['shortcode'];
            domainid = result['domains'][1]['domainid'];
          }

          checkUser(token, result['domains'], domain, domainid);
        } else {
          _loading = false;
          _showSnackBar(result['message']);
          setState(() {});
        }
      } else {
        _loading = false;
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  checkUser(token, domains, domain, domainid) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/signin';
    var fcmtoken = _provider.getDecrypt(prefs.getString("fcm_Token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "username": nametextController.text,
      "userid": widget.phone,
      "imagename": "",
      "domain": domain,
      "domainid": domainid,
      "domaintype": 2,
      "atoken": token,
      "appid": _appconfig.appid,
      "uuid": _deviceid,
      "fcmtoken": fcmtoken,
      "n1": _appconfig.appName,
      "version": _appconfig.version1
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

    debugPrint("signin user body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin user result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _userList.add({
            "syskey": result['syskey'],
            "username": result['username'],
            "userid": result['userid'],
            "imagename": result['imagename'],
            "domains": domains,
            "atoken": token
          });

          for (var i = 0; i < domains.length; i++) {
            if (domains[i]["shortcode"] == result['domain']) {
              domain = domains[i]['shortcode'];
              domainid = domains[i]['domainid'];
            }
          }

          getMenu(result, token, result['domain'], _userList, domainid);
        } else {
          _loading = false;
          _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        _loading = false;
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getMenu(userData, token, domain, userList, domainid) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'getpolicy';

    var body = jsonEncode({
      "userid": widget.phone,
      "appid": _appconfig.appid,
      "domain": domain,
      "domainid": domainid,
      "type": "0", // 0 for menu
      "atoken": token,
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            debugPrint(_provider.connectionError);
          });
        });

    debugPrint("menu body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("menu result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString("menulist", _provider.setJsonEncrypt(result['json']));
          _arrayTab = result['json'];
          gotoHome(userData, token, domain, _userList, domainid);
        } else if (result['returncode'] == "200") {
          // _loading = false;
          // _provider.sessionExpired(context);
          setState(() {});
        } else {
          _loading = false;
          _showSnackBar(result['returncode'] + " " + result['message']);
        }
      } else {
        _loading = false;
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  gotoHome(userData, token, domain, userList, domainid) async {
    final prefs = await SharedPreferences.getInstance();
    imageCache.clear();
    prefs.setString("kun_verify", _provider.setEncrypt("true"));
    prefs.setString("kunyek_domain",_provider.setEncrypt(domain));
    prefs.setString("kunyek_domain_id",_provider.setEncrypt(domainid));
    prefs.setString('userdata', _provider.setJsonEncrypt(userData));
    prefs.setString('userlist', _provider.setJsonEncrypt(userList));
    prefs.setString('app_token', _provider.setEncrypt(token));
    prefs.setString('menutype', _provider.setEncrypt('all'));
    prefs.setString('showmore', _provider.setEncrypt("0"));
    prefs.setString('campaignslist', _provider.setEncrypt("0"));
    prefs.setString('winnercampaignslist', _provider.setEncrypt("0"));
    prefs.setString('couponslist', _provider.setEncrypt("0"));
    prefs.setString("coupon_filtercode", _provider.setEncrypt("0"));
    prefs.setString("notilist", _provider.setEncrypt("0"));
    prefs.setString('showmore_profile', _provider.setEncrypt("0"));
    prefs.setString("domain_data", _provider.setEncrypt("0"));
    prefs.setString("organizationslist", _provider.setEncrypt("0"));

    _loading = false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TabsPage(
          openTab: 0,
          tabsLists: _arrayTab,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  displayName(context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(0.0),
            ),
          ),
          titlePadding: EdgeInsets.only(left: 0.0, right: 0.0),
          contentPadding: EdgeInsets.all(20.0),
          title: Container(
            color: mainColor,
            padding: EdgeInsets.only(top: 15.0, bottom: 15.0, left: 20.0),
            child: Text(
              "Name (Optional)",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Align(
                //   alignment: Alignment.bottomLeft,
                //   child: Text(
                //     "Name (Optional)",
                //     style: TextStyle(
                //       color: mainColor,
                //       fontSize: 16,
                //       fontWeight: FontWeight.w600,
                //       fontFamily: _fontFamily,
                //     ),
                //   ),
                // ),
                SizedBox(height: 6),
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(
                      color: mainColor,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    autofocus: false,
                    controller: nametextController,
                    keyboardType: TextInputType.text,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(0),
                      border: InputBorder.none,
                      // prefixIcon: Icon(Icons.person),
                      hintText: "Username",
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(150.0),
                      border: Border.all(
                        color: mainColor,
                        width: 1.5,
                      ),
                      color: Colors.white,
                    ),
                    child: RawMaterialButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        goVerify();
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: mainColor,
                      ),
                      constraints: BoxConstraints.tightFor(
                        width: 50.0,
                        height: 50.0,
                      ),
                      shape: CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: (verified)
                ? Center(
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        Image(
                          image: AssetImage("${_appconfig.projectLogo}"),
                          width: 80,
                          height: 80,
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            "Verification",
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 20,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            "Your account has been verified successfully!",
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 16,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        Center(
                          child: _loading
                              ? SizedBox(
                                  height: 55,
                                  child: Center(
                                    child: SpinKitCircle(
                                      color: mainColor,
                                      size: 40.0,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(150.0),
                                    border: Border.all(
                                      color: mainColor,
                                      width: 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: RawMaterialButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      if (!_loading) {
                                        getDomain(_token);
                                      }
                                    },
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 22,
                                      color: mainColor,
                                    ),
                                    constraints: BoxConstraints.tightFor(
                                      width: 55,
                                      height: 55,
                                    ),
                                    shape: CircleBorder(),
                                  ),
                                ),
                        ),
                        SizedBox(height: 110),
                      ],
                    ),
                  )
                : Center(
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        Image(
                          image: AssetImage("${_appconfig.projectLogo}"),
                          width: 80,
                          height: 80,
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            "Verification",
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 20,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Center(
                          child: Text(
                            widget.phone,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            "OTP",
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: _fontFamily,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        PinCodeTextFieldAutoFill(
                          controller: otptextController,
                          onCompleted: (v) {
                            debugPrint("Completed");
                            setState(() {
                              if (_type == "2") {
                                displayName(context);
                              } else {
                                goVerify();
                              }
                            });
                          },
                          onChanged: (value) {},
                        ),
                        SizedBox(height: 40),
                        Center(
                          child: _loading
                              ? SizedBox(
                                  height: 55,
                                  child: Center(
                                    child: SpinKitCircle(
                                      color: mainColor,
                                      size: 40.0,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(150.0),
                                    border: Border.all(
                                      color: mainColor,
                                      width: 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: RawMaterialButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      if (!_loading) {
                                        if (otptextController.text.length >=
                                                4 &&
                                            otptextController.text.length <=
                                                9) {
                                          if (_type == "2") {
                                            displayName(context);
                                          } else {
                                            goVerify();
                                          }
                                        } else {
                                          _showSnackBar("Invalid OTP");
                                        }
                                      }
                                    },
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 22,
                                      color: mainColor,
                                    ),
                                    constraints: BoxConstraints.tightFor(
                                      width: 55.0,
                                      height: 55.0,
                                    ),
                                    shape: CircleBorder(),
                                  ),
                                ),
                        ),
                        SizedBox(height: 40),
                        Center(
                          child: Text(
                            "Didn't receive the code?",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: _fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        _recent
                            ? SpinKitCircle(
                                color: mainColor,
                                size: 20.0,
                              )
                            : Center(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (!_loading) {
                                        _recent = true;
                                        otptextController.text = "";
                                        checkRegister();
                                      }
                                    });
                                  },
                                  child: Text(
                                    "Resend",
                                    style: TextStyle(
                                      color: mainColor,
                                      fontSize: 16,
                                      fontFamily: _fontFamily,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
