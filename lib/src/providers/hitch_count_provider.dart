import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HitchCountProvider extends ChangeNotifier{
  final String _totalHitchRequestsKey = 'totalHitchRequestsKey';
  final String _totalUsersKey = 'totalHitchUsers';
  final String _totalHitchChatsKey = 'totalHitchChats';
  final String _totalHitchAcceptedKey = 'totalHitchAccepted';

  int _totalUsers = 1;
  int _totalHitchRequests = 1;
  int _totalChats = 1;
  int _totalHitchAcceptedRequests = 1;

  HitchCountProvider(){
    _initHitchCount();
  }

  void _initHitchCount() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _totalUsers = prefs.getInt(_totalUsersKey) ?? 1;
    _totalHitchRequests = prefs.getInt(_totalHitchRequestsKey) ?? 1;
    _totalChats = prefs.getInt(_totalHitchChatsKey) ?? 1;
    _totalHitchAcceptedRequests = prefs.getInt(_totalHitchAcceptedKey) ?? 1;
    notifyListeners();

    _initFromNetwork();
  }

  void _initFromNetwork() {


  }
}