class AppValidators {
  AppValidators._();
  static String? required(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Invalid email';
    return null;
  }
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 10) return 'Invalid phone';
    return null;
  }
}
