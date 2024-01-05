import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:heic_to_jpg/heic_to_jpg.dart';
import 'package:loyalty/Home/tab_service.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/MenuDrawer/session_expired.dart';
import 'package:loyalty/Verify/verification.dart';
import 'package:rabbit_converter/rabbit_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;
import 'package:encrypt/encrypt.dart' as encrypt;

class FunctionProvider {
  final _appconfig = AppConfig();
  final _apiurl = ApiUrl();
  String connectionError = "Connection lost.";
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  DefaultOrgService _orgService = DefaultOrgService();

  getCurrentYear(aStatus) {
    var date = DateFormat("dd/MM/yyyy").format(DateTime.now());
    var year;
    if (aStatus == "max") {
      year = int.parse(date.substring(6, 10)) + 1;
      return DateTime(year, 12, 31);
    } else {
      year = int.parse(date.substring(6, 10)) - 20;
      return DateTime(year, 01, 01);
    }
  }

  showDate(date) {
    var day = date.substring(6, 8);
    var month = date.substring(4, 6);
    var year = date.substring(0, 4);
    return day + "/" + month + "/" + year;
  }

  sendDate(date) {
    var day = date.substring(0, 2);
    var month = date.substring(3, 5);
    var year = date.substring(6, 10);
    return year + month + day;
  }

  bindTimePicker(atime) {
    var check = atime.indexOf(':');
    var time = atime.toString();
    var hour, min, amorpm, second = "00";
    var check1 = atime.substring(0, 4);
    if (check1 == "12::" || check1 == "12: ") {
      hour = "00";
      min = "00";
    } else {
      if (atime.length > 8) {
        if (check == 1) {
          hour = "0" + time.substring(0, 1);
          min = time.substring(2, 4);
          second = time.substring(5, 7);
          amorpm = time.substring(8, 10);
        } else {
          hour = time.substring(0, 2);
          min = time.substring(3, 5);
          second = time.substring(6, 8);
          amorpm = time.substring(9, 11);
        }
      } else {
        if (atime.length != 0) {
          if (check == 1) {
            hour = "0" + time.substring(0, 1);
            min = time.substring(2, 4);
            amorpm = time.substring(5, 7);
          } else {
            hour = time.substring(0, 2);
            min = time.substring(3, 5);
            amorpm = time.substring(6, 8);
          }
        }
      }
      if (amorpm == "PM") {
        if (int.parse(hour) < 12) {
          hour = int.parse(hour) + 12;
          hour = hour.toString();
        }
      } else {
        if (int.parse(hour) == 12) {
          hour = "00";
        }
      }
    }
    DateTime dateAndtime = DateTime(
        2020, 5, 5, int.parse(hour), int.parse(min), int.parse(second));
    return dateAndtime;
  }

  bindDatePicker(datetime) {
    var date = datetime.toString();
    var day = date.substring(0, 2);
    var month = date.substring(3, 5);
    var year = date.substring(6, 10);
    DateTime dateAndtime =
        DateTime(int.parse(year), int.parse(month), int.parse(day));
    return dateAndtime;
  }

  bindDateMMM(dateTime) {
    var datetime = dateTime.toString();
    var year, month, day;
    year = datetime.substring(0, 4);
    month = datetime.substring(4, 6);
    day = datetime.substring(6, 8);
    DateTime dateAndtime =
        DateTime(int.parse(year), int.parse(month), int.parse(day));
    return dateAndtime;
  }

  timeFormatAM(atime) {
    var am = atime.indexOf('AM');
    var pm = atime.indexOf('PM');
    var check = atime.indexOf(':');
    var time = atime.toString();
    var hour, min, amorpm;

    if (am == -1 && pm == -1) {
      if (check == 1) {
        hour = time.substring(0, 1);
        min = time.substring(2, 4);
      } else {
        hour = time.substring(0, 2);
        min = time.substring(3, 5);
      }
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
    } else {
      return atime;
    }
  }

  returnDay(datetime) {
    var year, month, day;
    year = int.parse(datetime.substring(0, 4));
    month = int.parse(datetime.substring(4, 6));
    day = int.parse(datetime.substring(6, 8));
    var dDay = new DateTime.utc(year, month, day);
    var value = "";
    if (DateTime.monday == dDay.weekday) {
      value = "Mon";
    } else if (DateTime.tuesday == dDay.weekday) {
      value = "Tue";
    } else if (DateTime.wednesday == dDay.weekday) {
      value = "Wed";
    } else if (DateTime.thursday == dDay.weekday) {
      value = "Thu";
    } else if (DateTime.friday == dDay.weekday) {
      value = "Fri";
    } else if (DateTime.saturday == dDay.weekday) {
      value = "Sat";
    } else if (DateTime.sunday == dDay.weekday) {
      value = "Sun";
    }
    return value;
  }

