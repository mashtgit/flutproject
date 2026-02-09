import 'dart:async';

typedef VoidCallback = void Function();

class Debounce {
  Timer? _timer;
  
  void debounce(Duration duration, VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }
  
  void cancel() {
    _timer?.cancel();
  }
}