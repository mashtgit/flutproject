import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class HomeController extends ChangeNotifier {
  String _selectedLanguage = 'en';
  String _inputText = '';
  bool _isLoading = false;
  bool _isListening = false;
  String? _errorMessage;
  
  // Separate variables for source and target languages
  String _sourceLanguage = 'en';
  String _targetLanguage = 'ru';
  
  String get selectedLanguage => _selectedLanguage;
  String get inputText => _inputText;
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  String? get errorMessage => _errorMessage;
  
  // Getters for source and target languages
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  
  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }
  
  // New methods for setting source and target languages separately
  void setSourceLanguage(String language) {
    _sourceLanguage = language;
    notifyListeners();
  }
  
  void setTargetLanguage(String language) {
    _targetLanguage = language;
    notifyListeners();
  }
  
  void setInputText(String text) {
    _inputText = text;
    notifyListeners();
  }
  
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
  
  Future<void> translateText() async {
    if (_inputText.trim().isEmpty) {
      setError('Please enter text to translate');
      return;
    }
    
    setLoading(true);
    clearError();
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
    } catch (e) {
      setError('Translation failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }
  
  Future<void> startVoiceRecognition() async {
    _isListening = true;
    setLoading(true);
    clearError();
    notifyListeners();
    
    try {
      //Implement voice recognition logic
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate voice recognition result
      setInputText('Hello, this is a voice recognition test');
      
    } catch (e) {
      setError('Voice recognition failed. Please try again.');
    } finally {
      _isListening = false;
      setLoading(false);
      notifyListeners();
    }
  }
  
  void setListening(bool listening) {
    _isListening = listening;
    notifyListeners();
  }
}
