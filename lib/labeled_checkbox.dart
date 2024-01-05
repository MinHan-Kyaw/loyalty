import 'package:loyalty/style.dart';
import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox(
      {Key key,
      this.label,
      this.padding,
      this.value,
      this.onChanged,
      this.textStyle})
      : super(key: key);

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    showDetail() {
      showDialog(
        context: context,
        builder: (_context) => AlertDialog(
          contentPadding:
              EdgeInsets.only(left: 5, right: 15, top: 20, bottom: 20),
          content: GestureDetector(
            onTap: () {
              onChanged(!value);
              Navigator.of(context).pop();
            },
            child: Row(
              children: <Widget>[
                Checkbox(
                  activeColor: Style().primaryColor,
                  value: value,
                  onChanged: (bool newValue) {
                    onChanged(newValue);
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: Text(
                    label,
                    style: textStyle == null
                        ? TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Ubuntu",
                          )
                        : textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      onDoubleTap: () {
        showDetail();
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Checkbox(
              activeColor: Style().primaryColor,
              value: value,
              onChanged: (bool newValue) {
                onChanged(newValue);
              },
            ),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: textStyle == null
                    ? TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Ubuntu",
                      )
                    : textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
