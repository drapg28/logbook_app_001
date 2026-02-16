import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


enum ActionType { increment, decrement }

class LogEntry {
  final ActionType type;
  final int value;
  final DateTime timestamp;

  LogEntry({
    required this.type,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
  'v': value, 
  't': timestamp.toIso8601String(), 
  'ty': type.index
  
};

factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
  value: json['v'],
  timestamp: DateTime.parse(json['t']),
  type: ActionType.values[json['ty']],
);
}

class CounterController extends ChangeNotifier {
  int _counter = 0;
  int _step = 1; 
 
  List<LogEntry> _history = [];

  int get counter => _counter;
  int get step => _step;
  List<LogEntry> get history => List.unmodifiable(_history);

  CounterController() {
    loadData(); 
    }

  @override
  void dispose() {
    _saveData();
    super.dispose();
  }


  void setStep(int value) {
    if (value < 0) return;
    _step = value;
    notifyListeners();
  }

  void increment() {
    if (_step == 0) return; 
    
    _counter += _step;
    _addLog(ActionType.increment, _step);
    notifyListeners();
    _saveData();
  }

  void decrement() {
    if (_step == 0) return;

    _counter -= _step;
    _addLog(ActionType.decrement, _step);
    notifyListeners();
    _saveData();
  }

  void reset() {
    _counter = 0;
    _history.clear();
    notifyListeners();
    _saveData();
  }

  void _addLog(ActionType type, int value) {
    _history.insert(0, LogEntry(type: type, value: value, timestamp: DateTime.now()));
    if (_history.length > 5) _history.removeLast(); 
  }

  Future<void> _saveData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('last_val', _counter);
  List<String> logs = _history.map((e) => jsonEncode(e.toJson())).toList();
  await prefs.setStringList('history', logs);
  }

Future<void> loadData() async {
  final prefs = await SharedPreferences.getInstance();
  _counter = prefs.getInt('last_val') ?? 0;
  List<String>? logs = prefs.getStringList('history');
  if (logs != null) {
    _history = logs.map((e) => LogEntry.fromJson(jsonDecode(e))).toList();
  }
  notifyListeners();
  }
}
