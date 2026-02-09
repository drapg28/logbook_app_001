class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];

  
  int get counter => _counter;
  int get step => _step;
  List<String> get history => _history;

  void setStep(int val) {
    _step = val;
  } 

  void increment() {
    _counter += _step;
    _addLog("Ditambah $_step");
  }

  void decrement() {
    _counter -= _step;
    _addLog("Dikurangi $_step");
  }

  void reset() {
    _counter = 0;
    _addLog("Reset hitungan");
  }

  void _addLog(String action) {
    String timestamp = "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";
    _history.insert(0, "$action ($timestamp)");

    if (_history.length > 5) {
      _history.removeLast(); 
    }
  }
}