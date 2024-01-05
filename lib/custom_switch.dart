import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final String activeText;
  final String inactiveText;
  final Color activeTextColor;
  final Color inactiveTextColor;

  const CustomSwitch(
      {Key key,
      this.value,
      this.onChanged,
      this.activeColor,
      this.inactiveColor,
      this.activeText,
      this.inactiveText,
      this.activeTextColor,
      this.inactiveTextColor})
      : super(key: key);

  @override
  _CustomSwitchState createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  Animation _circleAnimation;
  AnimationController _animationController;

  String _fontFamily = "Ubuntu";

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 60));
    _circleAnimation = AlignmentTween(
            begin: widget.value ? Alignment.centerRight : Alignment.centerLeft,
            end: widget.value ? Alignment.centerLeft : Alignment.centerRight)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.linear));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (_animationController.isCompleted) {
              _animationController.reverse();
            } else {
              _animationController.forward();
            }
            widget.value == false
                ? widget.onChanged(true)
                : widget.onChanged(false);
          },
          child: Container(
            width: 55.0,
            height: 25.0,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: _circleAnimation.value == Alignment.centerLeft
                    ? widget.inactiveColor
                    : widget.activeColor),
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 2.0, bottom: 2.0, right: 3.0, left: 3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _circleAnimation.value == Alignment.centerRight
                      ? Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              widget.activeText,
                              style: TextStyle(
                                color: widget.activeTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.0,
                                fontFamily: _fontFamily,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                        ),
                  Align(
                    alignment: _circleAnimation.value,
                    child: Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _circleAnimation.value == Alignment.centerLeft
                      ? Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              widget.inactiveText,
                              style: TextStyle(
                                color: widget.inactiveTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.0,
                                fontFamily: _fontFamily,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
