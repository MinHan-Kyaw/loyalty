import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/MenuDrawer/add_otp.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AddAccountPage extends StatefulWidget {
  @override
  _AddAccountPageState createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController textController = new TextEditingController();

  TextEditingController domaintextController = new TextEditingController();
  TextEditingController codetextController = new TextEditingController();

  String message = '';
  String type = '';

  String _fontFamily = "Ubuntu";
  bool errmsg = false;
  bool eulaVal = true;

  List _allAccList = [];
  Color mainColor = Style().primaryColor;

  final _provider = FunctionProvider();
  final _appconfig = AppConfig();

  @override
  void initState() {
    super.initState();
    getAllAccount();
    setState(() {});
  }

  getAllAccount() async {
    final prefs = await SharedPreferences.getInstance();
    _allAccList = _provider.getJsonDecrypt(prefs.getString('userlist'));
    setState(() {});
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.parse(s, (e) => null) != null;
  }

  getText(context) {
    bool phone = isNumeric(textController.text);

    if (phone) {
      type = 'phone';
      checkPhoneType(context);
    } else {
      type = 'email';
      checkEmail(context);
    }
    setState(() {});
  }

  checkPhoneType(context) {
    var phone = textController.text;
    var a = phone.substring(0, 2);

    if (a == '09') {
      if (textController.text.length >= 9 && textController.text.length <= 11) {
        message = "";
        errmsg = false;
        textController.text = "+95" + phone.substring(1);
      } else {
        cannotGo();
      }
    } else {
      var b = phone.substring(0, 1);
      if (b == '+') {
        textController.text = phone;
      } else {
        cannotGo();
        // textController.text = "+959" + phone;
      }
    }
    if (textController.text.length >= 4) {
      if (textController.text.substring(0, 4) == "+959" ||
          textController.text.substring(0, 4) == "+977" ||
          textController.text.substring(0, 4) == "+855" ||
          textController.text.substring(0, 4) == "+856") {
        canGo();
      } else if (textController.text.substring(0, 3) == "+44" ||
          textController.text.substring(0, 3) == "+65" ||
          textController.text.substring(0, 3) == "+66") {
        canGo();
      } else if (textController.text.substring(0, 2) == "+1") {
        canGo();
      } else {
        cannotGo();
      }
    } else {
      cannotGo();
    }
  }

  canGo() {
    message = "";
    errmsg = false;
    goOTP();
    setState(() {});
  }

  cannotGo() {
    message = "Unsupported mobile number or country code!";
    errmsg = true;
    setState(() {});
  }

  // checkPhoneType(context) {
  //   var phone = textController.text;
  //   var a = phone.substring(0, 2);

  //   if (a == '09') {
  //     textController.text = "+95" + phone.substring(1);
  //   } else {
  //     var b = phone.substring(0, 1);
  //     if (b == '+') {
  //       textController.text = phone;
  //     } else {
  //       textController.text = "+959" + phone;
  //     }
  //   }
  //   if (textController.text.length == 11 || textController.text.length == 13) {
  //     message = "";
  //     errmsg = false;
  //     goOTP();
  //   } else {
  //     message = "Unsupported mobile number or country code!";
  //     errmsg = true;
  //   }
  //   setState(() {});
  // }

  checkEmail(context) {
    var email = textController.text;

    if (email.contains('@')) {
     bool emailValid = RegExp(r'\S+@\S+\.\S+').hasMatch(email);

      if (emailValid) {
        message = "";
        errmsg = false;
        textController.text = textController.text.toLowerCase();
        goOTP();
      } else {
        message = "Invalid Email Address!";
        errmsg = true;
      }
    } else {
      message = "Invalid. Please try again!";
      errmsg = true;
    }
    setState(() {});
  }

  goOTP() {
    bool add = false;
    for (var i = 0; i < _allAccList.length; i++) {
      if (_allAccList[i]['userid'] == textController.text) {
        add = true;
      }
    }
    if (add) {
      Navigator.pop(context);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddOTPPage(textController.text)));
    }
    setState(() {});
  }

  openEULA(link) async {
    var url = "";
    if (link == "Terms") {
      url = "https://www.kunyek.com/eula";
    } else {
      url = "https://www.kunyek.com/privacy";
    }
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
            child: Center(
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
                      "${_appconfig.projectName}",
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 20,
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Container(
                    margin: EdgeInsets.only(right: 20, left: 20, bottom: 10),
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 20, left: 20),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(
                        color: mainColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        autofocus: false,
                        controller: textController,
                        keyboardType: TextInputType.text,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(0),
                          border: InputBorder.none,
                          hintText: "Email or Mobile",
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: errmsg
                          ? Text(
                              message,
                              style: TextStyle(
                                color: Colors.red,
                                fontFamily: _fontFamily,
                              ),
                            )
                          : SizedBox(height: 0),
                    ),
                  ),
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
                          if (eulaVal) {
                            FocusScope.of(context).unfocus();
                            getText(context);
                          } else {
                            setState(() {
                              message = "Invalid. Please accept agreement!";
                              errmsg = true;
                            });
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
                  SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 35.0),
          child: Text(
            _appconfig.version,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
