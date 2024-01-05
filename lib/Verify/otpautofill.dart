import 'package:flutter/material.dart';
import 'package:loyalty/style.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_autofill/sms_autofill.dart';

class PinCodeTextFieldAutoFill extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onCompleted;
  final Function(String) onChanged;
  const PinCodeTextFieldAutoFill(
      {Key key, this.controller, this.onCompleted, this.onChanged})
      : super(key: key);
  @override
  _PinCodeTextFieldAutoFillState createState() =>
      _PinCodeTextFieldAutoFillState();
}

class _PinCodeTextFieldAutoFillState extends State<PinCodeTextFieldAutoFill>
    with CodeAutoFill {
  TextEditingController controller;
  String appSignature;

  Color mainColor = Style().primaryColor;
  bool _shouldDisposeController;

  @override
  void codeUpdated() {
    if (controller.text != code) {
      controller.value = TextEditingValue(text: code ?? '');
      if (widget.onChanged != null) {
        widget.onChanged(code ?? '');
      }
    }
    // setState(() {
    //   otptextController.text = code;
    // });
  }

  @override
  void initState() {
    super.initState();
    _shouldDisposeController = widget.controller == null;
    controller = widget.controller ?? TextEditingController(text: '');
    codeUpdated();
    controller.addListener(() {
      if (controller.text != code) {
        code = controller.text;
        // if (widget.onCodeChanged != null) {
        //   widget.onCodeChanged(code);
        // }
      }
    });
    listenForCode();

    SmsAutoFill().getAppSignature.then((signature) {
      setState(() {
        appSignature = signature;
      });
    });
  }

  @override
  void dispose() {
    if (_shouldDisposeController) {
      controller.dispose();
    }
    super.dispose();
    // cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      mainAxisAlignment: MainAxisAlignment.center,
      appContext: context,
      controller: controller,
      pastedTextStyle: TextStyle(
        color: mainColor,
        fontWeight: FontWeight.bold,
      ),
      length: 6,
      obscureText: false,
      obscuringCharacter: '*',
      blinkWhenObscuring: false,
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        fieldOuterPadding: EdgeInsets.all(2),
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(5),
        fieldHeight: 50,
        fieldWidth: 45,
        borderWidth: 1.5,
        inactiveColor: mainColor,
        activeColor: mainColor,
        activeFillColor: mainColor,
        selectedColor: mainColor,
      ),
      cursorColor: Colors.blue,
      animationDuration: Duration(milliseconds: 300),
      enableActiveFill: false,
      keyboardType: TextInputType.number,
      onCompleted: widget.onCompleted,
      onChanged: widget.onChanged,
      beforeTextPaste: (text) {
        return true;
      },
    );
  }
}