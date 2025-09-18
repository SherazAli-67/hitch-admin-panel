import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';

import '../widgets/table_item_widget.dart';

class DashboardPage extends StatelessWidget{
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 20,
          children: [
            Expanded(
              child: _buildInfoItemWidget(title: 'Users', value: 3544),
            ),
            Expanded(
              child: _buildInfoItemWidget(title: 'Requests', value: 2052),
            ),
            Expanded(
              child: _buildInfoItemWidget(title: 'Chats', value: 935),
            ),
          ],
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text("Users", style: AppTextStyles.headingTextStyle,),
              _buildSearchTextField(),
              _buildUsersList()

            ],
          ),
        )
      ],
    );
  }

  Expanded _buildUsersList() {
    return Expanded(child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)
              ),
              color: Colors.white,
              child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (ctx, index){
                    return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero
                          ),
                          // shadowColor: Colors.transparent
                          surfaceTintColor: Colors.white,
                          overlayColor: Colors.grey[300]
                        ),
                        onPressed: (){}, child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            spacing: 20,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                // backgroundImage: NetworkImage(''),
                                backgroundColor: AppColors.textFieldFillColor,
                                backgroundImage: CachedNetworkImageProvider('https://images.unsplash.com/photo-1758061607997-9acb866c12e3?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxmZWF0dXJlZC1waG90b3MtZmVlZHwxMXx8fGVufDB8fHx8fA%3D%3D'),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 5,
                                children: [
                                  Text("Sheraz Ali",style: AppTextStyles.regularTextStyle.copyWith(fontWeight: FontWeight.w600)),
                                  Text("San Francisco, CA", style: AppTextStyles.smallTextStyle,),
                                  Text("Passionate About Tennis and pickleball playing"),
                                  SizedBox(height: 10,),
                                  Row(
                                    spacing: 10,
                                    children: [
                                      _buildPlayerTypeItem(playerType: 'Pickleball'),
                                      _buildPlayerTypeItem(playerType: 'Tennis')
                                    ],
                                  )
                                ],
                              ),

                            ],
                          ),
                        ),
                        Container(
                          height: 1,
                          color: Colors.black12,
                        )
                      ],
                    ));
              }),
            ));
  }

  TextField _buildSearchTextField() {
    return TextField(
             decoration: InputDecoration(
               enabledBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(10),
                 borderSide: BorderSide(color: Colors.transparent)
               ),
               focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(10),
                   borderSide: BorderSide(color: Colors.transparent)
               ),
               fillColor: AppColors.textFieldFillColor,
               filled: true,
               hintText: "Search users",
               hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey),
               prefixIcon: Icon(Icons.search_sharp, color: Colors.grey,)
             ),
            );
  }

  Widget _buildPlayerTypeItem({required String playerType}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),

        color: AppColors.textFieldFillColor,
      ),
      child: Text(playerType,
        style: TextStyle(fontSize: 12, color: AppColors.primaryColor),),
    );
  }

  Widget _buildInfoItemWidget({required String title, required int value}) {
    return Container(
      
              decoration: BoxDecoration(
                color: AppColors.textFieldFillColor,
                borderRadius: BorderRadius.circular(10)
              ),
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 15,
                children: [
                  Text(title, style: AppTextStyles.regularTextStyle,),
                  Text("$value", style: AppTextStyles.headingTextStyle)
                ],
              ),
            );
  }

}