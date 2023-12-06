class Validator {
  static bool email(String? value) {
    // return false if email is invalid, else return true
    if (value == null || value.isEmpty) {
      return false;
    }
    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
      return false;
    }

    return true;
  }

  static bool password(String? value) {
    // return false if password has less than 8 characters, no uppercase, no lowercase, no number
    if (value == null || value.isEmpty) return false;
    if (value.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(value)) return false;
    if (!RegExp(r'[a-z]').hasMatch(value)) return false;
    if (!RegExp(r'[0-9]').hasMatch(value)) return false;

    //else return true
    return true;
  }
}
