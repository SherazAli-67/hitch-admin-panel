 import 'package:flutter/cupertino.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';

 class TableItemWidget extends StatelessWidget{
   final String text;
   final bool isCenterAlignment;
   final Color? textColor;
   final TextAlign textAlign;
   const TableItemWidget({super.key, this.isCenterAlignment = true, required this.text, this.textColor, this.textAlign = TextAlign.center});
   @override
   Widget build(BuildContext context) {
     return isCenterAlignment
         ? Center(child: Text(text, textAlign: textAlign, style: AppTextStyles.smallTextStyle.copyWith(color: textColor),),)
         : Text(text, textAlign: textAlign, style: AppTextStyles.smallTextStyle.copyWith(color: textColor),);
   }

 }