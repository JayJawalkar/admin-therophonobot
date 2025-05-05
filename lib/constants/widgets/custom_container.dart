import 'package:flutter/material.dart';

Widget customContainer({
  Key? key,
  double? height,
  double? imageOpacity,
  double? width,
  Color? containerColor,
  Color? borderColor,
  required double bRadius,
  double? hPadding,
  double? vPadding,
  double? hMargin,
  double? vMargin,
  String? assetsImg,
  String? networkImg,
  Color? shadowColor,
  double? shadowBlurRadius,
  Offset? shadowOffset,
  Gradient? gradient,
  Widget? child,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      key: key,
      height: height,
      width: width,
      margin: EdgeInsets.symmetric(
          vertical: vMargin ?? 0, horizontal: hMargin ?? 0),
      padding: EdgeInsets.symmetric(
          horizontal: hPadding ?? 0.0, vertical: vPadding ?? 0.0),
      decoration: BoxDecoration(
        color: gradient == null ? containerColor ?? Colors.white : null,
        gradient: gradient,
        border:
            Border.all(color: borderColor ?? Colors.grey.shade100, width: 0.5),
        borderRadius: BorderRadius.circular(bRadius),
        image: (networkImg != null)
            ? DecorationImage(
                image: NetworkImage(networkImg),
                fit: BoxFit.scaleDown,
                opacity: imageOpacity ?? 1.0)
            : (assetsImg != null)
                ? DecorationImage(
                    image: AssetImage(
                      assetsImg,
                    ),
                    fit: BoxFit.cover,
                    opacity: imageOpacity ?? 1.0)
                : null,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.transparent,
            blurRadius: shadowBlurRadius ?? 1.0,
            offset: shadowOffset ?? const Offset(0.5, 0.5),
          ),
        ],
      ),
      child: child,
    ),
  );
}