  returnLongDay(datetime) {
    var year, month, day;
    year = int.parse(datetime.substring(0, 4));
    month = int.parse(datetime.substring(4, 6));
    day = int.parse(datetime.substring(6, 8));
    var dDay = new DateTime.utc(year, month, day);
    var value = "";
    if (DateTime.monday == dDay.weekday) {
      value = "Monday";
    } else if (DateTime.tuesday == dDay.weekday) {
      value = "Tuesday";
    } else if (DateTime.wednesday == dDay.weekday) {
      value = "Wednesday";
    } else if (DateTime.thursday == dDay.weekday) {
      value = "Thursday";
    } else if (DateTime.friday == dDay.weekday) {
      value = "Friday";
    } else if (DateTime.saturday == dDay.weekday) {
      value = "Saturday";
    } else if (DateTime.sunday == dDay.weekday) {
      value = "Sunday";
    }
    return value;
  }

  convertSaveTime(atime) {
    var check = atime.indexOf(':');
    var time = atime.toString();
    var hour, min, amorpm;
    if (check == 1) {
      hour = "0" + time.substring(0, 1);
      min = time.substring(2, 4);
      amorpm = time.substring(5, 7);
    } else {
      hour = time.substring(0, 2);
      min = time.substring(3, 5);
      amorpm = time.substring(6, 8);
    }
    if (amorpm == "PM") {
      if (int.parse(hour) < 12) {
        hour = int.parse(hour) + 12;
        hour = hour.toString();
      }
    } else {
      if (int.parse(hour) == 12) {
        hour = "00";
      }
    }
    return hour + ':' + min;
  }

  returnMinute(atime) {
    var check = atime.indexOf(':');
    var hour = atime.substring(0, check);
    var min = atime.substring(check + 1, atime.length);
    var value = (int.parse(hour) * 60) + int.parse(min);
    return value;
  }

  splitTime(time) {
    if (time.length > 8) {
      var check1 = time.substring(0, 4);
      if (check1 == "12::" || check1 == "12: ") {
        return time;
      } else {
        var hmin, ampm;
        hmin = time.substring(0, 5);
        ampm = time.substring(time.indexOf(' '), time.length);
        return hmin + ' ' + ampm;
      }
    } else {
      return time;
    }
  }

  splitLatLong(aLat) {
    if (aLat.length > 8) {
      return aLat.substring(0, 8);
    } else {
      return aLat;
    }
  }

  splitLocationName(value) {
    var locationName;
    var checkDask = value.indexOf('-');
    if (checkDask == -1) {
      locationName = value;
    } else {
      var checkname = value.substring(checkDask, value.length);
      if (checkname == "-" || checkname == "- ") {
        locationName = value.substring(0, checkDask);
      } else {
        locationName = value;
      }
    }
    return locationName;
  }

  getThemeStg() async {
    var returnVal;
    final prefs = await SharedPreferences.getInstance();
    var theme = getDecrypt(prefs.getString('checkin_theme'));
    if (theme == "" || theme == null || theme == "light") {
      returnVal = "light";
    } else {
      returnVal = "blue";
    }
    return returnVal;
  }

  getLanStg() async {
    var returnVal;
    final pref = await SharedPreferences.getInstance();
    var lan = getDecrypt(pref.getString('checkin_lang'));

    if (lan == "" || lan == null || lan == "eng") {
      returnVal = "eng";
    } else {
      returnVal = "myan";
    }
    return returnVal;
  }

  showErrMessage(code) {
    var msg = "";
    if (code == 404) {
      msg = "Url link wroung.";
    } else if (code == 500) {
      msg = "Server not response.";
    } else if (code == -1) {
      msg = "Server stop.";
    } else if (code == 0) {
      msg = "App lost connection.";
    } else {
      msg = "Connection lost.";
    }
    return msg;
  }

