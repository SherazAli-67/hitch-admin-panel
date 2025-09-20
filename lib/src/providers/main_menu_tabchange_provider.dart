import 'package:flutter/cupertino.dart';

class MainMenUTabChangeProvider extends ChangeNotifier{
  int _currentIndex = 0;
  bool _isMenuExpanded = false;
  int _hoveredIndex = -1;

  int get currentIndex => _currentIndex;
  bool get isMenuExpanded => _isMenuExpanded;
  int get hoveredIndex => _hoveredIndex;

  void onTabChange(int index){
    _currentIndex = index;
    notifyListeners();
  }

  void setMenuExpanded(bool expanded) {
    if (_isMenuExpanded != expanded) {
      _isMenuExpanded = expanded;
      notifyListeners();
    }
  }

  void setHoveredIndex(int index) {
    if (_hoveredIndex != index) {
      _hoveredIndex = index;
      notifyListeners();
    }
  }

  void clearHover() {
    if (_hoveredIndex != -1) {
      _hoveredIndex = -1;
      notifyListeners();
    }
  }
}
