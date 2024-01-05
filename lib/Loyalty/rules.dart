import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../style.dart';

class Rules extends StatefulWidget {
  const Rules({Key key}) : super(key: key);

  @override
  State<Rules> createState() => _RulesState();
}

class _RulesState extends State<Rules> {
  Color mainColor = Style().primaryColor;
  String _fontFamily = "Ubuntu";
  bool _loading = true;
  InAppWebViewController webView;
  String url = "";

  var options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: false,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    // print(widget.url);
    getData();
  }

  getData() async {
  //   setState(() {
      // url = 'https://www.google.com';
  //     // Future.delayed(Duration(seconds: 1), () {
        url = 'https://www.nexxus.app/rules';
  //     // });

      // webView.loadUrl(urlRequest: URLRequest(url: Uri.parse('https://www.nexxus.app/rules')));
  //   });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    // _dropdownMenuController.dispose();
    webView.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Rules",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _loading
              ? LinearProgressIndicator(
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                )
              : Container(),
          // onError
          //     ? Container(
          //         margin: EdgeInsets.only(top: 20.0),
          //         child: Text(
          //           "No Connection!",
          //           style: TextStyle(
          //               color: Colors.black26,
          //               fontSize: 20.0,
          //               fontWeight: FontWeight.bold),
          //         ),
          //       )
          //     :
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: Uri.parse(url)),
              initialOptions: options,
              androidOnPermissionRequest: (InAppWebViewController controller,
                  String origin, List<String> resources) async {
                return PermissionRequestResponse(
                    resources: resources,
                    action: PermissionRequestResponseAction.GRANT);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;
                if (![
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about"
                ].contains(uri.scheme)) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  webView = controller;
                  _loading = false;
                });
              },
              onWebViewCreated: (controller) {
                setState(() {
                  webView = controller;
                });
              },
              // onUpdateVisitedHistory: (controller, url, androidIsReload) {
              //   setState(() {
              //     if (url.toString() == 'https://www.khub.cloud/home') {
              //       urls = 1;
              //     } else {
              //       urls = urls + 1;
              //     }
              //   });
              // },
              onConsoleMessage: (controller, consoleMessage) {
                //print(consoleMessage);
              },
            ),
          )
        ],
      ),
    );
  }
}
