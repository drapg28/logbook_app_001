import 'package:flutter/material.dart';

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
}

class CounterController extends ChangeNotifier {
  int _counter = 0;
  int _step = 1; 

  final List<LogEntry> _history = [];

  int get counter => _counter;
  int get step => _step;
  List<LogEntry> get history => List.unmodifiable(_history);

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
  }

  void decrement() {
    if (_step == 0) return;

    _counter -= _step;
    _addLog(ActionType.decrement, _step);
    notifyListeners();
  }

  void reset() {
    _counter = 0;
    _history.clear();
    notifyListeners();
  }

  void _addLog(ActionType type, int value) {
    _history.insert(0, LogEntry(type: type, value: value, timestamp: DateTime.now()));
    if (_history.length > 5) _history.removeLast(); //
  }
}
