import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';

import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/loading.dart';
import 'package:loyalty/style.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ScanLoyalty extends StatefulWidget {
  @override
  _ScanLoyaltyState createState() => _ScanLoyaltyState();
}

class _ScanLoyaltyState extends State<ScanLoyalty> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  String _fontFamily = "Ubuntu";
  QRViewController controller;

  bool viewQR = true;
  var _userData = {};

  String _domain = "";
  String qrText = "";

  final dateFormat = DateFormat("yyyyMMdd");
  final timeformat = DateFormat("hh:mm:ss a");

  final _provider = FunctionProvider();
  Color mainColor = Style().primaryColor;

  bool _loading = false;
  final _appconfig = AppConfig();

  final _apiurl = ApiUrl();
  var formatter = NumberFormat('#,##0', "en_US");

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
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  getData() async {
    final prefs = await SharedPreferences.getInstance();
    _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    _domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));
    var param = {"userid": _userData['userid'], "domain": _domain, "type": 1};
    qrText = jsonEncode(param);
    setState(() {});
  }

  void _onQRViewCreated(QRViewController controller) {
    String barcodeScanRes = "";
    setState(() {
      this.controller = controller;
    });
    this.controller.pauseCamera();
    this.controller.resumeCamera();
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      barcodeScanRes = scanData.code;
      // if (barcodeScanRes.startsWith('kunyek://signin?token=')) {
      //   callVerifyQRLogin(barcodeScanRes);
      // } else
      // if (barcodeScanRes.endsWith('=')) {

      // } else {
      var qrdata = await getQRcode(barcodeScanRes.toString());
      print("Scan QR>> $qrdata");
      if (qrdata == 'null') {
        callNewVerifyQRLogin(barcodeScanRes);
      } else {
        print("QR DECODE>> $qrdata");
        print("QQ>> ${qrdata.substring(0, 1)}");
        if (qrdata.substring(0, 1) == "{") {
          var couponData = json.decode(qrdata);
          checkRedeem(couponData);
        } else {
          checkCoupon(barcodeScanRes);          
          // LoadingPage.showLoadingAnimationDialog(context, _keyLoader);
          // LoadingPage.showLoadingCouponAnimationDialog(context, _keyLoader);
        }
      }

      // }
    });
  }

  // callVerifyQRLogin(value) async {
  //   LoadingPage.showLoadingDialog(context, _keyLoader);
  //   setState(() {
  //     _loading = true;
  //   });
  //   final prefs = await SharedPreferences.getInstance();
  //   final url = _apiurl.iamurl + 'verifyqrlogin';
  //   var token = _provider.getDecrypt(prefs.getString("app_token"));

  //   var body = jsonEncode({
  //     "userid": _userData['userid'],
  //     "atoken": token,
  //     "appid": _appconfig.appid,
  //     "requesturl": value
  //   });

  //   debugPrint("call verify qr body 2>>>>" + body.toString());

  //   final response = await http
  //       .post(Uri.parse(url),
  //           body: body,
  //           headers: <String, String>{"content-type": "application/json"})
  //       .timeout(Duration(seconds: 30))
  //       .catchError((error) {
  //         setState(() {
  //           setState(() {
  //             _loading = false;
  //             Navigator.pop(context);
  //             controller.resumeCamera();
  //           });
  //           _showSnackBar(_provider.connectionError);
  //         });
  //       });

  //   if (response != null) {
  //     if (response.statusCode == 200) {
  //       var result = json.decode(utf8.decode(response.bodyBytes));
  //       debugPrint("call verify qr result 2>>>>" + result.toString());
  //       if (result['returncode'] == "300") {
  //         setState(() {
  //           _loading = false;
  //         });
  //         Navigator.pop(context);
  //         Navigator.pop(context);
  //       } else if (result['returncode'] == "200") {
  //         setState(() {
  //           _loading = false;
  //           Navigator.pop(context);
  //           controller.resumeCamera();
  //         });
  //         _showSnackBar(result['message']);
  //         setState(() {});
  //       } else {
  //         setState(() {
  //           _loading = false;
  //           Navigator.pop(context);
  //           controller.resumeCamera();
  //         });
  //         _showSnackBar(result['status']);
  //         setState(() {});
  //       }
  //     } else {
  //       setState(() {
  //         _loading = false;
  //         Navigator.pop(context);
  //         controller.resumeCamera();
  //       });
  //       _showSnackBar(_provider.showErrMessage(response.statusCode));
  //       setState(() {});
  //     }
  //   }
  // }

  callNewVerifyQRLogin(value) async {
    print("SCAN>>> ");
    LoadingPage.showLoadingDialog(context, _keyLoader);
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'scanqr';
    var token = _provider.getDecrypt(prefs.getString("app_token"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "token": token,
      "appid": _appconfig.appid,
      "qr": value
    });

    debugPrint("call new verify qr body 1>>>>" + body.toString());

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            setState(() {
              _loading = false;
              Navigator.pop(context);
              controller.resumeCamera();
            });
            _showSnackBar(_provider.connectionError);
          });
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("call verify qr result 1>>>>" + result.toString());
        if (result['returncode'] == "300") {
          setState(() {
            _loading = false;
            controller.resumeCamera();
          });
          // Navigator.pop(context);
          Navigator.pop(context);
        } else if (result['returncode'] == "200") {
          setState(() {
            _loading = false;
            Navigator.pop(context);
            controller.resumeCamera();
          });
          _showSnackBar(result['message']);
          setState(() {});
        } else {
          setState(() {
            _loading = false;
            Navigator.pop(context);
            controller.resumeCamera();
          });
          _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        setState(() {
          _loading = false;
          Navigator.pop(context);
          controller.resumeCamera();
        });
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  getQRcode(scandata) {
    try {
      final key = encrypt.Key.fromUtf8('thisismysupersecretkeypleasehide');
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypt.Encrypted.fromBase64(scandata);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      return "null>>>>";
    }
  }

  checkRedeem(couponData) async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltycheckforredeem';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "winnerid": couponData['winnerid'],
      "coupon": couponData['coupon'],
      "date": couponData['date'],
      "userid": _userData['userid'],
      "appid": _appconfig.appid,
      "domainid": domainid,
      "atoken": token
    });
    debugPrint("check redeem body >>>>" + body.toString());

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            _loading = false;
            controller.resumeCamera();
            //debugPrint(error);
            // _showSnackBar(_provider.connectionError);
          });
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("check redeem result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          setState(() {
            _loading = false;
          });
          confirmRedeem(couponData, result['data']);
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            checkRedeem(couponData);
          }
        } else if (result['returncode'] == "200") {
          setState(() {
            _loading = false;
          });
          await errorDialog(result['message']);
          controller.resumeCamera();
          setState(() {});
        } else {
          setState(() {
            _loading = false;
          });
          await errorDialog("Sever Error");
          controller.resumeCamera();
          setState(() {});
        }
      } else {
        setState(() {
          _loading = false;
        });
        await errorDialog(_provider.showErrMessage(response.statusCode));
        controller.resumeCamera();
        setState(() {});
      }
    }
  }

  qrRedeem(couponData, data) async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltyqrredeem';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "winnerid": couponData['winnerid'],
      "coupon": couponData['coupon'],
      "orgid": data['orgid'],
      "userid": _userData['userid'],
      "appid": _appconfig.appid,
      "domainid": domainid,
      "atoken": token
    });
    debugPrint("loyalty qrredeem body >>>>" + body.toString());

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            _loading = false;
            Navigator.pop(context);
            controller.resumeCamera();
            // _showSnackBar(_provider.connectionError);
          });
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("loyalty qrredeem result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          setState(() {
            _loading = false;
          });
          Navigator.pop(context);
          await successfulDialog('Successfully');
          controller.resumeCamera();
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            qrRedeem(couponData, data);
          }
        } else if (result['returncode'] == "200") {
          setState(() {
            _loading = false;
            Navigator.pop(context);
          });
          await errorDialog(result['message']);
          controller.resumeCamera();
          setState(() {});
        } else {
          setState(() {
            _loading = false;
            Navigator.pop(context);
          });
          await errorDialog("Sever Error");
          controller.resumeCamera();
          setState(() {});
        }
      } else {
        setState(() {
          _loading = false;
          Navigator.pop(context);
        });
        await errorDialog(_provider.showErrMessage(response.statusCode));
        controller.resumeCamera();
        setState(() {});
      }
    }
  }

  checkCoupon(value) async {
    setState(() {
      _loading = true;
    });
    LoadingPage.showLoadingCouponAnimationDialog(context, _keyLoader);
    
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltycheckcoupondetails';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "coupon": value,
      "userid": _userData['userid'],
      "appid": _appconfig.appid,
      "domainid": domainid,
      "atoken": token
    });
    debugPrint("check coupon body >>>>" + body.toString());

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            _loading = false;
            Navigator.of(context).pop();
            controller.resumeCamera();
            //debugPrint(error);
            // _showSnackBar(_provider.connectionError);
          });
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("check coupon result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          setState(() {
            _loading = false;
            Navigator.of(context).pop();
          });
          confirmLoyaltyGift(result['data']);
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            checkCoupon(value);
          }
        } else if (result['returncode'] == "200") {
          setState(() {
            _loading = false;
            Navigator.of(context).pop();
          });
          await errorDialog(result['message']);
          controller.resumeCamera();
          setState(() {});
        } else {
          setState(() {
            _loading = false;
            Navigator.of(context).pop();
          });
          await errorDialog("Sever Error");
          controller.resumeCamera();
          setState(() {});
        }
      } else {
        setState(() {
          _loading = false;
          Navigator.of(context).pop();
        });
        await errorDialog(_provider.showErrMessage(response.statusCode));
        controller.resumeCamera();
        setState(() {});
      }
    }
  }

  loyaltyQrScan(value) async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'loyaltyqrscan';
    // final url = _apiurl.iamurl + 'testqrscan';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "qrdata": value,
      "userid": _userData['userid'],
      "appid": _appconfig.appid,
      "domainid": domainid,
      "atoken": token
    });
    debugPrint("loyalty URL >>>>" + url.toString());
    debugPrint("loyalty qrscan body >>>>" + body.toString());

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            _loading = false;
            Navigator.pop(context);
            controller.resumeCamera();
            // _showSnackBar(_provider.connectionError);
          });
        });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("loyalty qrscan result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          setState(() {
            _loading = false;
          });
          Navigator.pop(context);
          if (result['pricelist'].length > 0) {
            await getLoyaltyGift(result['pricelist'][0]['prize'],
                result['pricelist'][0]['instanttype']);
          } else {
            await getLoyaltyGift("", "");
          }
          controller.resumeCamera();
        } else if (result['returncode'] == "210") {
          var returnCode = await _provider.autoGetToken(context);
          if (returnCode == "300") {
            loyaltyQrScan(value);
          }
        } else if (result['returncode'] == "200") {
          setState(() {
            _loading = false;
            Navigator.pop(context);
          });
          await errorDialog(result['message']);
          controller.resumeCamera();
          setState(() {});
        } else {
          setState(() {
            _loading = false;
            Navigator.pop(context);
          });
          await errorDialog("Sever Error");
          controller.resumeCamera();
          setState(() {});
        }
      } else {
        setState(() {
          _loading = false;
          Navigator.pop(context);
        });
        await errorDialog(_provider.showErrMessage(response.statusCode));
        controller.resumeCamera();
        setState(() {});
      }
    }
  }

  _textWonPrice(price, type) {
    bool checkNum = _provider.isNumeric(price);
    if (checkNum && type == "002") {
      return formatter.format(int.parse(price)).toString();
    } else {
      return price;
    }
  }

  gotoHome(tab) async {
    final prefs = await SharedPreferences.getInstance();
    var _arrayTab = _provider.getJsonDecrypt(prefs.getString('menulist'));
    var a = 0;
    int page = 0;
    for (var i = 0; i < _arrayTab.length; i++) {
      if (_arrayTab[i]["pagename"].toString() == "MessagesPage()") {
        a = 1;
        page = i;
      }
    }
    if (a == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TabsPage(
            openTab: page,
            tabsLists: _arrayTab,
            msgTab: tab,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TabsPage(
            openTab: _arrayTab.length - 1,
            tabsLists: _arrayTab,
            msgTab: tab,
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  successfulDialog(msg) {
    return showDialog(
      context: context,
      builder: (_context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Container(
                height: 50,
                width: 50,
                margin: EdgeInsets.only(bottom: 10),
                child: Image(
                  image: AssetImage("assets/images/confirm.png"),
                ),
              ),
              Text(
                msg,
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
                        controller.resumeCamera();
                        setState(() {});
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

  errorDialog(msg) {
    return showDialog(
      context: context,
      builder: (_context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Container(
                height: 50,
                width: 50,
                margin: EdgeInsets.only(bottom: 10),
                child: Image(
                  image: AssetImage("assets/images/error.png"),
                ),
              ),
              Text(
                msg,
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
                        controller.resumeCamera();
                        setState(() {});
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

  confirmRedeem(coupon, data) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Container(
                height: 50,
                width: 50,
                margin: EdgeInsets.only(bottom: 10),
                child: Image(
                  image: AssetImage("assets/images/confirm.png"),
                ),
              ),
              Text(
                coupon['coupon'],
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
                    margin: EdgeInsets.only(bottom: 10, left: 20, right: 5),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.resumeCamera();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        side: BorderSide(
                          width: 2,
                          color: mainColor,
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10, left: 5, right: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        LoadingPage.showLoadingDialog(context, _keyLoader);
                        qrRedeem(coupon, data);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        primary: mainColor,
                      ),
                      child: Text(
                        "Confirm",
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

  confirmLoyaltyGift(coupon) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_context) => AlertDialog(
        titlePadding: const EdgeInsets.all(0),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Container(
                height: 50,
                width: 50,
                margin: EdgeInsets.all(10),
                child: Image(
                  image: AssetImage("assets/images/confirm.png"),
                ),
              ),
              Text(
                // coupon['coupon'],
                coupon['message'],
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
                    margin: EdgeInsets.only(bottom: 10, left: 20, right: 5),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.resumeCamera();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        side: BorderSide(
                          width: 2,
                          color: mainColor,
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10, left: 5, right: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        LoadingPage.showLoadingAnimationDialog(
                            context, _keyLoader);
                        loyaltyQrScan(coupon['coupon']);
                        // setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        primary: mainColor,
                      ),
                      child: Text(
                        "Confirm",
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

  getLoyaltyGift(value, type) {
    return showDialog(
      context: context,
      builder: (_context) => AlertDialog(
        title: Container(
          height: 100,
          width: 100,
          margin: EdgeInsets.only(top: 20, bottom: 10),
          child: Image(
            image: (value == "")
                ? AssetImage("assets/images/congratulations.png")
                : AssetImage("assets/images/congratulations.gif"),
          ),
        ),
        content: Text(
          (value == "")
              ? "Thank You\nBetter luck next time"
              : ("Congratulations, you won " + _textWonPrice(value, type)),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            color: mainColor,
            fontSize: 18,
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
                        controller.resumeCamera();
                        setState(() {});
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
    Widget _buildQrView(BuildContext context) {
      return QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.white,
          borderRadius: 0,
          borderLength: 15,
          borderWidth: 5,
          cutOutBottomOffset: 35,
          cutOutSize: MediaQuery.of(context).size.width * 2.1 / 3,
        ),
      );
    }

    Widget _buildQrCode(BuildContext context) {
      return Center(
        child: Container(
          margin: EdgeInsets.only(bottom: 70),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 3,
                spreadRadius: 1,
                offset: Offset(2.0, 2.0),
              ),
            ],
            color: Colors.white,
          ),
          child: QrImage(
            data: qrText,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width * 2 / 3,
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                (viewQR) ? _buildQrView(context) : _buildQrCode(context),
                _loading
                    ? Positioned(
                        bottom: 80,
                        right: (MediaQuery.of(context).size.width - 35) / 2,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 1.5,
                                  color: Colors.white,
                                ),
                                color: Colors.grey[300],
                              ),
                              child: SpinKitCircle(
                                color: Colors.black,
                                size: 23,
                              )),
                        ),
                      )
                    : Positioned(
                        bottom: 0,
                        right: (MediaQuery.of(context).size.width - 35) / 2,
                        child: Container(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
