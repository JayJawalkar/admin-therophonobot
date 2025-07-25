import 'package:flutter/material.dart';

class DisplayInternetImage extends StatefulWidget {
  const DisplayInternetImage({super.key});

  @override
  State<DisplayInternetImage> createState() => _DisplayInternetImageState();
}

class _DisplayInternetImageState extends State<DisplayInternetImage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Image.network('https://images.pexels.com/photos/733853/pexels-photo-733853.jpeg',height: 100,width: 200,),
    );
  }
}

