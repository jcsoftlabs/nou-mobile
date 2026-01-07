import 'package:flutter/services.dart';

/// Formateur pour les dates au format DD/MM/YYYY
/// Ajoute automatiquement les "/" pendant la saisie
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Supprimer tous les caractères non numériques
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limiter à 8 chiffres maximum (DDMMYYYY)
    if (text.length > 8) {
      return oldValue;
    }
    
    // Construire le texte formaté
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Ajouter un "/" après les positions 2 et 4
      if (i == 1 || i == 3) {
        if (i < text.length - 1) {
          buffer.write('/');
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
