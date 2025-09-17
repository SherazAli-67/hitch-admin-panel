import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/home_desktop_page.dart';
import 'package:hitch_tracker/src/res/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        fontFamily: appFontFamilyMontserrat
      ),
      home: Scaffold(
        body: HomeDesktopPage()
      )
    );
  }
}
