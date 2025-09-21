import 'package:flutter/material.dart';

import '../res/app_colors.dart';
import '../res/app_textstyles.dart';

class TableColumnWidget extends StatelessWidget {
  const TableColumnWidget({
    super.key,
    required this.title
  });

  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.regularTextStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor
      ),
    );
  }
}