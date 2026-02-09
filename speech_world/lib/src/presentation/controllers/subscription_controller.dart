import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SubscriptionController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubscribed = false;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSubscribed => _isSubscribed;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void setSubscribed(bool subscribed) {
    _isSubscribed = subscribed;
    notifyListeners();
  }
}