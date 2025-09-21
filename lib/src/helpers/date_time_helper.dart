import 'package:intl/intl.dart';

class DateTimeHelper {
  static String formatDateTime(DateTime dateTime){
    return DateFormat.MMMEd().format(dateTime);
  }
}