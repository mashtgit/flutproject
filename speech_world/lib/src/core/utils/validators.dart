class Validators {
  static const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const passwordRegex = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$';
  
  static bool isValidEmail(String email) {
    return RegExp(emailRegex).hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return RegExp(passwordRegex).hasMatch(password);
  }
}