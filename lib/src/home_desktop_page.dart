import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';

class HomeDesktopPage extends StatelessWidget{
  const HomeDesktopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hitch Admin", style: AppTextStyles.largeTextStyle,),
                Text("Admin Dashboard", style: AppTextStyles.regularTextStyle.copyWith(color: Colors.grey),)
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  Column(
                    spacing: 20,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMenuItemWidget(icon: Icons.home_outlined, title: "Dashboard", onTap: (){}),
                      _buildMenuItemWidget(icon: Icons.person, title: "Users", onTap: (){}),
                      _buildMenuItemWidget(icon: Icons.request_page, title: "Requests", onTap: (){}),
                      _buildMenuItemWidget(icon: Icons.chat_bubble_outline_rounded, title: "Chats", onTap: (){}),

                    ],
                  )
                ],
              ),
            )
          ],
        ),
      )),
    );
  }

  Widget _buildMenuItemWidget({required IconData icon, required String title, required VoidCallback onTap}) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            // elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)
            ),
            foregroundColor: Colors.white,
            elevation: 0
        ),
        onPressed: () {}, child: Row(
      spacing: 10,
      children: [
        Icon(icon, color: Colors.black45,),
        Text(title,
          style: AppTextStyles.smallTextStyle.copyWith(color: Colors.black),)
      ],
    ));
  }

}