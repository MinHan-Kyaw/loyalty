import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loyalty/functionProvider.dart';
import 'package:loyalty/style.dart';

class RedeemDialog extends StatefulWidget {
  final wonprizes;
  RedeemDialog(this.wonprizes);
  @override
  _RedeemDialogState createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<RedeemDialog> {
  ScrollController _scrollController = ScrollController();
  final _provider = FunctionProvider();

  String _fontfamily = "Ubuntu";
  Color mainColor = Style().primaryColor;

  List _wonpriceList = [];
  int _index = 0;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  getData() async {
    for (var i = 0; i < widget.wonprizes.length; i++) {
      if (!widget.wonprizes[i]['redeemed']) {
        _wonpriceList.add(widget.wonprizes[i]);
      }
    }
    setState(() {});
  }

  _textWonPrice(price, type) {
    bool checkNum = _provider.isNumeric(price);
    if (checkNum && type == "002") {
      return formatter.format(int.parse(price)).toString();
    } else {
      return price;
    }
  }

  displayLogout(context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          elevation: 24.0,
          title: Text(
            "Choose Prize",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontFamily: _fontfamily,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height / 5,
              maxHeight: MediaQuery.of(context).size.height / 3,
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _wonpriceList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.all(0),
                  onTap: () {
                    Navigator.pop(context, index);
                  },
                  title: Container(
                    child: Row(
                      children: <Widget>[
                        Theme(
                          data: ThemeData(
                            unselectedWidgetColor: Colors.black,
                          ),
                          child: Checkbox(
                            value: (_wonpriceList[index]['primarykey'] ==
                                    _wonpriceList[_index]['primarykey'])
                                ? true
                                : false,
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                            onChanged: (bool value) {
                              Navigator.pop(context, index);
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _textWonPrice(_wonpriceList[index]['price'],
                                _wonpriceList[index]['instanttype']),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontfamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.only(left: 10, right: 10, top: 20),
      elevation: 24.0,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(left: 15),
              child: Text(
                "Redeem following item?",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontfamily,
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.all(0),
              onTap: () async {
                if (_wonpriceList.length > 1) {
                  var index = await displayLogout(context);
                  if (index != null) {
                    _index = index;
                  }
                }
                setState(() {});
              },
              title: Container(
                child: Row(
                  children: <Widget>[
                    Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.black,
                      ),
                      child: Checkbox(
                        value: true,
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        onChanged: (bool value) {},
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _textWonPrice(_wonpriceList[_index]['price'],
                            _wonpriceList[_index]['instanttype']),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: _fontfamily,
                        ),
                      ),
                    ),
                    (_wonpriceList.length > 1)
                        ? Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                            size: 20,
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'No',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              Navigator.pop(context, _wonpriceList[_index]['primarykey']);
            });
          },
          child: Text(
            'Yes',
            style: TextStyle(
              color: mainColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
