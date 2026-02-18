import 'dart:async';
import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  final Map<String, String> _users = {
    "admin": "123",
    "samudra": "suiseikeren",
    "lancelot": "pedangkeadilan",
  };

  int _failedAttempts = 0;
  bool isLocked = false;

  bool login(String username, String password) {
    if (_users.containsKey(username) && _users[username] == password) {
      _failedAttempts = 0;
      return true;
    }
    
    _failedAttempts++;
    return false;
  }

  bool checkLockout() {
    if (_failedAttempts >= 3) {
      isLocked = true;
      Timer(const Duration(seconds: 10), () {
        isLocked = false;
        _failedAttempts = 0;
      });
      return true;
    }
    return false;
  }

  int get remainingAttempts => 3 - _failedAttempts;
}