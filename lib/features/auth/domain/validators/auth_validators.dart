String? validateRequiredText(String? value, {required String fieldName}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName requis';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Mot de passe requis';
  }
  if (value.length < 8) {
    return 'Au moins 8 caractères';
  }
  if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
    return 'Ajoute au moins une minuscule';
  }
  if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
    return 'Ajoute au moins une majuscule';
  }
  if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
    return 'Ajoute au moins un chiffre';
  }
  if (!RegExp(r'(?=.*[^A-Za-z0-9])').hasMatch(value)) {
    return 'Ajoute au moins un caractère spécial';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.trim().isEmpty) {
    return 'Confirme ton mot de passe';
  }
  if (value != password) {
    return 'Les mots de passe ne correspondent pas.';
  }
  return null;
}
