import 'package:admin_therophonobot/constants/images/image_constants.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
   final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double elevation;
  final Widget? leading;
  final bool centerTitle;
  final double? titleSpacing;
  final TextStyle? titleTextStyle;
  final double? toolbarHeight;

  const CustomAppBar({
    super.key,
     this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.textColor,
    this.elevation = 0,
    this.leading,
    this.centerTitle = true,
    this.titleSpacing,
    this.titleTextStyle,
    this.toolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double height=MediaQuery.of(context).size.height;
    final double width=MediaQuery.of(context).size.width;

    final theme = Theme.of(context);
    
    return AppBar(
      
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(ImageConstants.appLogo,height: height*0.1,width: width*0.1,),
          SizedBox(width: width*0.02,),
          Text(
            title??'Therophonobot',
            style: titleTextStyle ?? TextStyle(
              color: textColor ?? theme.colorScheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      leading: showBackButton
          ? (leading ?? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: textColor ?? theme.colorScheme.onPrimary,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ))
          : null,
      actions: actions,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight ?? kToolbarHeight,
      iconTheme: IconThemeData(
        color: textColor ?? theme.colorScheme.onPrimary,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);
}

// For transparent app bars (useful for images behind)
class TransparentAppBar extends CustomAppBar {
  const TransparentAppBar({
    super.key,
    required super.title,
    super.showBackButton = true,
    super.actions,
    super.onBackPressed,
    super.textColor = Colors.white,
    super.leading,
    super.centerTitle = true,
    super.titleTextStyle,
  }) : super(
          backgroundColor: Colors.transparent,
          elevation: 0,
        );
}

// For secondary screens with back button
class SecondaryAppBar extends CustomAppBar {
  const SecondaryAppBar({
    super.key,
    required super.title,
    super.actions,
    super.onBackPressed,
    super.textColor,
    super.leading,
    super.centerTitle = true,
    super.titleTextStyle,
  }) : super(
          showBackButton: true,
          elevation: 1,
        );
}

// For main screens without back button
class MainAppBar extends CustomAppBar {
  const MainAppBar({
    super.key,
    required super.title,
    super.actions,
    super.textColor,
    super.centerTitle = true,
    super.titleTextStyle,
  }) : super(
          showBackButton: false,
          elevation: 1,
        );
}