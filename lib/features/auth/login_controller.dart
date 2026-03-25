import 'dart:async';
import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  final Map<String, Map<String, String>> _users = {
    "admin": {
      "password": "123",
      "role": "Ketua",
      "teamId": "TEAM_001",
      "uid": "uid_admin",
    },
    "samudra": {
      "password": "suiseikeren",
      "role": "Anggota",
      "teamId": "TEAM_001",
      "uid": "uid_samudra",
    },
    "lancelot": {
      "password": "pedangkeadilan",
      "role": "Anggota",
      "teamId": "TEAM_002",
      "uid": "uid_lancelot",
    },
  };

  int _failedAttempts = 0;
  bool isLocked = false;

  Map<String, String>? login(String username, String password) {
    final userData = _users[username];
    if (userData != null && userData['password'] == password) {
      _failedAttempts = 0;
      return {
        'username': username,
        'role': userData['role']!,
        'teamId': userData['teamId']!,
        'uid': userData['uid']!,
      };
    }
    _failedAttempts++;
    return null;
  }

  bool checkLockout() {
    if (_failedAttempts >= 3) {
      isLocked = true;
      notifyListeners();
      Timer(const Duration(seconds: 10), () {
        isLocked = false;
        _failedAttempts = 0;
        notifyListeners();
      });
      return true;
    }
    return false;
  }

  int get remainingAttempts => 3 - _failedAttempts;
}