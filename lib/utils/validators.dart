class Validators {
  /// Valide un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est obligatoire';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  /// Valide un numéro de téléphone (format haïtien ou international)
  static String? validatePhone(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Le numéro de téléphone est obligatoire' : null;
    }
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{8,20}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < 8) {
      return 'Minimum 8 caractères';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return '1 majuscule requise';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return '1 chiffre requis';
    }
    return null;
  }

  /// Valide une date au format DD/MM/YYYY ou YYYY-MM-DD
  static String? validateDate(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'La date est obligatoire' : null;
    }
    try {
      DateTime date;
      
      // Vérifier si c'est le format DD/MM/YYYY
      if (value.contains('/')) {
        final parts = value.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          date = DateTime(year, month, day);
        } else {
          return 'Format de date invalide (JJ/MM/AAAA)';
        }
      } else {
        // Format YYYY-MM-DD
        date = DateTime.parse(value);
      }
      
      if (date.isAfter(DateTime.now())) {
        return 'La date ne peut pas être dans le futur';
      }
    } catch (e) {
      return 'Format de date invalide (JJ/MM/AAAA)';
    }
    return null;
  }

  /// Valide un champ obligatoire
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est obligatoire';
    }
    return null;
  }

  /// Valide un nom d'utilisateur
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est obligatoire';
    }
    if (value.length < 3) {
      return 'Minimum 3 caractères';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Lettres, chiffres et _ uniquement';
    }
    return null;
  }

  /// Valide un NIN (Numéro d'Identification Nationale)
  static String? validateNIN(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Le NIN est obligatoire' : null;
    }
    if (value.length < 10) {
      return 'NIN invalide';
    }
    return null;
  }

  /// Valide un NIF (Numéro d'Identification Fiscale)
  static String? validateNIF(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Le NIF est obligatoire' : null;
    }
    if (value.length < 8) {
      return 'NIF invalide';
    }
    return null;
  }

  /// Valide un nombre entier
  static String? validateInteger(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Ce champ est obligatoire' : null;
    }
    if (int.tryParse(value) == null) {
      return 'Nombre invalide';
    }
    return null;
  }
}
