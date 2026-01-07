import 'package:flutter/services.dart';

/// Formateur pour le NIF haïtien au format XXX-XXX-XXX-X
/// Exemple: 002-882-508-1
class NifInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Supprimer tous les caractères non numériques
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limiter à 10 chiffres maximum
    if (text.length > 10) {
      return oldValue;
    }
    
    // Construire le texte formaté
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Ajouter un tiret après les positions 3, 6 et 9
      if (i == 2 || i == 5 || i == 8) {
        if (i < text.length - 1) {
          buffer.write('-');
        }
      }
    }
    
    final formattedText = buffer.toString();
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Convertit le NIF formaté (XXX-XXX-XXX-X) en format backend (sans tirets)
String nifToBackendFormat(String nif) {
  return nif.replaceAll('-', '');
}

/// Convertit le NIF backend (sans tirets) en format affiché (XXX-XXX-XXX-X)
String nifToDisplayFormat(String nif) {
  final digits = nif.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 3) return digits;
  if (digits.length <= 6) return '${digits.substring(0, 3)}-${digits.substring(3)}';
  if (digits.length <= 9) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 9)}-${digits.substring(9)}';
}
