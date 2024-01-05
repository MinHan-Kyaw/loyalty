import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingPage {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
            key: key,
            backgroundColor: Colors.white,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation(Colors.grey),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      Text(
                        "Please Wait....",
                        style: TextStyle(color: Colors.grey, fontSize: 18.0),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static Future<void> showLoadingAnimationDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
            key: key,
            backgroundColor: Colors.white,
            children: <Widget>[
              Center(
                child: Container(
                  child: Column(
                    children: [
                      // SizedBox(
                      //   width: 30,
                      //   height: 30,
                      //   child: CircularProgressIndicator(
                      //     strokeWidth: 2.0,
                      //     valueColor: AlwaysStoppedAnimation(Colors.grey),
                      //   ),
                      // ),
                      // SizedBox(
                      //   width: 30,
                      // ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            margin: EdgeInsets.only(bottom: 10),
                            child: Image(
                              // image: AssetImage("assets/images/boxopen.gif"),
                              image:
                                  AssetImage("assets/images/lucky-wheel.gif"),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Please wait..",
                        style: TextStyle(color: Colors.grey, fontSize: 18.0),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static Future<void> showLoadingCouponAnimationDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
            key: key,
            backgroundColor: Colors.white,
            children: <Widget>[
              Center(
                child: Container(
                  child: Column(
                    children: [
                      // SizedBox(
                      //   width: 30,
                      //   height: 30,
                      //   child: CircularProgressIndicator(
                      //     strokeWidth: 2.0,
                      //     valueColor: AlwaysStoppedAnimation(Colors.grey),
                      //   ),
                      // ),
                      // SizedBox(
                      //   width: 30,
                      // ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Container(
                          //   padding: EdgeInsets.all(15),
                          //   child: LoadingAnimationWidget.inkDrop(
                          //     color: Color(0xFF0498D4),
                          //     size: 50,
                          //   ),
                          // ),
                          Container(
                            height: 150,
                            width: 150,
                            margin: EdgeInsets.only(bottom: 10),
                            child: Image(
                              image: AssetImage("assets/images/checkcoupon.gif"),
                              // image:
                              //     AssetImage("assets/images/lucky-wheel.gif"),
                            ),
                          ),
                          // Container(
                          //   height: 150,
                          //   width: 150,
                          //   margin: EdgeInsets.only(bottom: 10),
                          //   child: Image(
                          //     // image: AssetImage("assets/images/boxopen.gif"),
                          //     image: AssetImage("assets/images/checkcoupon.gif"),
                          //   ),
                          // ),
                        ],
                      ),
                      Text(
                        "Please wait..",
                        style: TextStyle(color: Colors.grey, fontSize: 18.0),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
