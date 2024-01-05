import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Verify/otp.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyPage extends StatefulWidget {
  @override
  _VerifyPageState createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController textController = new TextEditingController();

  TextEditingController domaintextController = new TextEditingController();
  TextEditingController codetextController = new TextEditingController();

  String message = '';
  String type = '';

  String _fontFamily = "Ubuntu";
  Color mainColor = Style().primaryColor;

  String verify = "Verify";
  bool errmsg = false;
  bool eulaVal = true;

  final _provider = FunctionProvider();
  final _appconfig = AppConfig();

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.parse(s, (e) => null) != null;
  }

  getText(context) {
    bool phone = isNumeric(textController.text.trim());

    if (phone) {
      type = 'phone';
      checkPhoneType(context);
    } else {
      cannotGo();
      // type = 'email';
      // checkEmail(context);
    }
    setState(() {});
  }

  checkPhoneType(context) {
    var phone = textController.text.trim();
    var a = phone.substring(0, 2);

    if (a == '09') {
      if (phone.length >= 9 && phone.length <= 11) {
        message = "";
        errmsg = false;
        phone = "+95" + phone.substring(1);

      } else {
        cannotGo();
        print("1>>>>");
      }
    } else {
      var b = phone.substring(0, 1);
      if (b == '+') {
        phone = phone;
      } else {
        cannotGo();
        print("2>>>>");
        // textController.text = "+959" + phone;
      }
    }
    if (phone.length >= 4) {
      if (phone.substring(0, 4) == "+959" ||
          phone.substring(0, 4) == "+977" ||
          phone.substring(0, 4) == "+855" ||
          phone.substring(0, 4) == "+856") {
        canGo(phone);
      } else if (phone.substring(0, 3) == "+44" ||
          phone.substring(0, 3) == "+65" ||
          phone.substring(0, 3) == "+66") {
        canGo(phone);
      } else if (phone.substring(0, 2) == "+1") {
        canGo(phone);
      } else {
        cannotGo();
        print("3>>>>");
      }
    } else {
      cannotGo();
      print("4>>>>");
    }
  }

  canGo(phone) {
    message = "";
    errmsg = false;
    textController.text = phone;
    goOTP();
    setState(() {});
  }

  cannotGo() {
    message = "Unsupported mobile number or country code!";
    errmsg = true;
    setState(() {});
  }

  // checkEmail(context) {
  //   var email = textController.text;

  //   if (email.contains('@')) {
  //     bool emailValid = RegExp(r'\S+@\S+\.\S+').hasMatch(email);

  //     if (emailValid) {
  //       message = "";
  //       errmsg = false;
  //       textController.text = textController.text.toLowerCase();
  //       goOTP();
  //     } else {
  //       message = "Invalid Email Address!";
  //       errmsg = true;
  //     }
  //   } else {
  //     message = "Invalid. Please try again!";
  //     errmsg = true;
  //   }
  //   setState(() {});
  // }

  goOTP() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => OTPPage(textController.text)));
    setState(() {});
  }

  displayDomainSetup(context) {
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
              "Domain Setup",
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
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    "Domain",
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  height: 40,
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
                    controller: domaintextController,
                    keyboardType: TextInputType.text,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(0),
                      border: InputBorder.none,
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: WillPopScope(
        onWillPop: () async {
          exit(0);
          return false;
        },
        child: Builder(
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
                      width: 100,
                      height: 100,
                    ),
                    // SizedBox(height: 10),
                    // Center(
                    //   child: Text(
                    //     "${_appconfig.projectName}",
                    //     style: TextStyle(
                    //       color: mainColor,
                    //       fontSize: 20,
                    //       fontFamily: _fontFamily,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    // ),
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
                            hintText: "Mobile",
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
