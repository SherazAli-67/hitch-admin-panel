import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/features/chats_page.dart';
import 'package:hitch_tracker/src/features/dashboard_page.dart';
import 'package:hitch_tracker/src/features/requests_page.dart';
import 'package:hitch_tracker/src/features/users_page.dart';
import 'package:hitch_tracker/src/providers/main_menu_tabchange_provider.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:provider/provider.dart';

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
              child: Consumer<MainMenUTabChangeProvider>(
                builder: (_, provider, _) {
                  int selectedIndex = provider.currentIndex;
                  return Row(
                    spacing: 20,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Column(
                          spacing: 20,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMenuItemWidget(icon: Icons.home_outlined, title: "Dashboard", onTap: (){}, tabIndex: 0, selectedIndex: selectedIndex, provider: provider),
                            _buildMenuItemWidget(icon: Icons.person, title: "Users", onTap: (){},  tabIndex: 1, selectedIndex: selectedIndex,  provider: provider),
                            _buildMenuItemWidget(icon: Icons.request_page, title: "Requests", onTap: (){},  tabIndex: 2, selectedIndex: selectedIndex,  provider: provider),
                            _buildMenuItemWidget(icon: Icons.chat_bubble_outline_rounded, title: "Chats", onTap: (){},  tabIndex: 3, selectedIndex: selectedIndex,  provider: provider),

                          ],
                        )
                      ),
                      Expanded(child: _buildMenuPageWidget(selectedIndex))
                    ],
                  );
                }
              ),
            )
          ],
        ),
      )),
    );
  }

  Widget _buildMenuItemWidget({required IconData icon, required String title, required VoidCallback onTap, required int selectedIndex, required int tabIndex, required MainMenUTabChangeProvider provider}) {
    bool isSelected = tabIndex == selectedIndex;
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? AppColors.textFieldFillColor : Colors.white,
            // elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)
            ),
            foregroundColor: Colors.white,
            elevation: 0
        ),
        onPressed: () => provider.onTabChange(tabIndex), child: Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black45,),
        Text(title,
          style: AppTextStyles.smallTextStyle.copyWith(color: Colors.black),)
      ],
    ));
  }

  _buildMenuPageWidget(int selectedIndex) {
    switch(selectedIndex){
      case 0:
        return DashboardPage();

      case 1:
        return UsersPage();

      case 2:
        return RequestsPage();

      case 3:
        return ChatsPage();
    }
  }

}