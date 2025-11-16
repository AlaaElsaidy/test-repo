String? emailValidator(String? value) {
  final emailRegExp = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[A-Za-z]{2,}$');
  if (value == null || value.isEmpty) return 'Please enter your email';
  if (!emailRegExp.hasMatch(value)) return 'Enter a valid email';
  return null;
}

String? nameValidator(String? value) {
  final nameRegExp = RegExp(r'^[\p{L} ]+$', unicode: true);

  if (value == null || value.trim().isEmpty) {
    return 'Please enter your name';
  }

  if (value.trim().length < 3) {
    return 'Name must be at least 3 characters';
  }

  if (!nameRegExp.hasMatch(value.trim())) {
    return 'Name can only contain letters';
  }

  return null;
}

String? passwordValidator(String? value) {
  final passwordRegExp = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );
  if (value == null || value.isEmpty) return 'Please enter your password';
  if (!passwordRegExp.hasMatch(value)) return 'Enter a valid password';
  return null;
}

String? confirmPasswordValidator(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your phone number';
  }

  final trimmed = value.trim();

  final pattern = RegExp(r'^(010|011|012|015)[0-9]{8}$');

  if (!pattern.hasMatch(trimmed)) {
    return 'Enter a valid Egyptian phone number';
  }

  return null;
}
