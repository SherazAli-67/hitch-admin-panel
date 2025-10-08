import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/features/chats_triggered_page.dart';
import 'package:hitch_tracker/src/features/dashboard_page.dart';
import 'package:hitch_tracker/src/features/requested_hitches_page.dart';
import 'package:hitch_tracker/src/features/accepted_hitch_users.dart';
import 'package:hitch_tracker/src/features/users_by_state.dart';
import 'package:hitch_tracker/src/providers/main_menu_tabchange_provider.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:hitch_tracker/src/res/string_constants.dart';
import 'package:provider/provider.dart';

class HomeDesktopPage extends StatefulWidget{
  const HomeDesktopPage({super.key});

  @override
  State<HomeDesktopPage> createState() => _HomeDesktopPageState();
}

class _HomeDesktopPageState extends State<HomeDesktopPage> {
  // Create widget instances once and keep them alive
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize all page widgets once
    _pages = [
      DashboardPage(),
      RequestedHitchesPage(),
      AcceptedHitchRequestsPage(),
      ChatsTriggeredPage(),
      UsersByState()
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 1,
        children: [
          Card(
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hitch", style: AppTextStyles.titleTextStyle,),
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(willPartonImageUrl),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<MainMenUTabChangeProvider>(
                builder: (_, provider, _) {
                  int selectedIndex = provider.currentIndex;
                  bool isExpanded = provider.isMenuExpanded;
                  int hoveredIndex = provider.hoveredIndex;
                  
                  return Row(
                    spacing: 20,
                    children: [
                      MouseRegion(
                        onEnter: (_) => provider.setMenuExpanded(true),
                        onExit: (_) {
                          provider.setMenuExpanded(false);
                          provider.clearHover();
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: isExpanded ? 250 : 75,
                          height: double.infinity,
                          child: Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 5,
                                children: [
                                  _buildMenuItemWidget(
                                    icon: Icons.home_outlined, 
                                    title: "Dashboard", 
                                    tabIndex: 0, 
                                    selectedIndex: selectedIndex, 
                                    provider: provider,
                                    isExpanded: isExpanded,
                                    isHovered: hoveredIndex == 0
                                  ),
                                  _buildMenuItemWidget(
                                    icon: Icons.person, 
                                    title: "Requested Hitches", 
                                    tabIndex: 1, 
                                    selectedIndex: selectedIndex, 
                                    provider: provider,
                                    isExpanded: isExpanded,
                                    isHovered: hoveredIndex == 1
                                  ),
                                  _buildMenuItemWidget(
                                    icon: Icons.request_page, 
                                    title: "Accepted Hitches", 
                                    tabIndex: 2, 
                                    selectedIndex: selectedIndex, 
                                    provider: provider,
                                    isExpanded: isExpanded,
                                    isHovered: hoveredIndex == 2
                                  ),
                                  _buildMenuItemWidget(
                                    icon: Icons.chat_bubble_outline_rounded, 
                                    title: "Chats", 
                                    tabIndex: 3, 
                                    selectedIndex: selectedIndex, 
                                    provider: provider,
                                    isExpanded: isExpanded,
                                    isHovered: hoveredIndex == 3
                                  ),
                                  _buildMenuItemWidget(
                                      icon: Icons.language,
                                      title: "Users by state",
                                      tabIndex: 4,
                                      selectedIndex: selectedIndex,
                                      provider: provider,
                                      isExpanded: isExpanded,
                                      isHovered: hoveredIndex == 4
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _buildMenuPageWidget(selectedIndex))
                    ],
                  );
                }
            ),
          ),
        ],
      ),),
    );
  }

  Widget _buildMenuItemWidget({
    required IconData icon, 
    required String title, 
    required int selectedIndex, 
    required int tabIndex, 
    required MainMenUTabChangeProvider provider,
    required bool isExpanded,
    required bool isHovered
  }) {
    bool isSelected = tabIndex == selectedIndex;
    
    return MouseRegion(
      onEnter: (_) => provider.setHoveredIndex(tabIndex),
      onExit: (_) => provider.clearHover(),
      child: GestureDetector(
        onTap: () => provider.onTabChange(tabIndex),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryColor.withValues(alpha: 0.1) 
                : isHovered 
                    ? Colors.grey.withValues(alpha: 0.05)
                    : null,
            borderRadius: isSelected || isHovered 
                ? BorderRadius.circular(8) 
                : BorderRadius.zero
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isSelected ? AppColors.primaryColor : Colors.black54,
                size: 22,
              ),
              if (isExpanded) ...[
                SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 250),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: Text(
                      title,
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: isSelected ? AppColors.primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: Duration(milliseconds: 200),
                  opacity: isHovered ? 1.0 : 0.0,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black54,
                    size: 14,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuPageWidget(int selectedIndex) {
    return IndexedStack(
      index: selectedIndex,
      children: _pages,
    );
  }

}
