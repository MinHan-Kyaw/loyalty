import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// import 'package:aws_s3/aws_s3.dart';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera_camera/camera_camera.dart';
import 'package:loyalty/Home/tab_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/Config/apiurl.dart';
import 'package:loyalty/Config/appconfig.dart';
import 'package:loyalty/Home/tabs.dart';
import 'package:loyalty/Widgets/camera_permission.dart';
import 'package:loyalty/Widgets/gallery_permission.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/loading.dart';
import 'package:loyalty/style.dart';
// import 'package:minio/minio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class ProfilePage extends StatefulWidget {
  final userdata;
  ProfilePage(this.userdata);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  DefaultOrgService _orgService = DefaultOrgService();

  ScrollController _scrollController = ScrollController();
  final _appconfig = AppConfig();

  final _provider = FunctionProvider();
  Color mainColor = Style().primaryColor;

  TextEditingController nameController = new TextEditingController();
  TextEditingController phoneController = new TextEditingController();

  TextEditingController nrcController = new TextEditingController();
  TextEditingController stateController = new TextEditingController();

  TextEditingController townshipController = new TextEditingController();
  TextEditingController addressController = new TextEditingController();

  String _fontFamily = "Ubuntu";
  var _userData = {};

  bool _loading = false;
  var _domain = "";

  File _image;
  bool changeImage = false;

  List _orgList = [];
  var _domainData = {};

  // String domainadmin = "";
  // String domainurl = "";

  final _apiurl = ApiUrl();
  String _selectMenuSetDefaultOrgid = "";

  List _divisionList = [];
  List<String> _divisionLst = [];

  String _selectDivision = "_";
  String _divisionID = "";

  List _regionList = [];
  List<String> _regionLst = [];

  String _selectRegion = "_";

  List _townshipList = [];
  List<String> _townshipLst = [];

  String _selectTownship = "_";
  String _townshipID = "";

  bool showMore = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    bindData();
    setState(() {});
  }

  bindData() async {
    final prefs = await SharedPreferences.getInstance();
    _userData = widget.userdata;
    nameController.text = _userData['username'];
    phoneController.text = _userData['userid'];
    nrcController.text = _userData['nrc'];
    _divisionID = _userData['state'];
    _selectRegion = (_userData['region'] == "") ? "_" : _userData['region'];
    _townshipID = _userData['township'];
    addressController.text = _userData['address'];
    _domain = _provider.getDecrypt(prefs.getString("kunyek_domain"));

    var domainData = _provider.getDecrypt(prefs.getString('domain_data'));
    if (domainData != null && domainData != "" && domainData != "0") {
      _domainData = _provider.getJsonDecrypt(prefs.getString('domain_data'));
    }
    var _organizationList =
        _provider.getDecrypt(prefs.getString('organizationslist'));
    if (_organizationList != null &&
        _organizationList != "" &&
        _organizationList != "0") {
      _orgList = _provider.getJsonDecrypt(prefs.getString('organizationslist'));
    }
    var _showProfile =
        _provider.getDecrypt(prefs.getString('showmore_profile'));
    if (_showProfile != null && _showProfile != "" && _showProfile != "0") {
      showMore =
          _provider.getDecrypt(prefs.getString('showmore_profile')) == "true";
    }

    _selectMenuSetDefaultOrgid =
        _provider.getDecrypt(prefs.getString("defaultorgid"));
    _orgService.setOrgid(_provider.getDecrypt(prefs.getString("defaultorgid")));

    readJson();
    checkDomain();
    setState(() {});
  }

  readJson() async {
    final String response =
        await rootBundle.loadString('assets/json/township.json');
    final data = await json.decode(response);
    _divisionList = data[0]['division'];
    var a = 0;

    for (var i = 0; i < _divisionList.length; i++) {
      _divisionLst.add(_divisionList[i]['name']);
      if (_divisionList[i]['divId'] == _divisionID) {
        _selectDivision = _divisionList[i]['name'];
        a = i;
      }
    }
    getRegion(a);
    setState(() {});
  }

  getRegion(index) {
    _regionLst = [];
    _regionList = _divisionList[index]['disList'];
    var a = 0;
    var b = 0;

    for (var i = 0; i < _regionList.length; i++) {
      _regionLst.add(_regionList[i]['name']);
      if (_regionList[i]['name'] == _selectRegion) {
        a = i;
        b = 1;
      }
    }
    if (b == 0) {
      _selectRegion = "_";
    }
    getTownship(a);
    setState(() {});
  }

  getTownship(index) {
    _townshipLst = [];
    _townshipList = _regionList[index]['tsList'];
    var a = 0;

    for (var i = 0; i < _townshipList.length; i++) {
      _townshipLst.add(_townshipList[i]['name']);
      if (_townshipList[i]['tsId'] == _townshipID) {
        _selectTownship = _townshipList[i]['name'];
        a = 1;
      }
    }
    if (a == 0) {
      _selectTownship = "_";
      _townshipID = "";
    }
    setState(() {});
  }

  checkDomain() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.iamurl + 'checkdomain';

    var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
    print("UD>> $_userData");
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "userid": _userData['userid'],
      "domainid": domainid,
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
            debugPrint(_provider.connectionError);
          });
        });

    debugPrint("check domain body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("check domain result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          prefs.setString(
              "domain_data", _provider.setJsonEncrypt(result['domain']));
          prefs.setString("organizationslist",
              _provider.setJsonEncrypt(result['organizations']));
          setState(() {});
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          checkDomain();
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

  updateUser(imagename) async {
    final prefs = await SharedPreferences.getInstance();
    final url = _apiurl.urlname + 'user/update';
    var token = _provider.getDecrypt(prefs.getString("app_token"));
    var domainid = _provider.getDecrypt(prefs.getString("kunyek_domain_id"));

    var body = jsonEncode({
      "syskey": _userData['syskey'],
      "username": nameController.text,
      "userid": phoneController.text,
      "nrc": nrcController.text,
      "state": _divisionID,
      "region": _selectRegion,
      "township": _townshipID,
      "address": addressController.text,
      "imagename": imagename,
      "domain": _domain,
      "domainid": domainid,
      "atoken": token,
      "appid": _appconfig.appid
    });

    final response = await http
        .post(Uri.parse(url),
            body: body,
            headers: <String, String>{"content-type": "application/json"})
        .timeout(Duration(seconds: 30))
        .catchError((error) {
          setState(() {
            _loading = false;
            Navigator.pop(context);
            _showSnackBar(_provider.connectionError);
          });
        });

    debugPrint("signin update profile body >>>>" + body);

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("signin update profile result >>>>" + result.toString());
        if (result['returncode'] == "300") {
          _loading = false;

          await prefs.setString('userdata', _provider.setJsonEncrypt(result));
          var _userData = _provider.getJsonDecrypt(prefs.getString('userdata'));
          print("RETURN_UD>> $_userData");
          gotoHome();
        } else if (result['returncode'] == "210") {
          await _provider.autoGetToken(context);
          updateUser(imagename);
        } else {
          _loading = false;
          Navigator.pop(context);
          _showSnackBar(result['status']);
          setState(() {});
        }
      } else {
        _loading = false;
        Navigator.pop(context);
        _showSnackBar(_provider.showErrMessage(response.statusCode));
        setState(() {});
      }
    }
  }

  updateProfile() async {
    var result;
    _image = await _provider.profileImageCompress(_image);
    String imgtype = _image.path.split(".").last;
    print("IMAGE PATH>>> $imgtype");
    String fileName =
        DateFormat('yyyyMMddHHmmssms').format(DateTime.now()) + "." + imgtype;
    print("IMAGE Name>>> $fileName");
    // AwsS3 awsS3 = AwsS3(
    //     awsFolderPath: "user/" + fileName,
    //     file: _image,
    //     fileNameWithExt: fileName,
    //     poolId: "ap-southeast-1:72ec8e98-ec7c-4b40-83dd-3cd84ac6fd6e",
    //     region: Regions.AP_SOUTHEAST_1,
    //     bucketName: _apiurl.s3Bucket);

    // result = await awsS3.uploadFile
    //     .timeout(Duration(seconds: 60))
    //     .catchError((error) {
    //   _showSnackBar(error.toString());
    // });
    // final minio = Minio(
    //   endPoint: 's3.amazonaws.com',
    //   accessKey: 'AKIA3BVTPPNYY5TX4AXZ',
    //   secretKey: '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',
    // );

    // await minio.putObject(
    //   _apiurl.s3Bucket,
    //   "user/" + fileName,
    //   Stream<Uint8List>.value(Uint8List(720)),
    //   onProgress: (bytes) => print('$bytes uploaded'),
    // );

    result = await AwsS3.uploadFile(
        accessKey: _apiurl.s3Access,
        secretKey: _apiurl.s3Secret,
        file: _image,
        filename: fileName,
        destDir: "user",
        bucket: _apiurl.s3Bucket,
        region: _apiurl.s3Region);

    print("UP>>>$result");

    if (result == null) {
      setState(() {
        Navigator.pop(context);
        _showSnackBar("Try again!");
      });
    } else {
      updateUser(fileName);
    }
  }

  List _arrayTab = [];
  gotoHome() async {
    final prefs = await SharedPreferences.getInstance();
    // var _arrayTab = _provider.getJsonDecrypt(prefs.getString('menulist'));
    // Navigator.pop(context);
    // Navigator.of(context).pop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TabsPage(
          openTab: 4,
          tabsLists: _arrayTab,
        ),
      ),
    );
  }

  // getImage(_type) async {
  //   var filePath;
  //   File image;
  //   if (_type == "camera") {
  //     filePath = await Navigator.push(
  //         context, MaterialPageRoute(builder: (context) => Camera()));
  //     // filePath = await ImagePicker.pickImage(source: ImageSource.camera);
  //   } else {
  //     PermissionStatus permissionStatus =
  //         await GalleryPermission().galleryPermission(context);
  //     if (permissionStatus == PermissionStatus.granted) {
  //       filePath = await ImagePicker.pickImage(source: ImageSource.gallery);
  //     }
  //   }

  //   if (filePath != null) {
  //     image = await FlutterExifRotation.rotateImage(path: filePath.path);
  //     cropImage(image);
  //     setState(() {});
  //   }
  // }

  getImage(_type) async {
    var filePath;
    File image;
    if (_type == "camera") {
      PermissionStatus permissionStatus =
          await CameraPermission().cameraPermission(context);
      if (permissionStatus == PermissionStatus.granted) {
        // filePath = await Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => Camera()));
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CameraCamera(onFile: (file) {
                      filePath = file;
                      Navigator.pop(context);
                      setState(() {});
                    })));
      }
      // filePath = await ImagePicker.pickImage(source: ImageSource.camera);
    } else {
      PermissionStatus permissionStatus =
          await GalleryPermission().galleryPermission(context);
      if (permissionStatus == PermissionStatus.granted) {
        filePath = await picker.getImage(source: ImageSource.gallery);
        // filePath = await ImagePicker.pickImage(source: ImageSource.gallery);
      }
    }

    if (filePath != null) {
      image = await FlutterExifRotation.rotateImage(path: filePath.path);
      cropImage(image);
      setState(() {});
    }
  }

  cropImage(File filepath) async {
    File cropped = await ImageCropper().cropImage(
      androidUiSettings: AndroidUiSettings(
          toolbarColor: Colors.grey[200],
          toolbarTitle: "Crop Image",
          toolbarWidgetColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      iosUiSettings: IOSUiSettings(
        title: "Crop Image",
        minimumAspectRatio: 1.0,
      ),
      sourcePath: filepath.path,
      cropStyle: CropStyle.circle,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
            ]
          : [
              CropAspectRatioPreset.square,
            ],
    );
    if (cropped != null) {
      setState(() {
        _image = cropped;
        changeImage = true;
        // _uploadFile(_image);
      });
    } else {
      // _image = filepath;
      // Navigator.pop(context);
    }
  }

  goActionSheet() {
    final action = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: 10),
        ListTile(
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 1.5,
                color: Colors.white,
              ),
              color: Colors.grey[300],
            ),
            child: Icon(
              Icons.camera_alt,
              color: Colors.black54,
              size: 20,
            ),
          ),
          title: Text(
            'Camera',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            getImage("camera");
          },
        ),
        ListTile(
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 1.5,
                color: Colors.white,
              ),
              color: Colors.grey[300],
            ),
            child: Icon(
              Icons.photo_library_rounded,
              color: Colors.black54,
              size: 20,
            ),
          ),
          title: Text(
            'Gallery',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            getImage("gallery");
          },
        ),
        SizedBox(height: 20),
      ],
    );
    showModalBottomSheet(
      context: context,
      builder: (context) => action,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0), topRight: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.white,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  goBackSaveData() async {
    LoadingPage.showLoadingDialog(context, _keyLoader);
    if (changeImage) {
      await updateProfile();
    } else {
      await updateUser("");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem> divisionList = _divisionLst
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      val,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(width: 10),
                    _selectDivision == val
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                            size: 15,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            size: 15,
                          ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList();

    List<DropdownMenuItem> regionList = _regionLst
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      val,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(width: 10),
                    _selectRegion == val
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                            size: 15,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            size: 15,
                          ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList();

    List<DropdownMenuItem> townshipList = _townshipLst
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      val,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(width: 10),
                    _selectTownship == val
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                            size: 15,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            size: 15,
                          ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList();

    return WillPopScope(
      onWillPop: () async {
        goBackSaveData();
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          iconTheme: IconThemeData(color: mainColor),
          automaticallyImplyLeading: true,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Profile",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    fontSize: 20,
                  ),
                ),
                (_domainData.length > 0)
                    ? Container(
                        padding: EdgeInsets.only(left: 5),
                        child: Image(
                          image: AssetImage("assets/images/admin.png"),
                          height: 20,
                          width: 20,
                          color: mainColor,
                        ),
                      )
                    : Container(),
              ],
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
        ),
        body: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                children: <Widget>[
                  Center(
                    child: Stack(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            goActionSheet();
                          },
                          child: Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                ),
                                child: (changeImage)
                                    ? Image.file(_image)
                                    : (_userData['imagename'] != "" &&
                                            _userData['imagename'] != null)
                                        ? CachedNetworkImage(
                                            imageUrl: _userData['imagename'],
                                            placeholder: (context, url) =>
                                                Image(
                                              image: AssetImage(
                                                  "assets/images/man.png"),
                                              height: 110,
                                              width: 110,
                                              color: Colors.grey,
                                            ),
                                            height: 110,
                                            width: 110,
                                            fit: BoxFit.cover,
                                          )
                                        : Image(
                                            image: AssetImage(
                                                "assets/images/man.png"),
                                            height: 110,
                                            width: 110,
                                            color: Colors.grey,
                                          ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () {
                              goActionSheet();
                            },
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
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.only(right: 20, left: 20, bottom: 10),
                    child: Text(
                      "Name",
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                        controller: nameController,
                        keyboardType: TextInputType.text,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        right: 20, left: 20, top: 10, bottom: 10),
                    child: Text(
                      "Email or Mobile",
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                        readOnly: true,
                        autofocus: false,
                        controller: phoneController,
                        keyboardType: TextInputType.text,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  (showMore)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                  right: 20, left: 20, top: 10, bottom: 10),
                              child: Text(
                                "NRC",
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                                  controller: nrcController,
                                  keyboardType: TextInputType.text,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(0),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                  right: 20, left: 20, top: 10, bottom: 10),
                              child: Text(
                                "State",
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20, left: 20),
                              padding: EdgeInsets.only(left: 10),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  color: mainColor,
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    _selectDivision,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  iconSize: 24,
                                  elevation: 1,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectDivision = newValue;
                                      var index =
                                          _divisionLst.indexOf(newValue);
                                      _divisionID =
                                          _divisionList[index]['divId'];
                                      getRegion(index);
                                    });
                                  },
                                  items: divisionList,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                  right: 20, left: 20, top: 10, bottom: 10),
                              child: Text(
                                "Region",
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20, left: 20),
                              padding: EdgeInsets.only(left: 10),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  color: mainColor,
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    _selectRegion,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  iconSize: 24,
                                  elevation: 1,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectRegion = newValue;
                                      var index = _regionLst.indexOf(newValue);
                                      getTownship(index);
                                    });
                                  },
                                  items: regionList,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                  right: 20, left: 20, top: 10, bottom: 10),
                              child: Text(
                                "Township",
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20, left: 20),
                              padding: EdgeInsets.only(left: 10),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  color: mainColor,
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    _selectTownship,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  iconSize: 24,
                                  elevation: 1,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectTownship = newValue;
                                      var index =
                                          _townshipLst.indexOf(newValue);
                                      _townshipID =
                                          _townshipList[index]['tsId'];
                                      debugPrint(_townshipID);
                                    });
                                  },
                                  items: townshipList,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                  right: 20, left: 20, top: 10, bottom: 10),
                              child: Text(
                                "Address",
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: _fontFamily,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20, left: 20),
                              padding: EdgeInsets.only(left: 10, right: 10),
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  color: mainColor,
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                controller: addressController,
                                maxLines: 8,
                                autofocus: false,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(),
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        showMore = !showMore;
                        prefs.setString('showmore_profile',
                            _provider.setEncrypt(showMore.toString()));
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 20, left: 20, top: 10),
                      child: Text(
                        showMore ? "Show less (-)" : "Show more (+)",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontFamily: _fontFamily,
                        ),
                      ),
                    ),
                  ),
                  _orgList.isEmpty
                      ? Container()
                      : Container(
                          margin: EdgeInsets.only(
                              right: 20, left: 20, top: 10, bottom: 10),
                          child: Text(
                            "Marchant",
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                            ),
                          ),
                        ),
                  Container(
                    margin:
                        EdgeInsets.only(right: 20, left: 20, top: 5, bottom: 0),
                    child: Column(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: EdgeInsets.all(0),
                          itemCount: _orgList.length,
                          itemBuilder: (context, i) {
                            return InkWell(
                              onTap: () {},
                              onLongPress: () {},
                              child: Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding:
                                              (_orgList[i]['imageurl'] != "" &&
                                                      _orgList[i]['imageurl'] !=
                                                          null)
                                                  ? EdgeInsets.all(0)
                                                  : EdgeInsets.all(7.5),
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color: Colors.grey[300],
                                          ),
                                          child: (_orgList[i]['imageurl'] !=
                                                      "" &&
                                                  _orgList[i]['imageurl'] !=
                                                      null)
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  child: CachedNetworkImage(
                                                    imageUrl: _orgList[i]
                                                        ['imageurl'],
                                                    placeholder:
                                                        (context, url) => Image(
                                                      image: AssetImage(
                                                          "assets/images/profile_orgadmin.png"),
                                                      height: 35,
                                                      width: 35,
                                                      color: Colors.black54,
                                                    ),
                                                    height: 35,
                                                    width: 35,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Image(
                                                  image: AssetImage(
                                                      "assets/images/profile_orgadmin.png"),
                                                  height: 35,
                                                  width: 35,
                                                  color: Colors.black54,
                                                ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {},
                                            child: Container(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 10),
                                                        constraints:
                                                            BoxConstraints(
                                                          minWidth: 50,
                                                          maxWidth: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.50,
                                                        ),
                                                        child: Text(
                                                          "${_orgList[i]["name"]}",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontFamily:
                                                                _fontFamily,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 5),
                                                        child: Image(
                                                          image: AssetImage(
                                                              "assets/images/admin.png"),
                                                          height: 20,
                                                          width: 20,
                                                          color: mainColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
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
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
