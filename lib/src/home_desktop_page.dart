import 'package:flutter/material.dart';

class HomeDesktopPage extends StatelessWidget{
  const HomeDesktopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text("Home Page Desktop"),)),
    );
  }

}