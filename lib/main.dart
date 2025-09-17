import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/home_desktop_page.dart';
import 'package:hitch_tracker/src/providers/main_menu_tabchange_provider.dart';
import 'package:hitch_tracker/src/res/app_constants.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_)=> MainMenUTabChangeProvider())
  ], child: const MyApp(),));
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
        fontFamily: appFontFamilyMontserrat,
        scaffoldBackgroundColor: Colors.white
      ),
      home: Scaffold(
        body: HomeDesktopPage()
      )
    );
  }
}