  sessionExpired(context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SessionExpired();
      },
    );
  }

  autoGetToken(context) async {
    final prefs = await SharedPreferences.getInstance();
    var domain = getDecrypt(prefs.getString("kunyek_domain"));
    var userData = getJsonDecrypt(prefs.getString('userdata'));
    var token = getDecrypt(prefs.getString("app_token"));
    var deviceid = await FlutterUdid.udid;
    final url = _apiurl.urlname + 'checktokenkunyek';

    var body = jsonEncode({
      "userid": userData['userid'],
      "domain": domain,
      "appid": _appconfig.appid,
      "atoken": token,
      "password": "",
      "recaptcha": "",
      "uuid": deviceid,
      "skip": "true"
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {});

    debugPrint("signin body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString('app_token', setEncrypt(result['atoken']));
        } else {
          goLogout(context);
        }
      }
    }
  }

  autoGetTokenHcm(context) async {
    final prefs = await SharedPreferences.getInstance();
    var _userData = getJsonDecrypt(prefs.getString('userdata'));
    final url =
        _apiurl.hcmurl + '/module001/serviceRegistrationAPI/refreshbtoken';

    var body = jsonEncode({"btoken": _userData['sessionID']});

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {});

    debugPrint("token body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("token result >>>>" + result.toString());
        if (result['state']) {
          _userData['sessionID'] = result['btoken'];
          prefs.setString('userdata', setJsonEncrypt(_userData));
        }
      }
    }
  }

  goLogout(context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("kun_verify", setEncrypt("false"));
    prefs.setString("userdata", setJsonEncrypt({}));
    prefs.setString('userlist', setJsonEncrypt([]));
    prefs.setString("menulist", setJsonEncrypt([]));
    prefs.setString('showmore', setEncrypt("0"));
    prefs.setString('campaignslist', setEncrypt("0"));
    prefs.setString('winnercampaignslist', setEncrypt("0"));
    prefs.setString('couponslist', setEncrypt("0"));
    prefs.setString("coupon_filtercode", setEncrypt("0"));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return VerifyPage();
        },
      ),
    );
  }

  profileImageCompress(image) async {
    String imgtype = image.path.split(".").last;
    if (imgtype == "heic" || imgtype == "HEIC") {
      String jpegPath = await HeicToJpg.convert(image.path);
      image = File(jpegPath);
      imgtype = 'jpeg';
    }
    final bytes = image.readAsBytesSync().lengthInBytes;
    final kb = bytes / 1024;
    final mb = kb / 1024;
    double _mb = double.parse(mb.toString());
    double _kb = double.parse(kb.toString());

    if (_mb >= 3) {
      File compressedFile = await FlutterNativeImage.compressImage(
        image.path,
        percentage: 25,
        quality: 50,
      );
      image = File(compressedFile.path);
    } else if (_mb < 3 && _mb > 1) {
      File compressedFile = await FlutterNativeImage.compressImage(
        image.path,
        percentage: 50,
        quality: 50,
      );
      image = File(compressedFile.path);
    } else if (_mb < 1 && _kb > 300) {
      File compressedFile = await FlutterNativeImage.compressImage(
        image.path,
        percentage: 90,
        quality: 70,
      );
      image = File(compressedFile.path);
    } else if (_kb < 300 && _kb > 100) {
      File compressedFile = await FlutterNativeImage.compressImage(
        image.path,
        percentage: 75,
        quality: 50,
      );
      image = File(compressedFile.path);
    }

    return image;
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    var kilo = 12742 * asin(sqrt(a));
    var meter = kilo * 1000;
    return meter;
  }

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint("Permission1>> $permission");

      permission = await _geolocatorPlatform.requestPermission();
      debugPrint("Permission2>> $permission");

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  getAddress(latitude, longitude) async {
    try {
      // From coordinates
      final coordinates = new Coordinates(latitude, longitude);
      var addresses =
          await Geocoder.local.findAddressesFromCoordinates(coordinates);
      var first = addresses.first;
      // debugPrint("Address Line : ${first.addressLine}");
      // debugPrint("Address adminArea : ${first.adminArea}");
      // debugPrint("Address subAdminArea : ${first.subAdminArea}");
      // debugPrint("Address locality : ${first.locality}");
      // debugPrint("Address subLocality : ${first.subLocality}");
      // debugPrint("Address thoroughfare : ${first.thoroughfare}");
      // debugPrint("Address subThoroughfare : ${first.subThoroughfare}");
      var name = "";
      if (first.thoroughfare != null && first.locality != null) {
        name = first.thoroughfare + ' , ' + first.locality;
      } else {
        if (first.thoroughfare != null) {
          name = first.thoroughfare;
        } else {
          name = first.locality;
        }
      }

      return name;
    } catch (e) {
      debugPrint("err>> $e");
    }
  }

  Future setDeviceFont() async {
    final prefs = await SharedPreferences.getInstance();

    String deviceLanguage = await Devicelocale.currentLocale;
    var checkfont = deviceLanguage.substring(3, 5);
    if (checkfont == 'ZG') {
      debugPrint(checkfont);
      // debugPrint('lenght ---- ' + textMyan.length.toString());
      prefs.setString("lan", setEncrypt("Zg"));
    } else {
      // debugPrint('lenght ---- ' + textMyan.length.toString());
      prefs.setString("lan", setEncrypt("Uni"));
    }
    debugPrint('-->$deviceLanguage');
  }

  //set Zawgyi to Uni
  set2Uni(txt) {
    try {
      return Rabbit.zg2uni(txt);
    } catch (e) {
      debugPrint("Set2uniterr>> $e");
      return txt;
    }
  }

  //show Zawgyi to Uni
  showZawgyi2Uni(txt) async {
    final prefs = await SharedPreferences.getInstance();
    var lan = getDecrypt(prefs.getString("lan"));

    if (lan != null && lan != "") {
      if (lan == "Zg") {
        return Rabbit.uni2zg(txt);
      } else {
        return txt;
      }
    }

    return txt;
  }

  setDefaultOrgId(orgid) async {
    final prefs = await SharedPreferences.getInstance();

    _orgService.setOrgid(orgid);
    prefs.setString('defaultorgid', setEncrypt(orgid));

    final url = _apiurl.urlname + 'user/defaultorg/add';
    var token = getDecrypt(prefs.getString("app_token"));
    var _userData = getJsonDecrypt(prefs.getString('userdata'));
    var _domain = getDecrypt(prefs.getString("kunyek_domain"));

    var body = jsonEncode({
      "orgid": orgid,
      "userid": _userData['userid'],
      "domain": _domain,
      "appid": _appconfig.appid,
      "atoken": token
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {});
    debugPrint("setdefaultorg body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("setdefaultorg result >>>>" + result.toString());
        if (result['returncode'] != "300") {
        } else if (result['returncode'] != "210") {}
      }
    }
  }

  isNumeric(String txt) {
    try {
      if (txt == null) {
        return false;
      }

      var check = int.parse(txt);

      return true;
    } catch (e) {
      return false;
    }
  }
