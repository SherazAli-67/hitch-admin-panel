import 'package:flutter/cupertino.dart';

class MainMenUTabChangeProvider extends ChangeNotifier{
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void onTabChange(int index){
    _currentIndex = index;
    notifyListeners();
  }
}