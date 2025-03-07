import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sideswap/common/screen_utils.dart';

class SwitchButton extends StatefulWidget {
  const SwitchButton({
    Key? key,
    this.backgroundColor = const Color(0xFF043857),
    this.borderRadius = 8,
    this.width = 142,
    this.height = 35,
    required this.value,
    this.onToggle,
    this.borderColor = const Color(0xFF043857),
    this.borderWidth = 2,
    this.activeToggle,
    this.inactiveToggle,
    this.activeToggleBackground = const Color(0xFF1B8BC8),
    this.inactiveToggleBackground = const Color(0xFF043857),
    this.activeText = '',
    this.inactiveText = '',
    this.activeTextStyle,
    this.inactiveTextStyle,
  }) : super(key: key);

  final double width;
  final double height;
  final Color backgroundColor;
  final double borderRadius;
  final bool value;
  final void Function(bool)? onToggle;
  final Color borderColor;
  final double borderWidth;
  final Widget? activeToggle;
  final Widget? inactiveToggle;
  final Color activeToggleBackground;
  final Color inactiveToggleBackground;
  final String activeText;
  final String inactiveText;
  final TextStyle? activeTextStyle;
  final TextStyle? inactiveTextStyle;

  @override
  _SwitchButtonState createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  final defaultActiveTextStyle = GoogleFonts.roboto(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  final defaultInactiveTextStyle = GoogleFonts.roboto(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF78AECC),
  );

  late double switchWidth = (widget.width - 3 * widget.borderWidth) / 2;
  late double switchHeight = widget.height - 2 * widget.borderWidth;
  bool disabled = false;

  @override
  void initState() {
    super.initState();
    disabled = widget.onToggle == null;
  }

  @override
  void didUpdateWidget(SwitchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onToggle != widget.onToggle) {
      disabled = widget.onToggle == null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var activeTextStyle = (disabled
            ? widget.activeTextStyle?.copyWith(
                color: widget.activeTextStyle?.color?.withOpacity(0.2))
            : widget.activeTextStyle) ??
        (disabled
            ? defaultActiveTextStyle.copyWith(color: const Color(0xFF78AECC))
            : defaultActiveTextStyle);
    Widget defaultActiveToggle = Container(
      width: switchWidth,
      height: switchHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
            Radius.circular(widget.borderRadius - widget.borderWidth)),
        color: disabled
            ? const Color(0xFF1B8BC8).withOpacity(0.2)
            : widget.activeToggleBackground,
      ),
      child: Center(
        child: Text(
          widget.value ? widget.activeText : widget.inactiveText,
          style: activeTextStyle,
        ),
      ),
    );

    Widget defaultInactiveToggle = Container(
      width: switchWidth,
      height: switchHeight,
      color: widget.inactiveToggleBackground,
      child: Center(
        child: Text(
          widget.value ? widget.inactiveText : widget.activeText,
          style: widget.inactiveTextStyle ?? defaultInactiveTextStyle,
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        if (!disabled && widget.onToggle != null) {
          widget.onToggle!(!widget.value);
        }
      },
      child: Opacity(
        opacity: disabled ? 1 : 1,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(
              width: widget.borderWidth,
              color: widget.borderColor,
            ),
            borderRadius:
                BorderRadius.all(Radius.circular(widget.borderRadius)),
            color: widget.backgroundColor,
          ),
          child: Row(
            children: [
              if (widget.value) ...[
                widget.inactiveToggle ?? defaultInactiveToggle,
                const Spacer(),
                widget.activeToggle ?? defaultActiveToggle,
              ] else ...[
                widget.activeToggle ?? defaultActiveToggle,
                const Spacer(),
                widget.inactiveToggle ?? defaultInactiveToggle,
              ]
            ],
          ),
        ),
      ),
    );
  }
}