//   final encryptKey = "This 32 char key have 256 bits..";

//     ///Accepts encrypted data and decrypt it. Returns plain text
// String decryptWithAES(String key, Encrypted encryptedData) {
//   final cipherKey = encrypt.Key.fromUtf8(key);
//   final encryptService = Encrypter(AES(cipherKey, mode: AESMode.cbc)); //Using AES CBC encryption
//   final initVector = IV.fromUtf8(key.substring(0, 16)); //Here the IV is generated from key. This is for example only. Use some other text or random data as IV for better security.

//   return encryptService.decrypt(encryptedData, iv: initVector);
// }

// ///Encrypts the given plainText using the key. Returns encrypted data
// Encrypted encryptWithAES(String key, String plainText) {
//   final cipherKey = encrypt.Key.fromUtf8(key);
//   final encryptService = Encrypter(AES(cipherKey, mode: AESMode.cbc));
//   final initVector = IV.fromUtf8(key.substring(0, 16)); //Here the IV is generated from key. This is for example only. Use some other text or random data as IV for better security.

//   Encrypted encryptedData = encryptService.encrypt(plainText, iv: initVector);

//   // String encryptedBase64 = encryptedData.base64;
//   return encryptedData;
// }

// // For Fernet Encryption/Decryption
//   static final keyFernet =
//       encrypt.Key.fromUtf8('TechWithVPIsBestTechWithVPIsBest');
//   // if you need to use the ttl feature, you'll need to use APIs in the algorithm itself
//   static final fernet = encrypt.Fernet(keyFernet);
//   static final encrypterFernet = encrypt.Encrypter(fernet);

//     encryptFernet(text) {
//     final encrypted = encrypterFernet.encrypt(text);

//     debugPrint(fernet.extractTimestamp(encrypted.bytes)); // unix timestamp
//     return encrypted;
//   }

//     decryptFernet(text) {
//     return encrypterFernet.decrypt(text);
//   }

  final decrypyKey = "L&9O)*Y@#A%&*L+(T&^Y!~N073EX_XUS";

  setEncrypt(data) {
    final key = encrypt.Key.fromUtf8(decrypyKey);
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(data, iv: iv);

    return encrypted.base64;
  }

  getDecrypt(data) {
    try {
      final key = encrypt.Key.fromUtf8(decrypyKey);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypt.Encrypted.fromBase64(data);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      return data;
    }
  }

  setJsonEncrypt(data) {
    final key = encrypt.Key.fromUtf8(decrypyKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(json.encode(data), iv: iv);

    return encrypted.base64;
  }

  getJsonDecrypt(data) {
    try {
      final key = encrypt.Key.fromUtf8(decrypyKey);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypt.Encrypted.fromBase64(data);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return json.decode(decrypted);
    } catch (e) {
      return data;
    }
  }
}
